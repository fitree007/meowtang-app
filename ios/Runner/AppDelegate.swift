import Flutter
import UIKit
import Photos
import PhotosUI
import Vision
import AVFoundation
import Speech

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NativeBridgePlugin") {
      NativeBridgePlugin.register(with: registrar)
    }
  }
}

public class NativeBridgePlugin: NSObject, FlutterPlugin, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  private static var instance: NativeBridgePlugin?
  private static var isRegistered = false
  private var imagePickerResult: FlutterResult?
  private var speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "th-TH"))
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private let audioEngine = AVAudioEngine()
  private var pendingVoiceResult: FlutterResult?
  private var silenceTimer: Timer?
  private var latestVoiceText: String = ""

  public static func register(with registrar: FlutterPluginRegistrar) {
    guard !isRegistered else { return }
    isRegistered = true
    let channel = FlutterMethodChannel(name: "com.afitree.rizqi/native", binaryMessenger: registrar.messenger())
    let plugin = NativeBridgePlugin()
    instance = plugin
    registrar.addMethodCallDelegate(plugin, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "checkAppPermissions":
      checkPermissions(result: result)

    case "requestAppPermissions":
      requestPermissions(result: result)

    case "pickImage":
      self.pickImage(result: result)

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
      self.shareFile(filePath: filePath, result: result)

    case "startVoiceRecognition":
      self.startVoiceRecognition(result: result)

    case "stopVoiceRecognition":
      self.stopVoiceRecognition(result: result)

    case "startMediaObserver", "startBackgroundService", "stopMediaObserver":
      result(true)

    case "isNotificationListenerGranted":
      result(false)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Permissions (Photos, Camera, Microphone)
  private func checkPermissions(result: @escaping FlutterResult) {
    let photoStatus = PHPhotoLibrary.authorizationStatus()
    let photoGranted: Bool
    if #available(iOS 14, *) {
      photoGranted = (photoStatus == .authorized || photoStatus == .limited)
    } else {
      photoGranted = (photoStatus == .authorized)
    }

    let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    let cameraGranted = (cameraStatus == .authorized)

    let micStatus = AVAudioSession.sharedInstance().recordPermission
    let micGranted = (micStatus == .granted)

    let isAllGranted = photoGranted && cameraGranted
    result([
      "allGranted": isAllGranted,
      "storageGranted": photoGranted,
      "cameraGranted": cameraGranted,
      "audioGranted": micGranted
    ])
  }

  private func requestPermissions(result: @escaping FlutterResult) {
    let group = DispatchGroup()
    var photoGranted = false
    var cameraGranted = false
    var micGranted = false

    // 1. Photo Library
    group.enter()
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
        photoGranted = (status == .authorized || status == .limited)
        group.leave()
      }
    } else {
      PHPhotoLibrary.requestAuthorization { status in
        photoGranted = (status == .authorized)
        group.leave()
      }
    }

    // 2. Camera
    group.enter()
    AVCaptureDevice.requestAccess(for: .video) { granted in
      cameraGranted = granted
      group.leave()
    }

    // 3. Microphone
    group.enter()
    AVAudioSession.sharedInstance().requestRecordPermission { granted in
      micGranted = granted
      group.leave()
    }

    group.notify(queue: .main) {
      let isAllGranted = photoGranted && cameraGranted
      result([
        "allGranted": isAllGranted,
        "storageGranted": photoGranted,
        "cameraGranted": cameraGranted,
        "audioGranted": micGranted
      ])
    }
  }

  // MARK: - Pick Image from Photo Library
  private func pickImage(result: @escaping FlutterResult) {
    guard let topVC = getTopViewController() else {
      result(nil)
      return
    }

    self.imagePickerResult = result

    if #available(iOS 14, *) {
      var config = PHPickerConfiguration()
      config.filter = .images
      config.selectionLimit = 1
      let picker = PHPickerViewController(configuration: config)
      picker.delegate = self
      topVC.present(picker, animated: true, completion: nil)
    } else {
      let picker = UIImagePickerController()
      picker.sourceType = .photoLibrary
      picker.allowsEditing = false
      picker.delegate = self
      topVC.present(picker, animated: true, completion: nil)
    }
  }

  // MARK: - UIImagePickerControllerDelegate (Fallback for iOS < 14)
  public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true, completion: nil)
    guard let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.92) else {
      self.imagePickerResult?(nil)
      self.imagePickerResult = nil
      return
    }

    let cacheDir = FileManager.default.temporaryDirectory.appendingPathComponent("ios_picked_slips")
    try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    let fileUrl = cacheDir.appendingPathComponent("picked_slip_\(UUID().uuidString).jpg")
    try? data.write(to: fileUrl)

    self.imagePickerResult?(fileUrl.path)
    self.imagePickerResult = nil
  }

  public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
    self.imagePickerResult?(nil)
    self.imagePickerResult = nil
  }

  // MARK: - Scan Bank Slips From iOS Photo Album
  private func scanBankSlipsFromAlbum(daysLimit: Int, result: @escaping FlutterResult) {
    let performScan = { [weak self] in
      guard let self = self else { return }
      DispatchQueue.global(qos: .userInitiated).async {
        let fetchOptions = PHFetchOptions()
        if daysLimit > 0 {
          let cutoffDate = Calendar.current.date(byAdding: .day, value: -daysLimit, to: Date()) ?? Date()
          fetchOptions.predicate = NSPredicate(format: "mediaType = %d AND creationDate >= %@", PHAssetMediaType.image.rawValue, cutoffDate as NSDate)
        } else {
          // Unlimited historical scan for Creator Edition
          fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        }
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

        let total = assets.count
        let dateFormatter = ISO8601DateFormatter()

        for i in 0..<total {
          let asset = assets.object(at: i)
          let assetDate = asset.creationDate ?? Date()
          let filename = PHAssetResource.assetResources(for: asset).first?.originalFilename ?? "ios_slip_\(i).jpg"

          if #available(iOS 13.0, *) {
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
          } else {
            imageManager.requestImageData(for: asset, options: requestOptions) { data, _, _, _ in
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
        }

        DispatchQueue.main.async {
          result(results)
        }
      }
    }

    let status = PHPhotoLibrary.authorizationStatus()
    if status == .notDetermined {
      if #available(iOS 14, *) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
          if newStatus == .authorized || newStatus == .limited {
            performScan()
          } else {
            DispatchQueue.main.async { result([]) }
          }
        }
      } else {
        PHPhotoLibrary.requestAuthorization { newStatus in
          if newStatus == .authorized {
            performScan()
          } else {
            DispatchQueue.main.async { result([]) }
          }
        }
      }
    } else if status == .authorized || (status.rawValue == 4 /* limited */) {
      performScan()
    } else {
      result([])
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
    let barcodeRequest = VNDetectBarcodesRequest { request, _ in
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
    if #available(iOS 13.0, *) {
      group.enter()
      let textRequest = VNRecognizeTextRequest { request, _ in
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
    } else {
      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      DispatchQueue.global(qos: .userInitiated).async {
        try? handler.perform([barcodeRequest])
        group.notify(queue: .main) {
          result([
            "qrPayload": qrPayload,
            "ocrText": ""
          ])
        }
      }
    }
  }

  // MARK: - Share File
  private func shareFile(filePath: String, result: @escaping FlutterResult) {
    guard let topVC = getTopViewController() else {
      result(false)
      return
    }
    let fileUrl = URL(fileURLWithPath: filePath)
    let activityVC = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
    if let popover = activityVC.popoverPresentationController {
      popover.sourceView = topVC.view
      popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }
    topVC.present(activityVC, animated: true) {
      result(true)
    }
  }

  // MARK: - Top View Controller Resolver
  private func getTopViewController() -> UIViewController? {
    if #available(iOS 13.0, *) {
      let scenes = UIApplication.shared.connectedScenes.compactMap { scene in scene as? UIWindowScene }
      for scene in scenes {
        if let window = scene.windows.first(where: { win in win.isKeyWindow }) ?? scene.windows.first {
          if let root = window.rootViewController {
            return findTop(root)
          }
        }
      }
    }
    if let window = UIApplication.shared.windows.first(where: { win in win.isKeyWindow }) ?? UIApplication.shared.windows.first {
      if let root = window.rootViewController {
        return findTop(root)
      }
    }
    return nil
  }

  private func findTop(_ vc: UIViewController) -> UIViewController {
    if let presented = vc.presentedViewController {
      return findTop(presented)
    }
    if let nav = vc as? UINavigationController, let visible = nav.visibleViewController {
      return findTop(visible)
    }
    if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
      return findTop(selected)
    }
    return vc
  }

  // MARK: - Speech Recognition (Thai Language)
  private func startVoiceRecognition(result: @escaping FlutterResult) {
    if self.pendingVoiceResult != nil {
      finishVoiceRecognition(text: self.latestVoiceText)
    }

    self.pendingVoiceResult = result
    self.latestVoiceText = ""

    SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
      guard let self = self else { return }
      DispatchQueue.main.async {
        guard authStatus == .authorized else {
          self.finishVoiceRecognition(text: "")
          return
        }

        AVAudioSession.sharedInstance().requestRecordPermission { granted in
          DispatchQueue.main.async {
            guard granted else {
              self.finishVoiceRecognition(text: "")
              return
            }
            self.beginSpeechListening()
          }
        }
      }
    }
  }

  private func beginSpeechListening() {
    stopCurrentAudioEngine()

    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      finishVoiceRecognition(text: "")
      return
    }

    if speechRecognizer == nil {
      speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "th-TH")) ?? SFSpeechRecognizer()
    }

    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    guard let recognitionRequest = recognitionRequest else {
      finishVoiceRecognition(text: "")
      return
    }
    recognitionRequest.shouldReportPartialResults = true

    let inputNode = audioEngine.inputNode
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.removeTap(onBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
      self.recognitionRequest?.append(buffer)
    }

    audioEngine.prepare()
    do {
      try audioEngine.start()
    } catch {
      finishVoiceRecognition(text: "")
      return
    }

    recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] speechResult, error in
      guard let self = self else { return }
      if let speechResult = speechResult {
        let text = speechResult.bestTranscription.formattedString
        self.latestVoiceText = text
        self.resetSilenceTimer()
        if speechResult.isFinal {
          self.finishVoiceRecognition(text: text)
        }
      }
      if error != nil {
        self.finishVoiceRecognition(text: self.latestVoiceText)
      }
    }

    resetSilenceTimer(timeout: 5.0)
  }

  private func resetSilenceTimer(timeout: TimeInterval = 2.0) {
    silenceTimer?.invalidate()
    silenceTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
      guard let self = self else { return }
      if !self.latestVoiceText.isEmpty {
        self.finishVoiceRecognition(text: self.latestVoiceText)
      }
    }
  }

  private func stopVoiceRecognition(result: @escaping FlutterResult) {
    finishVoiceRecognition(text: latestVoiceText)
    result(true)
  }

  private func finishVoiceRecognition(text: String) {
    silenceTimer?.invalidate()
    silenceTimer = nil
    stopCurrentAudioEngine()

    if let res = pendingVoiceResult {
      pendingVoiceResult = nil
      DispatchQueue.main.async {
        res(text.trimmingCharacters(in: .whitespacesAndNewlines))
      }
    }
  }

  private func stopCurrentAudioEngine() {
    if audioEngine.isRunning {
      audioEngine.stop()
      audioEngine.inputNode.removeTap(onBus: 0)
    }
    recognitionRequest?.endAudio()
    recognitionRequest = nil
    recognitionTask?.cancel()
    recognitionTask = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}

// MARK: - PHPickerViewControllerDelegate (iOS 14+)
@available(iOS 14, *)
extension NativeBridgePlugin: PHPickerViewControllerDelegate {
  public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true, completion: nil)
    guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
      self.imagePickerResult?(nil)
      self.imagePickerResult = nil
      return
    }

    provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
      guard let self = self, let uiImage = image as? UIImage, let data = uiImage.jpegData(compressionQuality: 0.92) else {
        DispatchQueue.main.async {
          self?.imagePickerResult?(nil)
          self?.imagePickerResult = nil
        }
        return
      }

      let cacheDir = FileManager.default.temporaryDirectory.appendingPathComponent("ios_picked_slips")
      try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
      let fileUrl = cacheDir.appendingPathComponent("picked_slip_\(UUID().uuidString).jpg")
      try? data.write(to: fileUrl)

      DispatchQueue.main.async {
        self.imagePickerResult?(fileUrl.path)
        self.imagePickerResult = nil
      }
    }
  }
}
