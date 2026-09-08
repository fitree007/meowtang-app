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

class SlipDetectionService : Service() {
    private val HEADS_UP_CHANNEL_ID = "rizqi_slip_heads_up_channel"

    private var mediaObserver: ContentObserver? = null
    private var lastNotifiedSlipId: String? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
        registerMediaObserver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

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
        val projection = arrayOf(
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DISPLAY_NAME,
            MediaStore.Images.Media.DATE_ADDED,
            MediaStore.Images.Media.SIZE,
            MediaStore.Images.Media.DATA
        )

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

                    val id = it.getLong(idColumn).toString()
                    val name = it.getString(nameColumn) ?: ""
                    val path = if (dataColumn != -1) it.getString(dataColumn) else ""
                    val size = it.getLong(sizeColumn)

                    if (id == lastNotifiedSlipId) return

                    val lowerName = name.lowercase()
                    val lowerPath = path?.lowercase() ?: ""

                    // Negative Filter 1: Ignore My QR / Receive Money QR codes (only pure QR templates)
                    val isMyQr = lowerName.contains("myqr") || lowerName.contains("my_qr") || lowerName.contains("my-qr") ||
                                 lowerPath.contains("myqr") || lowerPath.contains("my_qr") || lowerPath.contains("my-qr") ||
                                 lowerName.contains("qr_receive") || lowerName.contains("receive_qr") || lowerName.contains("promptpay_qr")
                    if (isMyQr) return

                    // Negative Filter 2: Ignore Bank Passbook / Book Bank / Statement / Account Certificate images (e.g. Krungthai passbook)
                    val isPassbook = lowerName.contains("passbook") || lowerName.contains("bookbank") || lowerName.contains("book_bank") ||
                                     lowerName.contains("สมุดบัญชี") || lowerName.contains("สมุดคู่ฝาก") || lowerName.contains("หน้าสมุด") ||
                                     lowerName.contains("หน้าบัญชี") || lowerName.contains("account_book") || lowerName.contains("e-savings") ||
                                     lowerName.contains("esavings") || lowerName.contains("statement") || lowerName.contains("สมุดเงินฝาก") ||
                                     lowerPath.contains("passbook") || lowerPath.contains("bookbank") || lowerPath.contains("book_bank") ||
                                     lowerPath.contains("สมุดบัญชี") || lowerPath.contains("สมุดคู่ฝาก") || lowerPath.contains("หน้าสมุด") ||
                                     lowerPath.contains("หน้าบัญชี") || lowerPath.contains("account_book") || lowerPath.contains("e-savings") ||
                                     lowerPath.contains("esavings") || lowerPath.contains("statement") || lowerPath.contains("สมุดเงินฝาก")
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
                    val isIncomeSlip = lowerName.contains("เงินเข้า") || lowerPath.contains("เงินเข้า") ||
                                       lowerName.contains("โอนเข้า") || lowerPath.contains("โอนเข้า") ||
                                       lowerName.contains("รับเงิน") || lowerPath.contains("รับเงิน") ||
                                       lowerName.contains("เงินโอนเข้า") || lowerPath.contains("เงินโอนเข้า") ||
                                       lowerName.contains("เงินเดือน") || lowerPath.contains("เงินเดือน") ||
                                       lowerName.contains("เงินช่วยเหลือ") || lowerPath.contains("เงินช่วยเหลือ") ||
                                       lowerName.contains("สวัสดิการ") || lowerPath.contains("สวัสดิการ")

                    if (lowerPath.contains("k plus") || lowerPath.contains("kplus") || lowerName.contains("kbank") || lowerPath.contains("kbank")) {
                        detectedBank = "กสิกรไทย (K PLUS)"
                        isSlip = true
                    } else if (lowerPath.contains("scb") || lowerName.contains("scb")) {
                        detectedBank = "ไทยพาณิชย์ (SCB EASY)"
                        isSlip = true
                    } else if (lowerPath.contains("krungthai") || lowerPath.contains("ktb") || lowerName.contains("ktb") || lowerName.contains("krungthai")) {
                        detectedBank = "กรุงไทย (Krungthai NEXT)"
                        isSlip = true
                    } else if (lowerPath.contains("paotang") || lowerName.contains("paotang") || lowerPath.contains("เป๋าตัง") || lowerName.contains("เป๋าตัง") || lowerPath.contains("gwallet") || lowerPath.contains("g-wallet") || lowerPath.contains("ไทยช่วยไทย") || lowerName.contains("ไทยช่วยไทย")) {
                        detectedBank = if (lowerPath.contains("ibank") || lowerName.contains("ibank") || lowerPath.contains("อิสลาม") || lowerName.contains("อิสลาม")) {
                            "iBank (อิสลามแห่งประเทศไทย)"
                        } else if (lowerPath.contains("ไทยช่วยไทย") || lowerName.contains("ไทยช่วยไทย")) {
                            "ไทยช่วยไทย (เป๋าตัง)"
                        } else {
                            "เป๋าตัง (PaoTang)"
                        }
                        isSlip = true
                    } else if (lowerPath.contains("truemoney") || lowerName.contains("truemoney")) {
                        detectedBank = "TrueMoney Wallet"
                        isSlip = true
                    } else if (lowerPath.contains("bbl") || lowerName.contains("bbl") || lowerPath.contains("bualuang")) {
                        detectedBank = "กรุงเทพ (Bualuang)"
                        isSlip = true
                    } else if (lowerPath.contains("ttb") || lowerName.contains("ttb")) {
                        detectedBank = "ttb touch"
                        isSlip = true
                    } else if (lowerPath.contains("mymo") || lowerName.contains("mymo")) {
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

        val notification = NotificationCompat.Builder(this, HEADS_UP_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(desc)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setLargeIcon(BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify((System.currentTimeMillis() % 10000).toInt() + 100, notification)
    }

    override fun onDestroy() {
        mediaObserver?.let {
            contentResolver.unregisterContentObserver(it)
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
