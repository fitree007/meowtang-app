import Flutter
import UIKit
import Photos
import PhotosUI
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var imagePickerDelegate: ImagePickerDelegate?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      setupNativeChannel(messenger: controller.binaryMessenger, controller: controller)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func setupNativeChannel(messenger: FlutterBinaryMessenger, controller: FlutterViewController) {
    let nativeChannel = FlutterMethodChannel(name: "com.afitree.rizqi/native", binaryMessenger: messenger)

    nativeChannel.setMethodCallHandler({ [weak self, weak controller] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard let self = self else { return }
      let targetController = controller ?? self.window?.rootViewController

      switch call.method {
      case "checkAppPermissions":
        let status = PHPhotoLibrary.authorizationStatus()
        let isGranted: Bool
        if #available(iOS 14, *) {
          isGranted = (status == .authorized || status == .limited)
        } else {
          isGranted = (status == .authorized)
        }
        result(["allGranted": isGranted, "storageGranted": isGranted])

      case "requestAppPermissions":
        if #available(iOS 14, *) {
          PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
              let isGranted = (status == .authorized || status == .limited)
              result(["allGranted": isGranted, "storageGranted": isGranted])
            }
          }
        } else {
          PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
              let isGranted = (status == .authorized)
              result(["allGranted": isGranted, "storageGranted": isGranted])
            }
          }
        }

      case "pickImage":
        guard let vc = targetController else {
          result(nil)
          return
        }
        self.pickImageFromGallery(controller: vc, result: result)

      case "scanBankSlips":
        let args = call.arguments as? [String: Any]
        let daysLimit = args?["daysLimit"] as? Int ?? 60
        self.scanBankSlipsFromAlbum(daysLimit: daysLimit, result: result)

      case "processSlipImage":
        let args = call.arguments as? [String: Any]
        guard let filePath = args?["filePath"] as? String else {
          result(["error": "Missing filePath", "qrPayload": "", "ocrText": ""])
          return
        }
        self.processSlipImage(filePath: filePath, result: result)

      case "shareFile":
        let args = call.arguments as? [String: Any]
        let filePath = args?["filePath"] as? String ?? ""
        if let vc = targetController {
          self.shareFile(filePath: filePath, controller: vc, result: result)
        } else {
          result(false)
        }

      case "startMediaObserver", "startBackgroundService", "stopMediaObserver":
        // Background continuous daemon is restricted by iOS Sandbox, return true gracefully
        result(true)

      case "isNotificationListenerGranted":
        result(false)

      default:
        result(FlutterMethodNotImplemented)
      }
    })
  }

  // MARK: - Pick Image from Photo Library
  private func pickImageFromGallery(controller: UIViewController, result: @escaping FlutterResult) {
    let picker = UIImagePickerController()
    picker.sourceType = .photoLibrary
    picker.allowsEditing = false

    let delegate = ImagePickerDelegate { [weak self] path in
      self?.imagePickerDelegate = nil
      result(path)
    }
    self.imagePickerDelegate = delegate
    picker.delegate = delegate
    controller.present(picker, animated: true, completion: nil)
  }

  // MARK: - Scan Bank Slips From iOS Photo Album
  private func scanBankSlipsFromAlbum(daysLimit: Int, result: @escaping FlutterResult) {
    let status = PHPhotoLibrary.authorizationStatus()
    let isAuthorized: Bool
    if #available(iOS 14, *) {
      isAuthorized = (status == .authorized || status == .limited)
    } else {
      isAuthorized = (status == .authorized)
    }

    guard isAuthorized else {
      result([])
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let fetchOptions = PHFetchOptions()
      let cutoffDate = Calendar.current.date(byAdding: .day, value: -daysLimit, to: Date()) ?? Date()
      fetchOptions.predicate = NSPredicate(format: "mediaType = %d AND creationDate >= %@", PHAssetMediaType.image.rawValue, cutoffDate as NSDate)
      fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

      let assets = PHAsset.fetchAssets(with: fetchOptions)
      var results: [[String: Any]] = []
      let imageManager = PHImageManager.default()
      let requestOptions = PHImageRequestOptions()
      requestOptions.isSynchronous = true
      requestOptions.deliveryMode = .highQualityFormat
      requestOptions.isNetworkAccessAllowed = true

      let cacheDir = FileManager.default.temporaryDirectory.appendingPathComponent("ios_slip_cache")
      try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

      let total = min(assets.count, 200)
      let dateFormatter = ISO8601DateFormatter()

      for i in 0..<total {
        let asset = assets.object(at: i)
        let assetDate = asset.creationDate ?? Date()
        let filename = PHAssetResource.assetResources(for: asset).first?.originalFilename ?? "ios_slip_\(i).jpg"

        imageManager.requestImageDataAndOrientation(for: asset, options: requestOptions) { data, _, _, _ in
          guard let data = data else { return }
          let safeId = asset.localIdentifier.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "\\", with: "_")
          let targetUrl = cacheDir.appendingPathComponent("\(safeId).jpg")
          try? data.write(to: targetUrl)

          results.append([
            "path": targetUrl.path,
            "name": filename,
            "date": dateFormatter.string(from: assetDate),
            "bankName": "ธนาคารไทย"
          ])
        }
      }

      DispatchQueue.main.async {
        result(results)
      }
    }
  }

  // MARK: - Process Slip Image (Apple Vision Framework OCR & QR)
  private func processSlipImage(filePath: String, result: @escaping FlutterResult) {
    guard let image = UIImage(contentsOfFile: filePath), let cgImage = image.cgImage else {
      result(["error": "Cannot load image", "qrPayload": "", "ocrText": ""])
      return
    }

    var qrPayload = ""
    var ocrText = ""

    let group = DispatchGroup()

    // 1. QR Code Barcode detection
    group.enter()
    let barcodeRequest = VNDetectBarcodesRequest { request, error in
      defer { group.leave() }
      if let observations = request.results as? [VNBarcodeObservation] {
        for obs in observations {
          if let payload = obs.payloadStringValue, !payload.isEmpty {
            qrPayload = payload
            break
          }
        }
      }
    }
    barcodeRequest.symbologies = [.qr]

    // 2. Offline Text Recognition (OCR)
    group.enter()
    let textRequest = VNRecognizeTextRequest { request, error in
      defer { group.leave() }
      if let observations = request.results as? [VNRecognizedTextObservation] {
        var lines: [String] = []
        for obs in observations {
          if let topCandidate = obs.topCandidates(1).first {
            lines.append(topCandidate.string)
          }
        }
        ocrText = lines.joined(separator: "\n")
      }
    }
    textRequest.recognitionLevel = .accurate
    textRequest.usesLanguageCorrection = false
    if #available(iOS 16.0, *) {
      textRequest.recognitionLanguages = ["th-TH", "en-US"]
    } else {
      textRequest.recognitionLanguages = ["en-US"]
    }

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    DispatchQueue.global(qos: .userInitiated).async {
      try? handler.perform([barcodeRequest, textRequest])
      group.notify(queue: .main) {
        result([
          "qrPayload": qrPayload,
          "ocrText": ocrText
        ])
      }
    }
  }

  // MARK: - Share File
  private func shareFile(filePath: String, controller: UIViewController, result: @escaping FlutterResult) {
    let fileUrl = URL(fileURLWithPath: filePath)
    let activityVC = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
    if let popover = activityVC.popoverPresentationController {
      popover.sourceView = controller.view
      popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }
    controller.present(activityVC, animated: true) {
      result(true)
    }
  }
}

// MARK: - ImagePickerDelegate
class ImagePickerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  private let completion: (String?) -> Void

  init(completion: @escaping (String?) -> Void) {
    self.completion = completion
  }

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true, completion: nil)
    if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.9) {
      let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("picked_slip_\(UUID().uuidString).jpg")
      try? data.write(to: tempFile)
      completion(tempFile.path)
    } else {
      completion(nil)
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
    completion(nil)
  }
}
