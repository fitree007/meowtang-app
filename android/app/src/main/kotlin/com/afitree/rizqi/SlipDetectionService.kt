package com.afitree.rizqi

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.database.ContentObserver
import android.database.Cursor
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.MediaStore
import androidx.core.app.NotificationCompat
import org.json.JSONArray

import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.os.PowerManager

class SlipDetectionService : Service() {
    companion object {
        const val ACTION_START_SCAN = "com.afitree.rizqi.ACTION_START_SCAN"
        const val ACTION_STOP_SCAN = "com.afitree.rizqi.ACTION_STOP_SCAN"
        const val EXTRA_SCAN_TITLE = "extra_scan_title"
        const val EXTRA_SCAN_MESSAGE = "extra_scan_message"

        const val SCAN_NOTIFICATION_ID = 2001
        const val HEADS_UP_CHANNEL_ID = "meow_slip_heads_up_channel_v4"
        const val SCAN_CHANNEL_ID = "meow_slip_sync_channel_v4"
    }

    private var mediaObserver: ContentObserver? = null
    private var lastNotifiedSlipId: String? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var isScanningForeground = false

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
        registerMediaObserver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == ACTION_START_SCAN) {
            val title = intent.getStringExtra(EXTRA_SCAN_TITLE) ?: "เหมียวตังค์: กำลังดึงและอ่านสลิป... 🔄"
            val message = intent.getStringExtra(EXTRA_SCAN_MESSAGE) ?: "ระบบกำลังประมวลผลสลิปในเครื่อง"
            startScanForeground(title, message)
        } else if (action == ACTION_STOP_SCAN) {
            stopScanForeground()
        }
        return START_STICKY
    }

    private fun startScanForeground(title: String, message: String) {
        acquireWakeLock()
        isScanningForeground = true

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

        val notification = NotificationCompat.Builder(this, SCAN_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(R.drawable.ic_notification_cat)
            .setLargeIcon(catLargeIcon)
            .setColor(0xFFFF8A00.toInt())
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setProgress(0, 0, true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(SCAN_NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(SCAN_NOTIFICATION_ID, notification)
        }
    }

    private fun stopScanForeground() {
        releaseWakeLock()
        if (isScanningForeground) {
            isScanningForeground = false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        }
    }

    private fun acquireWakeLock() {
        try {
            if (wakeLock == null) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "MeowTang::SlipScanWakeLock").apply {
                    setReferenceCounted(false)
                }
            }
            wakeLock?.let {
                if (!it.isHeld) {
                    it.acquire(15 * 60 * 1000L) // 15 minutes safety timeout
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Scan status foreground channel (LOW importance so no annoying chime on updates)
            val scanChannel = NotificationChannel(
                SCAN_CHANNEL_ID,
                "สถานะการดึงสลิป (Slip Scan Status)",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "แจ้งเตือนสถานะการค้นหาและประมวลผลสลิปในเครื่อง"
                setShowBadge(false)
            }
            manager.createNotificationChannel(scanChannel)

            // High-priority Channel for Actionable Heads-Up Notification (only pops up when slip is detected)
            val headsUpChannel = NotificationChannel(
                HEADS_UP_CHANNEL_ID,
                "แจ้งเตือนตรวจพบสลิปโอนเงิน (Heads-up Alert)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "แจ้งเตือนเด้งทันทีเมื่อพบสลิปโอนเงินใหม่ แตะเพื่อเปิดหน้าบันทึก"
                enableVibration(true)
                setShowBadge(true)
            }
            manager.createNotificationChannel(headsUpChannel)
        }
    }

    private fun registerMediaObserver() {
        if (mediaObserver != null) return
        val handler = Handler(Looper.getMainLooper())
        mediaObserver = object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                checkForNewBankSlip()
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

    private fun checkForNewBankSlip() {
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
                    val path = if (dataColumn != -1) it.getString(dataColumn) else ""
                    val relPath = if (relPathColumn != -1) it.getString(relPathColumn) ?: "" else ""
                    val bucketName = if (bucketColumn != -1) it.getString(bucketColumn) ?: "" else ""
                    val size = it.getLong(sizeColumn)

                    if (id == lastNotifiedSlipId) return

                    val lowerName = name.lowercase()
                    val lowerPath = path?.lowercase() ?: ""
                    val lowerRelPath = relPath.lowercase()
                    val lowerBucket = bucketName.lowercase()
                    val combinedSearch = "$lowerName $lowerPath $lowerRelPath $lowerBucket"

                    // Negative Filter 1: Ignore My QR / Receive Money QR codes (only pure QR templates)
                    val isMyQr = combinedSearch.contains("myqr") || combinedSearch.contains("my_qr") || combinedSearch.contains("my-qr") ||
                                 combinedSearch.contains("qr_receive") || combinedSearch.contains("receive_qr") || combinedSearch.contains("promptpay_qr")
                    if (isMyQr) return

                    // Negative Filter 2: Ignore Bank Passbook / Book Bank / Statement / Account Certificate images
                    val isPassbook = combinedSearch.contains("passbook") || combinedSearch.contains("bookbank") || combinedSearch.contains("book_bank") ||
                                     combinedSearch.contains("สมุดบัญชี") || combinedSearch.contains("สมุดคู่ฝาก") || combinedSearch.contains("หน้าสมุด") ||
                                     combinedSearch.contains("หน้าบัญชี") || combinedSearch.contains("account_book") || combinedSearch.contains("e-savings") ||
                                     combinedSearch.contains("esavings") || combinedSearch.contains("statement") || combinedSearch.contains("สมุดเงินฝาก")
                    if (isPassbook) return

                    // 1. Bank Slip & Incoming Money Keywords Validation
                    val slipKeywords = listOf(
                        "kplus", "kbank", "scb", "ktb", "krungthai", "truemoney", "promptpay", "bbl",
                        "ttb", "mymo", "ibank", "paotang", "เป๋าตัง", "gwallet", "g-wallet", "ไทยช่วยไทย",
                        "คนละครึ่ง", "เราชนะ", "สวัสดิการแห่งรัฐ", "เงินช่วยเหลือ",
                        "slip", "สลิป", "โอน", "สำเร็จ", "รายการสำเร็จ", "โอนเงินสำเร็จ",
                        "เงินเข้า", "โอนเข้า", "รับเงิน", "ได้รับเงิน", "เงินโอนเข้า", "เงินเดือน", "ยอดเงินเข้า"
                    )

                    var detectedBank = "ธนาคารไทย"
                    var isSlip = false
                    val isIncomeSlip = combinedSearch.contains("เงินเข้า") || combinedSearch.contains("โอนเข้า") ||
                                       combinedSearch.contains("รับเงิน") || combinedSearch.contains("เงินโอนเข้า") ||
                                       combinedSearch.contains("เงินเดือน") || combinedSearch.contains("เงินช่วยเหลือ") ||
                                       combinedSearch.contains("สวัสดิการ")

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
                    } else if (lowerPath.contains("ibank") || lowerName.contains("ibank") || lowerPath.contains("อิสลาม") || lowerName.contains("อิสลาม")) {
                        detectedBank = "iBank (อิสลามแห่งประเทศไทย)"
                        isSlip = true
                    } else if (slipKeywords.any { kw -> lowerName.contains(kw) || lowerPath.contains(kw) }) {
                        detectedBank = if (isIncomeSlip) "สลิปรับเงินโอนเข้า" else "สลิปโอนเงิน"
                        isSlip = true
                    }

                    // 2. Strict slip check & Duplicate check against Room / SharedPreferences
                    if (isSlip && size > 1024) {
                        val slipFullPath = if (path.isNotEmpty()) path else name
                        if (!isSlipAlreadySaved(slipFullPath, name)) {
                            lastNotifiedSlipId = id
                            showActionableHeadsUpNotification(detectedBank, slipFullPath, isIncomeSlip)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Duplicate Check: Checks if the slip path or filename is already in the database
     */
    private fun isSlipAlreadySaved(filePath: String, fileName: String): Boolean {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val txJson = prefs.getString("flutter.rizqi_transactions_v2", "[]") ?: "[]"
            val array = JSONArray(txJson)

            val cleanPath = filePath.trim().lowercase()
            val cleanName = fileName.trim().lowercase()

            for (i in 0 until array.length()) {
                val item = array.getJSONObject(i)
                val slipImg = item.optString("slipImageUrl", "").trim().lowercase()
                val note = item.optString("note", "").trim().lowercase()

                if (slipImg.isNotEmpty() && (slipImg == cleanPath || slipImg.endsWith(cleanName))) {
                    return true
                }
                if (cleanName.isNotEmpty() && note.contains(cleanName)) {
                    return true
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }

    /**
     * Actionable Heads-up Notification: Tapping opens app with PendingIntent directly to slip review
     */
    private fun showActionableHeadsUpNotification(bankName: String, slipPath: String, isIncome: Boolean = false) {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            putExtra("slip_path", slipPath)
            putExtra("auto_open_slip", true)
            putExtra("is_income", isIncome)
            putExtra("action", "EDIT_SLIP")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            (System.currentTimeMillis() % 100000).toInt(),
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val title = if (isIncome) "💰 พบยอดเงินเข้าใหม่ (รายรับ)" else "🧾 พบสลิปใหม่ แตะเพื่อบันทึก"
        val desc = if (isIncome) "ตรวจพบยอดเงินเข้า: $bankName แตะเพื่อตรวจสอบและบันทึก" else "ตรวจพบ: $bankName แตะเพื่อตรวจสอบยอดเงินและบันทึก"

        val catLargeIcon = BitmapFactory.decodeResource(resources, R.drawable.ic_notification_cat_large)

        val notification = NotificationCompat.Builder(this, HEADS_UP_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(desc)
            .setSmallIcon(R.drawable.ic_notification_cat)
            .setLargeIcon(catLargeIcon)
            .setColor(0xFFFF8A00.toInt())
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify((System.currentTimeMillis() % 10000).toInt() + 100, notification)
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        stopScanForeground()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        stopScanForeground()
        mediaObserver?.let {
            contentResolver.unregisterContentObserver(it)
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
