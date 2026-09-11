package com.afitree.rizqi

import android.Manifest
import android.app.Activity
import android.app.AlertDialog
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.graphics.BitmapFactory
import androidx.core.app.NotificationCompat
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import org.json.JSONArray
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.afitree.rizqi/native"
    private val PICK_IMAGE_REQUEST = 1001
    private val SPEECH_REQUEST = 1002
    private val PICK_FILE_REQUEST = 1003
    private val PERMISSION_REQUEST_CODE = 2001

    private var methodChannel: MethodChannel? = null
    private var pendingImageResult: MethodChannel.Result? = null
    private var pendingSpeechResult: MethodChannel.Result? = null
    private var pendingFileResult: MethodChannel.Result? = null
    private var inAppSpeechRecognizer: SpeechRecognizer? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    private var mediaObserver: ContentObserver? = null
    private var lastNotifiedSlipId: String? = null
    private var hasPromptedPermissionOnStart = false

    private var initialSlipPath: String? = null
    private var isReloadReceiverRegistered = false

    private val reloadReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            methodChannel?.invokeMethod("onVoiceTransactionAdded", null)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
        try {
            val filter = android.content.IntentFilter("com.afitree.rizqi.RELOAD_TRANSACTIONS")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(reloadReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(reloadReceiver, filter)
            }
            isReloadReceiverRegistered = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val slipPath = intent?.getStringExtra("slip_path")
        val autoOpen = intent?.getBooleanExtra("auto_open_slip", false) ?: false
        if (!slipPath.isNullOrEmpty() && autoOpen) {
            initialSlipPath = slipPath
            val payload = mapOf(
                "path" to slipPath,
                "name" to (File(slipPath).name),
                "bankName" to "ธนาคารไทย",
                "dateAdded" to System.currentTimeMillis()
            )
            methodChannel?.invokeMethod("onOpenSlipFromNotification", payload)
        }
    }

    override fun onPostResume() {
        super.onPostResume()
        methodChannel?.invokeMethod("onAppResumed", null)
        // Automatically check and prompt runtime permission popup immediately upon opening app
        if (!hasPromptedPermissionOnStart && !hasStoragePermission()) {
            hasPromptedPermissionOnStart = true
            requestPermissionsFromSystem()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Android Widget MethodChannel for Daily Quota & Balance
        val widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.afitree.rizqi/widget")
        widgetChannel.setMethodCallHandler { call, result ->
            if (call.method == "updateWidgets") {
                val todayIncome = call.argument<Double>("todayIncome") ?: 0.0
                val todayExpense = call.argument<Double>("todayExpense") ?: 0.0
                val todayNet = call.argument<Double>("todayNet") ?: (todayIncome - todayExpense)
                val dailyQuota = call.argument<Double>("dailyQuota") ?: 250.0
                val monthlyExpense = call.argument<Double>("monthlyExpense") ?: 0.0
                RizqiQuotaWidgetProvider.updateAllWidgets(
                    this@MainActivity,
                    todayIncome,
                    todayExpense,
                    todayNet,
                    dailyQuota,
                    monthlyExpense
                )
                result.success(true)
            } else {
                result.notImplemented()
            }
        }

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSlipPath" -> {
                    val path = initialSlipPath
                    initialSlipPath = null
                    result.success(path)
                }
                "processSlipImage" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath.isNullOrEmpty()) {
                        result.error("INVALID_PATH", "File path is empty", null)
                    } else {
                        processSlipImageWithMlKit(filePath, result)
                    }
                }
                "requestAppPermissions" -> {
                    pendingPermissionResult = result
                    requestPermissionsFromSystem()
                }
                "checkAppPermissions" -> {
                    result.success(checkPermissionsStatus())
                }
                "startMediaObserver" -> {
                    registerMediaContentObserver()
                    startBackgroundSlipService()
                    result.success(true)
                }
                "stopMediaObserver" -> {
                    unregisterMediaContentObserver()
                    stopBackgroundSlipService()
                    result.success(true)
                }
                "startBackgroundService" -> {
                    startBackgroundSlipService()
                    result.success(true)
                }
                "shareBackupFile" -> {
                    val filePath = call.argument<String>("filePath")
                    val title = call.argument<String>("title") ?: "สำรองข้อมูลบันทึกริซกี"
                    if (filePath != null) {
                        shareBackupFileViaIntent(filePath, title)
                        result.success(true)
                    } else {
                        result.error("INVALID_PATH", "File path cannot be null", null)
                    }
                }
                "pickBackupFile" -> {
                    pendingFileResult = result
                    val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                        type = "*/*"
                        addCategory(Intent.CATEGORY_OPENABLE)
                    }
                    try {
                        startActivityForResult(Intent.createChooser(intent, "เลือกไฟล์สำรองข้อมูลบันทึกริซกี (.rizqi หรือ .json)"), PICK_FILE_REQUEST)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                "saveBackupToDownloads" -> {
                    val fileName = call.argument<String>("fileName") ?: "Rizqi_Backup.rizqi"
                    val contentStr = call.argument<String>("content") ?: ""
                    val path = saveBackupFileToDownloads(fileName, contentStr)
                    result.success(path)
                }
                "saveExportFile" -> {
                    val fileName = call.argument<String>("fileName") ?: "meowtang_export.pdf"
                    val bytes = call.argument<ByteArray>("bytes")
                    val contentStr = call.argument<String>("content")
                    val subDirName = call.argument<String>("subDir") ?: "MeowTang"

                    val path = saveExportFileToStorage(fileName, bytes, contentStr, subDirName)
                    result.success(path)
                }
                "shareFile" -> {
                    val filePath = call.argument<String>("filePath")
                    val title = call.argument<String>("title") ?: "แชร์ไฟล์จากเหมียวตังค์"
                    if (!filePath.isNullOrEmpty()) {
                        val success = shareFileViaIntent(filePath, title)
                        result.success(success)
                    } else {
                        result.error("INVALID_PATH", "File path cannot be null", null)
                    }
                }
                "openFile" -> {
                    val filePath = call.argument<String>("filePath")
                    if (!filePath.isNullOrEmpty()) {
                        val success = openFileViaIntent(filePath)
                        result.success(success)
                    } else {
                        result.error("INVALID_PATH", "File path cannot be null", null)
                    }
                }
                "shareCsvFile" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        shareFileViaIntent(filePath, "ส่งออกรายงานเหมียวตังค์")
                        result.success(true)
                    } else {
                        result.error("INVALID_PATH", "File path cannot be null", null)
                    }
                }
                "pickImage" -> {
                    pendingImageResult = result
                    val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
                    intent.type = "image/*"
                    try {
                        startActivityForResult(intent, PICK_IMAGE_REQUEST)
                    } catch (e: Exception) {
                        val fallbackIntent = Intent(Intent.ACTION_GET_CONTENT)
                        fallbackIntent.type = "image/*"
                        startActivityForResult(fallbackIntent, PICK_IMAGE_REQUEST)
                    }
                }
                "scanBankSlips" -> {
                    val daysLimit = call.argument<Int>("daysLimit") ?: 30
                    val slips = queryDeviceBankSlips(daysLimit)
                    result.success(slips)
                }
                "getInstalledBankingApps" -> {
                    val apps = checkInstalledBankingApps()
                    result.success(apps)
                }
                "startVoiceRecognition" -> {
                    startInAppVoiceRecognition(result)
                }
                "stopVoiceRecognition" -> {
                    stopInAppVoiceRecognition()
                    result.success(true)
                }
                "isNotificationListenerGranted" -> {
                    val enabledListeners = android.provider.Settings.Secure.getString(
                        contentResolver,
                        "enabled_notification_listeners"
                    )
                    val isGranted = enabledListeners?.contains(packageName) == true
                    result.success(isGranted)
                }
                "openNotificationListenerSettings" -> {
                    try {
                        val intent = Intent(android.provider.Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.success(false)
                    }
                }
                "compressAndSaveSlip" -> {
                    val filePath = call.argument<String>("filePath")
                    val customName = call.argument<String>("fileName")
                    if (filePath.isNullOrEmpty()) {
                        result.error("INVALID_PATH", "File path is empty", null)
                    } else {
                        val savedPath = compressAndSaveSlipInternal(filePath, customName)
                        result.success(savedPath)
                    }
                }
                "showScanProgressNotification" -> {
                    val title = call.argument<String>("title") ?: "เหมียวตังค์: กำลังดึงสลิป..."
                    val message = call.argument<String>("message") ?: "ระบบกำลังประมวลผลสลิปในเครื่อง"
                    showScanProgressNotification(title, message)
                    result.success(true)
                }
                "showScanCompletedNotification" -> {
                    val title = call.argument<String>("title") ?: "เหมียวตังค์: ดึงสลิปสำเร็จแล้ว!"
                    val message = call.argument<String>("message") ?: "ประมวลผลสลิปเรียบร้อยแล้ว"
                    showScanCompletedNotification(title, message)
                    result.success(true)
                }
                "cancelScanProgressNotification" -> {
                    cancelScanProgressNotification()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        if (hasStoragePermission()) {
            registerMediaContentObserver()
            startBackgroundSlipService()
        }
    }

    /**
     * Executes real Google ML Kit Barcode/QR Scanning & Thai OCR Text Recognition on the image file
     */
    private fun processSlipImageWithMlKit(filePath: String, result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val file = File(filePath)
                if (!file.exists() && !filePath.startsWith("content://")) {
                    withContext(Dispatchers.Main) {
                        result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                    }
                    return@launch
                }

                val inputImage: InputImage = if (filePath.startsWith("content://")) {
                    InputImage.fromFilePath(this@MainActivity, Uri.parse(filePath))
                } else {
                    InputImage.fromFilePath(this@MainActivity, Uri.fromFile(file))
                }

                // 1. STEP 1: Barcode / QR Code Scanning
                var qrPayload: String? = null
                try {
                    val barcodeScanner = BarcodeScanning.getClient()
                    val barcodes = barcodeScanner.process(inputImage).await()
                    for (barcode in barcodes) {
                        if (barcode.format == Barcode.FORMAT_QR_CODE || barcode.valueType == Barcode.TYPE_TEXT || barcode.valueType == Barcode.TYPE_URL) {
                            val raw = barcode.rawValue
                            if (!raw.isNullOrEmpty()) {
                                qrPayload = raw
                                break
                            }
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }

                // 2. STEP 2: OCR Text Recognition
                var ocrText = ""
                try {
                    val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                    val visionText = recognizer.process(inputImage).await()
                    ocrText = visionText.text ?: ""
                } catch (e: Exception) {
                    e.printStackTrace()
                }

                val resMap = mapOf(
                    "qrPayload" to (qrPayload ?: ""),
                    "ocrText" to ocrText,
                    "hasQr" to (!qrPayload.isNullOrEmpty()),
                    "hasText" to ocrText.isNotEmpty()
                )

                withContext(Dispatchers.Main) {
                    result.success(resMap)
                }
            } catch (e: Exception) {
                e.printStackTrace()
                withContext(Dispatchers.Main) {
                    result.success(mapOf(
                        "qrPayload" to "",
                        "ocrText" to "",
                        "hasQr" to false,
                        "hasText" to false,
                        "error" to (e.message ?: "Unknown error")
                    ))
                }
            }
        }
    }

    private fun startBackgroundSlipService() {
        // Event-driven ContentObserver in registerMediaContentObserver() handles slip detection cleanly
        // No sticky persistent ongoing notification in the notification bar
    }

    private fun stopBackgroundSlipService() {
        // No-op
    }

    private fun shareBackupFileViaIntent(filePath: String, title: String) {
        val file = File(filePath)
        if (!file.exists()) return

        val fileUri: Uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file
        )

        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "*/*"
            putExtra(Intent.EXTRA_STREAM, fileUri)
            putExtra(Intent.EXTRA_SUBJECT, title)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        startActivity(Intent.createChooser(shareIntent, title))
    }

    private fun saveBackupFileToDownloads(fileName: String, content: String): String? {
        return try {
            val downloadsDir = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }
            val targetFile = File(downloadsDir, fileName)
            targetFile.writeText(content)
            targetFile.absolutePath
        } catch (e: Exception) {
            try {
                val appDocsDir = getExternalFilesDir(android.os.Environment.DIRECTORY_DOWNLOADS) ?: filesDir
                val targetFile = File(appDocsDir, fileName)
                targetFile.writeText(content)
                targetFile.absolutePath
            } catch (e2: Exception) {
                null
            }
        }
    }

    private fun saveExportFileToStorage(
        fileName: String,
        bytes: ByteArray?,
        contentStr: String?,
        subDirName: String
    ): String? {
        try {
            // 1. Try public Downloads/MeowTang folder
            val downloadsDir = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS)
            val targetDir = File(downloadsDir, subDirName)
            if (!targetDir.exists()) {
                targetDir.mkdirs()
            }
            val targetFile = File(targetDir, fileName)
            if (bytes != null) {
                targetFile.writeBytes(bytes)
            } else if (contentStr != null) {
                targetFile.writeText(contentStr, Charsets.UTF_8)
            }
            if (targetFile.exists() && targetFile.length() > 0) {
                android.media.MediaScannerConnection.scanFile(
                    this,
                    arrayOf(targetFile.absolutePath),
                    null,
                    null
                )
                return targetFile.absolutePath
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 2. Fallback to external files dir or internal files dir
        try {
            val appDocsDir = getExternalFilesDir(android.os.Environment.DIRECTORY_DOWNLOADS) ?: filesDir
            val targetFile = File(appDocsDir, fileName)
            if (bytes != null) {
                targetFile.writeBytes(bytes)
            } else if (contentStr != null) {
                targetFile.writeText(contentStr, Charsets.UTF_8)
            }
            return targetFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    private fun openFileViaIntent(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) return false
            val fileUri: Uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                file
            )
            val mimeType = when {
                filePath.endsWith(".pdf", ignoreCase = true) -> "application/pdf"
                filePath.endsWith(".csv", ignoreCase = true) -> "text/csv"
                filePath.endsWith(".xlsx", ignoreCase = true) -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                filePath.endsWith(".txt", ignoreCase = true) -> "text/plain"
                filePath.endsWith(".json", ignoreCase = true) -> "application/json"
                else -> "*/*"
            }
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(fileUri, mimeType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun shareFileViaIntent(filePath: String, title: String = "แชร์ไฟล์จากเหมียวตังค์"): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) return false
            val fileUri: Uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                file
            )
            val mimeType = when {
                filePath.endsWith(".pdf", ignoreCase = true) -> "application/pdf"
                filePath.endsWith(".csv", ignoreCase = true) -> "text/csv"
                filePath.endsWith(".xlsx", ignoreCase = true) -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                filePath.endsWith(".txt", ignoreCase = true) -> "text/plain"
                else -> "*/*"
            }
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, fileUri)
                putExtra(Intent.EXTRA_SUBJECT, title)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val chooser = Intent.createChooser(shareIntent, title)
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(chooser)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun registerMediaContentObserver() {
        if (mediaObserver != null) return
        val handler = Handler(Looper.getMainLooper())
        mediaObserver = object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                checkLatestSlipAndNotify()
            }
        }

        try {
            contentResolver.registerContentObserver(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                true,
                mediaObserver!!
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun unregisterMediaContentObserver() {
        mediaObserver?.let {
            try {
                contentResolver.unregisterContentObserver(it)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        mediaObserver = null
    }

    private fun checkLatestSlipAndNotify() {
        if (!hasStoragePermission()) return

        val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            arrayOf(
                MediaStore.Images.Media._ID,
                MediaStore.Images.Media.DISPLAY_NAME,
                MediaStore.Images.Media.DATE_ADDED,
                MediaStore.Images.Media.SIZE,
                MediaStore.Images.Media.DATA,
                MediaStore.Images.Media.RELATIVE_PATH,
                MediaStore.Images.Media.BUCKET_DISPLAY_NAME
            )
        } else {
            arrayOf(
                MediaStore.Images.Media._ID,
                MediaStore.Images.Media.DISPLAY_NAME,
                MediaStore.Images.Media.DATE_ADDED,
                MediaStore.Images.Media.SIZE,
                MediaStore.Images.Media.DATA
            )
        }

        val sortOrder = "${MediaStore.Images.Media.DATE_ADDED} DESC"

        try {
            val cursor: Cursor? = contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection,
                null,
                null,
                sortOrder
            )

            cursor?.use {
                if (it.moveToFirst()) {
                    val idColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
                    val nameColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)
                    val dateColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_ADDED)
                    val sizeColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media.SIZE)
                    val dataColumn = it.getColumnIndex(MediaStore.Images.Media.DATA)
                    val relPathColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) it.getColumnIndex(MediaStore.Images.Media.RELATIVE_PATH) else -1
                    val bucketColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) it.getColumnIndex(MediaStore.Images.Media.BUCKET_DISPLAY_NAME) else -1

                    val id = it.getLong(idColumn).toString()
                    val name = it.getString(nameColumn) ?: ""
                    val dateAdded = it.getLong(dateColumn) * 1000
                    val size = it.getLong(sizeColumn)
                    val path = if (dataColumn != -1) it.getString(dataColumn) else ""
                    val relPath = if (relPathColumn != -1) it.getString(relPathColumn) ?: "" else ""
                    val bucketName = if (bucketColumn != -1) it.getString(bucketColumn) ?: "" else ""

                    if (id == lastNotifiedSlipId) return

                    val lowerName = name.lowercase()
                    val lowerPath = path?.lowercase() ?: ""
                    val lowerRelPath = relPath.lowercase()
                    val lowerBucket = bucketName.lowercase()
                    val combinedSearch = "$lowerName $lowerPath $lowerRelPath $lowerBucket"

                    // Negative Filter 1: Ignore My QR / Receive Money QR codes
                    val isMyQr = combinedSearch.contains("myqr") || combinedSearch.contains("my_qr") || combinedSearch.contains("my-qr") ||
                                 combinedSearch.contains("qr_receive") || combinedSearch.contains("receive_qr") || combinedSearch.contains("promptpay_qr")
                    if (isMyQr) return

                    // Negative Filter 2: Ignore Bank Passbook / Book Bank / Statement / Account Certificate images
                    val isPassbook = combinedSearch.contains("passbook") || combinedSearch.contains("bookbank") || combinedSearch.contains("book_bank") ||
                                     combinedSearch.contains("สมุดบัญชี") || combinedSearch.contains("สมุดคู่ฝาก") || combinedSearch.contains("หน้าสมุด") ||
                                     combinedSearch.contains("หน้าบัญชี") || combinedSearch.contains("account_book") || combinedSearch.contains("e-savings") ||
                                     combinedSearch.contains("esavings") || combinedSearch.contains("statement") || combinedSearch.contains("สมุดเงินฝาก")
                    if (isPassbook) return

                    // Keyword validation for bank slip indicators
                    val slipKeywords = listOf(
                        "kplus", "kbank", "scb", "ktb", "krungthai", "truemoney", "promptpay", "bbl",
                        "ttb", "mymo", "ibank", "paotang", "เป๋าตัง", "gwallet", "g-wallet", "ไทยช่วยไทย",
                        "คนละครึ่ง", "เราชนะ", "สวัสดิการแห่งรัฐ", "เงินช่วยเหลือ",
                        "slip", "สลิป", "โอน", "สำเร็จ", "รายการสำเร็จ", "โอนเงินสำเร็จ"
                    )

                    var detectedBank = "ธนาคารไทย"
                    var isSlip = false

                    if (combinedSearch.contains("k plus") || combinedSearch.contains("kplus") || combinedSearch.contains("k_+") || combinedSearch.contains("k+") || combinedSearch.contains("kbank") || combinedSearch.contains("kasikorn")) {
                        detectedBank = "กสิกรไทย (K PLUS)"
                        isSlip = true
                    } else if (combinedSearch.contains("scb")) {
                        detectedBank = "ไทยพาณิชย์ (SCB EASY)"
                        isSlip = true
                    } else if (combinedSearch.contains("krungthai") || combinedSearch.contains("ktb")) {
                        detectedBank = "กรุงไทย (Krungthai NEXT)"
                        isSlip = true
                    } else if (combinedSearch.contains("paotang") || combinedSearch.contains("เป๋าตัง") || combinedSearch.contains("gwallet") || combinedSearch.contains("g-wallet") || combinedSearch.contains("ไทยช่วยไทย")) {
                        detectedBank = if (combinedSearch.contains("ibank") || combinedSearch.contains("อิสลาม")) {
                            "iBank (อิสลามแห่งประเทศไทย)"
                        } else if (combinedSearch.contains("ไทยช่วยไทย")) {
                            "ไทยช่วยไทย (เป๋าตัง)"
                        } else {
                            "เป๋าตัง (PaoTang)"
                        }
                        isSlip = true
                    } else if (combinedSearch.contains("truemoney")) {
                        detectedBank = "TrueMoney Wallet"
                        isSlip = true
                    } else if (combinedSearch.contains("bbl") || combinedSearch.contains("bualuang")) {
                        detectedBank = "กรุงเทพ (Bualuang)"
                        isSlip = true
                    } else if (combinedSearch.contains("ttb")) {
                        detectedBank = "ttb touch"
                        isSlip = true
                    } else if (combinedSearch.contains("mymo")) {
                        detectedBank = "MyMo (ออมสิน)"
                        isSlip = true
                    } else if (combinedSearch.contains("ibank") || combinedSearch.contains("อิสลาม")) {
                        detectedBank = "iBank (อิสลามแห่งประเทศไทย)"
                        isSlip = true
                    } else if (slipKeywords.any { kw -> combinedSearch.contains(kw) }) {
                        detectedBank = "สลิปโอนเงิน"
                        isSlip = true
                    }

                    // Strict slip check & duplicate check: skip any generic or already saved images
                    if (isSlip && size > 1024) {
                        val slipFullPath = if (path != null && path.isNotEmpty()) path else name
                        if (!isSlipAlreadySaved(slipFullPath, name)) {
                            lastNotifiedSlipId = id
                            val payload = mapOf(
                                "id" to id,
                                "name" to name,
                                "path" to (path ?: ""),
                                "bankName" to detectedBank,
                                "dateAdded" to dateAdded
                            )
                            runOnUiThread {
                                methodChannel?.invokeMethod("onNewSlipDetected", payload)
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun isSlipAlreadySaved(filePath: String, fileName: String): Boolean {
        return try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val txJson = prefs.getString("flutter.rizqi_transactions_v2", "[]") ?: "[]"
            val array = JSONArray(txJson)

            val cleanPath = filePath.trim().lowercase().replace('\\', '/')
            val cleanName = fileName.trim().lowercase()
            val baseName = if (cleanName.isNotEmpty()) cleanName else cleanPath.substringAfterLast('/')

            for (i in 0 until array.length()) {
                val item = array.getJSONObject(i)
                val slipImg = item.optString("slipImageUrl", "").trim().lowercase().replace('\\', '/')
                val note = item.optString("note", "").trim().lowercase()

                if (slipImg.isNotEmpty()) {
                    val imgBase = slipImg.substringAfterLast('/')
                    if (slipImg == cleanPath || (baseName.isNotEmpty() && imgBase == baseName) || (baseName.isNotEmpty() && slipImg.endsWith(baseName))) {
                        return true
                    }
                }
                if (baseName.isNotEmpty() && note.contains(baseName)) {
                    return true
                }
            }
            false
        } catch (e: Exception) {
            false
        }
    }

    private fun hasStoragePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun getRequiredPermissions(): Array<String> {
        val permissions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.READ_MEDIA_IMAGES)
            permissions.add(Manifest.permission.READ_MEDIA_VIDEO)
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            permissions.add(Manifest.permission.READ_EXTERNAL_STORAGE)
            permissions.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
        }
        permissions.add(Manifest.permission.RECORD_AUDIO)
        permissions.add(Manifest.permission.CAMERA)
        return permissions.toTypedArray()
    }

    private fun requestPermissionsFromSystem() {
        val permissions = getRequiredPermissions()
        val notGranted = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (notGranted.isEmpty()) {
            registerMediaContentObserver()
            startBackgroundSlipService()
            pendingPermissionResult?.success(checkPermissionsStatus())
            pendingPermissionResult = null
        } else {
            ActivityCompat.requestPermissions(this, notGranted.toTypedArray(), PERMISSION_REQUEST_CODE)
        }
    }

    private fun checkPermissionsStatus(): Map<String, Boolean> {
        val status = mutableMapOf<String, Boolean>()
        val hasStorage = hasStoragePermission()
        val hasAudio = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        val hasCamera = ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED

        status["storage"] = hasStorage
        status["audio"] = hasAudio
        status["camera"] = hasCamera
        status["allGranted"] = hasStorage && hasAudio
        return status
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val status = checkPermissionsStatus()
            val isStorageGranted = status["storage"] == true

            if (isStorageGranted) {
                registerMediaContentObserver()
                startBackgroundSlipService()
            } else {
                showPermissionDeniedDialog()
            }

            pendingPermissionResult?.success(status)
            pendingPermissionResult = null
        }
    }

    private fun showPermissionDeniedDialog() {
        AlertDialog.Builder(this)
            .setTitle("จำเป็นต้องขอสิทธิ์เข้าถึงรูปภาพ")
            .setMessage("หากไม่ให้สิทธิ์ จะไม่สามารถใช้ฟีเจอร์ดึงสลิปธนาคารอัตโนมัติได้")
            .setCancelable(false)
            .setPositiveButton("ไปที่การตั้งค่า") { dialog, _ ->
                dialog.dismiss()
                openAppSettings()
            }
            .setNegativeButton("ยกเลิก") { dialog, _ ->
                dialog.dismiss()
            }
            .show()
    }

    private fun openAppSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun startInAppVoiceRecognition(result: MethodChannel.Result) {
        runOnUiThread {
            if (!SpeechRecognizer.isRecognitionAvailable(this)) {
                // Fallback to intent if in-app service not available
                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, "th-TH")
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, "th-TH")
                    putExtra(RecognizerIntent.EXTRA_ONLY_RETURN_LANGUAGE_PREFERENCE, "th-TH")
                }
                try {
                    pendingSpeechResult = result
                    startActivityForResult(intent, SPEECH_REQUEST)
                } catch (e: Exception) {
                    result.success("")
                }
                return@runOnUiThread
            }

            try {
                inAppSpeechRecognizer?.destroy()
            } catch (e: Exception) {}

            var hasResponded = false

            try {
                inAppSpeechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
                val recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, "th-TH")
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, "th-TH")
                    putExtra(RecognizerIntent.EXTRA_ONLY_RETURN_LANGUAGE_PREFERENCE, "th-TH")
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                }

                inAppSpeechRecognizer?.setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {}
                    override fun onBeginningOfSpeech() {}
                    override fun onRmsChanged(rmsdB: Float) {}
                    override fun onBufferReceived(buffer: ByteArray?) {}
                    override fun onEndOfSpeech() {}
                    override fun onError(error: Int) {
                        if (!hasResponded) {
                            hasResponded = true
                            result.success("")
                        }
                    }
                    override fun onResults(results: Bundle?) {
                        if (!hasResponded) {
                            hasResponded = true
                            val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                            val text = if (!matches.isNullOrEmpty()) matches[0] else ""
                            result.success(text)
                        }
                    }
                    override fun onPartialResults(partialResults: Bundle?) {}
                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })

                inAppSpeechRecognizer?.startListening(recognizerIntent)
            } catch (e: Exception) {
                if (!hasResponded) {
                    hasResponded = true
                    result.success("")
                }
            }
        }
    }

    private fun stopInAppVoiceRecognition() {
        runOnUiThread {
            try {
                inAppSpeechRecognizer?.stopListening()
            } catch (e: Exception) {}
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        when (requestCode) {
            PICK_FILE_REQUEST -> {
                if (resultCode == Activity.RESULT_OK && data?.data != null) {
                    val uri = data.data!!
                    try {
                        contentResolver.openInputStream(uri)?.use { stream ->
                            val text = stream.bufferedReader().use { it.readText() }
                            pendingFileResult?.success(text)
                        } ?: run {
                            pendingFileResult?.success(null)
                        }
                    } catch (e: Exception) {
                        pendingFileResult?.success(null)
                    }
                } else {
                    pendingFileResult?.success(null)
                }
                pendingFileResult = null
            }
            PICK_IMAGE_REQUEST -> {
                if (resultCode == Activity.RESULT_OK && data != null && data.data != null) {
                    val uri: Uri = data.data!!
                    val filePath = copyUriToCache(uri)
                    pendingImageResult?.success(filePath)
                } else {
                    pendingImageResult?.success(null)
                }
                pendingImageResult = null
            }
            SPEECH_REQUEST -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    val results = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                    val spokenText = if (!results.isNullOrEmpty()) results[0] else null
                    pendingSpeechResult?.success(spokenText)
                } else {
                    pendingSpeechResult?.success(null)
                }
                pendingSpeechResult = null
            }
        }
    }

    private fun queryDeviceBankSlips(daysLimit: Int): List<Map<String, Any>> {
        val slipList = mutableListOf<Map<String, Any>>()
        val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            arrayOf(
                MediaStore.Images.Media._ID,
                MediaStore.Images.Media.DISPLAY_NAME,
                MediaStore.Images.Media.DATE_ADDED,
                MediaStore.Images.Media.SIZE,
                MediaStore.Images.Media.DATA,
                MediaStore.Images.Media.RELATIVE_PATH,
                MediaStore.Images.Media.BUCKET_DISPLAY_NAME
            )
        } else {
            arrayOf(
                MediaStore.Images.Media._ID,
                MediaStore.Images.Media.DISPLAY_NAME,
                MediaStore.Images.Media.DATE_ADDED,
                MediaStore.Images.Media.SIZE,
                MediaStore.Images.Media.DATA
            )
        }

        val (selection, selectionArgs) = if (daysLimit > 0) {
            val cutoffTimestamp = (System.currentTimeMillis() / 1000) - (daysLimit * 24L * 60L * 60L)
            Pair("${MediaStore.Images.Media.DATE_ADDED} >= ?", arrayOf(cutoffTimestamp.toString()))
        } else {
            Pair(null, null)
        }
        val sortOrder = "${MediaStore.Images.Media.DATE_ADDED} DESC"

        try {
            val cursor: Cursor? = contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                sortOrder
            )

            cursor?.use {
                val idColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
                val nameColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)
                val dateColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_ADDED)
                val sizeColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media.SIZE)
                val dataColumn = it.getColumnIndex(MediaStore.Images.Media.DATA)
                val relPathColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) it.getColumnIndex(MediaStore.Images.Media.RELATIVE_PATH) else -1
                val bucketColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) it.getColumnIndex(MediaStore.Images.Media.BUCKET_DISPLAY_NAME) else -1

                val bankKeywords = listOf(
                    "kplus", "kbank", "scb", "ktb", "krungthai", "truemoney", "promptpay", "bbl",
                    "ttb", "mymo", "ibank", "paotang", "เป๋าตัง", "gwallet", "g-wallet", "ไทยช่วยไทย",
                    "คนละครึ่ง", "เราชนะ", "สวัสดิการแห่งรัฐ", "เงินช่วยเหลือ",
                    "slip", "สลิป", "โอน", "สำเร็จ", "รายการสำเร็จ", "โอนเงินสำเร็จ"
                )

                while (it.moveToNext() && slipList.size < 1000) {
                    val id = it.getLong(idColumn)
                    val name = it.getString(nameColumn) ?: ""
                    val dateAdded = it.getLong(dateColumn) * 1000
                    val size = it.getLong(sizeColumn)
                    val path = if (dataColumn != -1) it.getString(dataColumn) else ""
                    val relPath = if (relPathColumn != -1) it.getString(relPathColumn) ?: "" else ""
                    val bucketName = if (bucketColumn != -1) it.getString(bucketColumn) ?: "" else ""

                    val contentUri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id).toString()
                    val lowerName = name.lowercase()
                    val lowerPath = path?.lowercase() ?: ""
                    val lowerRelPath = relPath.lowercase()
                    val lowerBucket = bucketName.lowercase()
                    val combinedSearch = "$lowerName $lowerPath $lowerRelPath $lowerBucket"

                    val isMyQr = lowerName.contains("myqr") || lowerName.contains("my_qr") || lowerName.contains("my-qr") ||
                                 lowerPath.contains("myqr") || lowerPath.contains("my_qr") || lowerPath.contains("my-qr") ||
                                 lowerName.contains("qr_receive") || lowerName.contains("receive_qr") || lowerName.contains("promptpay_qr")
                    if (isMyQr) continue

                    // Negative Filter 2: Ignore Passbooks / Book Bank / Statements / Account details
                    val isPassbook = lowerName.contains("passbook") || lowerName.contains("bookbank") || lowerName.contains("book_bank") ||
                                     lowerName.contains("สมุดบัญชี") || lowerName.contains("สมุดคู่ฝาก") || lowerName.contains("หน้าสมุด") ||
                                     lowerName.contains("หน้าบัญชี") || lowerName.contains("account_book") || lowerName.contains("e-savings") ||
                                     lowerName.contains("esavings") || lowerName.contains("statement") || lowerName.contains("สมุดเงินฝาก") ||
                                     lowerPath.contains("passbook") || lowerPath.contains("bookbank") || lowerPath.contains("book_bank") ||
                                     lowerPath.contains("สมุดบัญชี") || lowerPath.contains("สมุดคู่ฝาก") || lowerPath.contains("หน้าสมุด") ||
                                     lowerPath.contains("หน้าบัญชี") || lowerPath.contains("account_book") || lowerPath.contains("e-savings") ||
                                     lowerPath.contains("esavings") || lowerPath.contains("statement") || lowerPath.contains("สมุดเงินฝาก")
                    if (isPassbook) continue

                    var detectedBank = "ธนาคารไทย"
                    var isSlip = false

                    if (combinedSearch.contains("k plus") || combinedSearch.contains("kplus") || combinedSearch.contains("k_+") || combinedSearch.contains("k+") || combinedSearch.contains("kbank") || combinedSearch.contains("kasikorn") || combinedSearch.contains("k-plus")) {
                        detectedBank = "กสิกรไทย (K PLUS)"
                        isSlip = true
                    } else if (combinedSearch.contains("scb")) {
                        detectedBank = "ไทยพาณิชย์ (SCB EASY)"
                        isSlip = true
                    } else if (combinedSearch.contains("krungthai") || combinedSearch.contains("ktb")) {
                        detectedBank = "กรุงไทย (Krungthai NEXT)"
                        isSlip = true
                    } else if (combinedSearch.contains("paotang") || combinedSearch.contains("เป๋าตัง") || combinedSearch.contains("gwallet") || combinedSearch.contains("g-wallet") || combinedSearch.contains("ไทยช่วยไทย") || combinedSearch.contains("pictures/paotang") || lowerBucket == "paotang" || lowerBucket == "เป๋าตัง") {
                        detectedBank = if (combinedSearch.contains("ibank") || combinedSearch.contains("อิสลาม") || combinedSearch.contains("islamic")) {
                            "iBank (อิสลามแห่งประเทศไทย)"
                        } else if (combinedSearch.contains("ไทยช่วยไทย") || combinedSearch.contains("สวัสดิการ") || combinedSearch.contains("คนละครึ่ง") || combinedSearch.contains("เราชนะ")) {
                            "ไทยช่วยไทย (เป๋าตัง)"
                        } else {
                            "เป๋าตัง (PaoTang)"
                        }
                        isSlip = true
                    } else if (combinedSearch.contains("truemoney")) {
                        detectedBank = "TrueMoney Wallet"
                        isSlip = true
                    } else if (combinedSearch.contains("bbl") || combinedSearch.contains("bualuang")) {
                        detectedBank = "กรุงเทพ (Bualuang)"
                        isSlip = true
                    } else if (combinedSearch.contains("ttb")) {
                        detectedBank = "ttb touch"
                        isSlip = true
                    } else if (combinedSearch.contains("mymo")) {
                        detectedBank = "MyMo (ออมสิน)"
                        isSlip = true
                    } else if (combinedSearch.contains("ibank") || combinedSearch.contains("อิสลาม") || combinedSearch.contains("islamic")) {
                        detectedBank = "iBank (อิสลามแห่งประเทศไทย)"
                        isSlip = true
                    } else if (bankKeywords.any { kw -> combinedSearch.contains(kw) }) {
                        detectedBank = "สลิปโอนเงิน"
                        isSlip = true
                    }

                    if (isSlip && size > 1024) {
                        val item = mutableMapOf<String, Any>(
                            "id" to id.toString(),
                            "name" to name,
                            "path" to (path ?: contentUri),
                            "uri" to contentUri,
                            "dateAdded" to dateAdded,
                            "size" to size,
                            "bankName" to detectedBank
                        )
                        slipList.add(item)
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Direct Physical Directory Scan for PaoTang folder to ensure 100% detection regardless of MediaStore index status
        try {
            val directFolders = listOf(
                File("/storage/emulated/0/Pictures/PaoTang"),
                File("/storage/emulated/0/Pictures/เป๋าตัง"),
                File("/storage/emulated/0/DCIM/PaoTang"),
                File("/storage/emulated/0/Download/PaoTang"),
                File(android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_PICTURES), "PaoTang"),
                File(android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_PICTURES), "เป๋าตัง"),
                File(android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DCIM), "PaoTang"),
                File(android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS), "PaoTang")
            )

            for (folder in directFolders) {
                if (folder.exists() && folder.isDirectory) {
                    val files = folder.listFiles { f ->
                        val ext = f.extension.lowercase()
                        (ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "webp") && f.length() > 1024
                    }
                    if (files != null) {
                        for (file in files) {
                            val alreadyInList = slipList.any { (it["path"] as? String) == file.absolutePath }
                            if (!alreadyInList) {
                                val fnameLower = file.name.lowercase()
                                val detectedBank = if (fnameLower.contains("ibank") || fnameLower.contains("อิสลาม") || fnameLower.contains("islamic")) {
                                    "iBank (อิสลามแห่งประเทศไทย)"
                                } else if (fnameLower.contains("ไทยช่วยไทย") || fnameLower.contains("สวัสดิการ")) {
                                    "ไทยช่วยไทย (เป๋าตัง)"
                                } else {
                                    "เป๋าตัง (PaoTang)"
                                }
                                val item = mutableMapOf<String, Any>(
                                    "id" to file.absolutePath.hashCode().toString(),
                                    "name" to file.name,
                                    "path" to file.absolutePath,
                                    "uri" to Uri.fromFile(file).toString(),
                                    "dateAdded" to file.lastModified(),
                                    "size" to file.length(),
                                    "bankName" to detectedBank
                                )
                                slipList.add(item)
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return slipList
    }

    private fun checkInstalledBankingApps(): List<Map<String, String>> {
        val pm = packageManager
        val bankingPackages = mapOf(
            "com.kasikorn.retail.mbanking.wap" to "K PLUS (กสิกรไทย)",
            "com.scb.phone" to "SCB EASY (ไทยพาณิชย์)",
            "ktbcs.netbank" to "Krungthai NEXT (กรุงไทย)",
            "th.co.truemoney.wallet" to "TrueMoney Wallet",
            "com.bbl.mPlus" to "Bualuang mBanking (กรุงเทพ)",
            "com.ttbbank.oneapp" to "ttb touch (ทหารไทยธนชาต)",
            "com.gsb.mymo" to "MyMo (ธนาคารออมสิน)",
            "th.co.cimbthai.moo" to "CIMB Thai Digital",
            "th.co.lhbank.mobile" to "LHB You (LH Bank)"
        )

        val installedList = mutableListOf<Map<String, String>>()
        for ((pkg, name) in bankingPackages) {
            try {
                pm.getPackageInfo(pkg, 0)
                installedList.add(mapOf("packageName" to pkg, "appName" to name, "isInstalled" to "true"))
            } catch (e: PackageManager.NameNotFoundException) {
                // Not installed
            }
        }
        return installedList
    }

    private fun copyUriToCache(uri: Uri): String? {
        return try {
            val inputStream: InputStream? = contentResolver.openInputStream(uri)
            val fileName = "slip_${System.currentTimeMillis()}.jpg"
            val file = File(cacheDir, fileName)
            val outputStream = FileOutputStream(file)

            inputStream?.use { input ->
                outputStream.use { output ->
                    input.copyTo(output)
                }
            }
            file.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun compressAndSaveSlipInternal(sourcePath: String, customName: String?): String? {
        return try {
            val sourceFile = File(sourcePath)
            if (!sourceFile.exists()) return null

            val slipsDir = File(filesDir, "saved_slips")
            if (!slipsDir.exists()) {
                slipsDir.mkdirs()
            }

            val fileName = if (!customName.isNullOrEmpty()) {
                if (customName.endsWith(".jpg") || customName.endsWith(".jpeg")) customName else "$customName.jpg"
            } else {
                val cleanName = sourceFile.nameWithoutExtension
                val hash = cleanName.hashCode().toString().replace("-", "")
                "slip_${hash}.jpg"
            }

            val targetFile = File(slipsDir, fileName)
            if (targetFile.exists() && targetFile.length() > 0) {
                return targetFile.absolutePath
            }

            val options = android.graphics.BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            android.graphics.BitmapFactory.decodeFile(sourcePath, options)

            val maxDim = 1200
            var sampleSize = 1
            if (options.outHeight > maxDim || options.outWidth > maxDim) {
                val halfHeight = options.outHeight / 2
                val halfWidth = options.outWidth / 2
                while (halfHeight / sampleSize >= maxDim && halfWidth / sampleSize >= maxDim) {
                    sampleSize *= 2
                }
            }

            val decodeOptions = android.graphics.BitmapFactory.Options().apply {
                inSampleSize = sampleSize
                inPreferredConfig = android.graphics.Bitmap.Config.RGB_565
            }

            val bitmap = android.graphics.BitmapFactory.decodeFile(sourcePath, decodeOptions) ?: return null

            FileOutputStream(targetFile).use { out ->
                bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 78, out)
                out.flush()
            }
            bitmap.recycle()

            targetFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private val SCAN_NOTIFICATION_ID = 2001
    private val SCAN_COMPLETED_NOTIFICATION_ID = 2002
    private val SCAN_CHANNEL_ID = "meow_slip_sync_channel"

    private fun ensureScanNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                SCAN_CHANNEL_ID,
                "สถานะการดึงสลิป (Slip Scan Status)",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "แจ้งเตือนสถานะการค้นหาและประมวลผลสลิปในเครื่อง"
                setShowBadge(false)
            }
            manager.createNotificationChannel(channel)
        }
    }

    private fun showScanProgressNotification(title: String, message: String) {
        try {
            val serviceIntent = Intent(this, SlipDetectionService::class.java).apply {
                action = SlipDetectionService.ACTION_START_SCAN
                putExtra(SlipDetectionService.EXTRA_SCAN_TITLE, title)
                putExtra(SlipDetectionService.EXTRA_SCAN_MESSAGE, message)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            showLocalScanProgressNotification(title, message)
        }
    }

    private fun showLocalScanProgressNotification(title: String, message: String) {
        ensureScanNotificationChannel()
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            SCAN_NOTIFICATION_ID,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val catLargeIcon = BitmapFactory.decodeResource(resources, R.drawable.ic_notification_cat_large)
            ?: BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)

        val notification = NotificationCompat.Builder(this, SCAN_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(R.drawable.ic_stat_cat)
            .setLargeIcon(catLargeIcon)
            .setColor(0xFFFF8A00.toInt())
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setProgress(0, 0, true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(SCAN_NOTIFICATION_ID, notification)
    }

    private fun showScanCompletedNotification(title: String, message: String) {
        cancelScanProgressNotification()
        ensureScanNotificationChannel()

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            SCAN_COMPLETED_NOTIFICATION_ID,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val catLargeIcon = BitmapFactory.decodeResource(resources, R.drawable.ic_notification_cat_large)
            ?: BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)

        val notification = NotificationCompat.Builder(this, SCAN_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(R.drawable.ic_stat_cat)
            .setLargeIcon(catLargeIcon)
            .setColor(0xFFFF8A00.toInt())
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(SCAN_COMPLETED_NOTIFICATION_ID, notification)
    }

    private fun cancelScanProgressNotification() {
        try {
            val serviceIntent = Intent(this, SlipDetectionService::class.java).apply {
                action = SlipDetectionService.ACTION_STOP_SCAN
            }
            startService(serviceIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(SCAN_NOTIFICATION_ID)
    }

    override fun onDestroy() {
        if (isReloadReceiverRegistered) {
            try {
                unregisterReceiver(reloadReceiver)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        unregisterMediaContentObserver()
        super.onDestroy()
    }
}
