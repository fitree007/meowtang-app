package com.afitree.rizqi

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.widget.Toast
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.regex.Pattern

/**
 * BankNotificationListenerService
 * Automatically captures incoming money / income notifications from Thai Banking apps & Mobile Wallets
 * and logs them directly to Rizqi Expense Tracker so users never forget tracking their income!
 */
class BankNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "BankNotificationListener"
        private const val CHANNEL_ID = "rizqi_income_channel"
        private const val CHANNEL_NAME = "บันทึกเงินเข้าอัตโนมัติ"

        // Cache last detected notification to prevent duplicate recording within 60 seconds
        private var lastDetectedText: String = ""
        private var lastDetectedAmount: Double = 0.0
        private var lastDetectedTime: Long = 0L

        // Known Thai Banking & Wallet Package Names
        private val BANK_PACKAGES = mapOf(
            "com.kasikorn.retail.mbanking.wap" to "กสิกรไทย (K PLUS)",
            "com.scb.phone" to "ไทยพาณิชย์ (SCB EASY)",
            "ktbcs.netbank" to "กรุงไทย (Krungthai NEXT)",
            "com.bbl.mobilebanking" to "กรุงเทพ (Bualuang m)",
            "com.tmbbank.oneapp" to "ttb touch",
            "th.or.gsb.mymo" to "MyMo (ออมสิน)",
            "krungsri.kma" to "กรุงศรี (KMA)",
            "th.co.cimbthai.mo" to "CIMB Thai",
            "th.co.truemoney.wallet" to "TrueMoney Wallet",
            "com.shopeepay.th" to "ShopeePay"
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val pkg = sbn.packageName ?: ""
        val extras = sbn.notification?.extras ?: return
        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        val bigText = extras.getCharSequence("android.bigText")?.toString() ?: ""
        val combinedText = "$title $text $bigText".trim()

        if (combinedText.isEmpty()) return

        // 1. Check if the app is a known bank package OR if notification text contains Thai income keywords
        val bankName = BANK_PACKAGES[pkg] ?: detectBankFromText(combinedText)
        val isIncomeNotification = isIncomeEvent(combinedText)

        if (!isIncomeNotification && BANK_PACKAGES[pkg] == null) {
            return
        }

        if (!isIncomeNotification) {
            return
        }

        // 2. Extract Income Amount
        val amount = extractIncomeAmount(combinedText)
        if (amount <= 0.0 || amount > 100000000.0) return

        // 3. Deduplicate (prevent recording same income twice within 60s)
        val now = System.currentTimeMillis()
        if (amount == lastDetectedAmount && (now - lastDetectedTime) < 60000 && combinedText == lastDetectedText) {
            return
        }

        lastDetectedAmount = amount
        lastDetectedText = combinedText
        lastDetectedTime = now

        // 4. Extract sender name or note
        val sender = extractSender(combinedText)
        val titleText = if (sender.isNotEmpty()) "รับเงินจาก $sender" else "รับเงินเข้า ($bankName)"
        val noteText = "📥 แจ้งเตือนจาก $bankName ($text)"

        // 5. Save to database in background
        CoroutineScope(Dispatchers.IO).launch {
            val saved = saveIncomeToDatabase(
                id = "tx_auto_inc_${System.currentTimeMillis()}",
                title = titleText,
                amount = amount,
                bankName = bankName,
                note = noteText
            )

            withContext(Dispatchers.Main) {
                if (saved) {
                    showInstantFeedback(titleText, amount, bankName)
                }
            }
        }
    }

    /**
     * Identifies if text is an incoming money notification
     */
    private fun isIncomeEvent(text: String): Boolean {
        val lower = text.lowercase(Locale.getDefault())

        // Explicit expense rejection keywords
        if (lower.contains("ชำระเงินสำเร็จ") || lower.contains("โอนเงินไป") || lower.contains("หักบัญชี") || lower.contains("ถอนเงิน")) {
            if (!lower.contains("เงินเข้า") && !lower.contains("รับโอน") && !lower.contains("ได้รับเงิน")) {
                return false
            }
        }

        val incomeKeywords = listOf(
            "เงินเข้า", "เงินโอนเข้า", "โอนเงินเข้า", "ยอดเงินเข้า", "ได้รับเงิน", "รับเงิน",
            "รับโอน", "เงินเข้าบัญชี", "ฝากเงิน", "เงินปันผล", "โอนให้คุณ", "incoming",
            "transfer in", "deposit", "credit", "cr", "ได้รับยอดเงิน", "เงินเข้าสำเร็จ",
            "พร้อมเพย์เงินเข้า", "รับโอนเงินสำเร็จ"
        )

        for (kw in incomeKeywords) {
            if (lower.contains(kw)) return true
        }

        // Check for "+฿" or "+ ฿" or "คุณได้รับ"
        return lower.contains("+฿") || lower.contains("คุณได้รับ")
    }

    /**
     * Extracts monetary amount from notification text
     */
    private fun extractIncomeAmount(text: String): Double {
        val clean = text.replace(",", "").replace(" ", "")

        val patterns = listOf(
            Pattern.compile("(?:เงินเข้า|รับโอน|โอนเงินเข้า|ได้รับเงิน|จำนวน|ยอดเงิน|ยอด|Amount|\\+฿|\\+)([0-9]+(?:\\.[0-9]+)?)", Pattern.CASE_INSENSITIVE),
            Pattern.compile("([0-9]+(?:\\.[0-9]+)?)\\s*(?:บาท|thb|บ\\.)", Pattern.CASE_INSENSITIVE),
            Pattern.compile("\\b([0-9]+\\.[0-9]{2})\\b")
        )

        for (p in patterns) {
            val matcher = p.matcher(clean)
            if (matcher.find()) {
                val match = matcher.group(1)
                val parsed = match?.toDoubleOrNull()
                if (parsed != null && parsed > 0.0 && parsed < 100000000.0) {
                    return parsed
                }
            }
        }

        return 0.0
    }

    private fun detectBankFromText(text: String): String {
        val lower = text.lowercase(Locale.getDefault())
        if (lower.contains("k plus") || lower.contains("kbank") || lower.contains("กสิกร")) return "กสิกรไทย (K PLUS)"
        if (lower.contains("scb") || lower.contains("ไทยพาณิชย์")) return "ไทยพาณิชย์ (SCB EASY)"
        if (lower.contains("krungthai") || lower.contains("ktb") || lower.contains("กรุงไทย")) return "กรุงไทย (Krungthai NEXT)"
        if (lower.contains("ttb") || lower.contains("ทีทีบี")) return "ttb touch"
        if (lower.contains("mymo") || lower.contains("ออมสิน")) return "MyMo (ออมสิน)"
        if (lower.contains("bualuang") || lower.contains("bbl") || lower.contains("กรุงเทพ")) return "กรุงเทพ (Bualuang)"
        if (lower.contains("kma") || lower.contains("กรุงศรี")) return "กรุงศรี (KMA)"
        if (lower.contains("truemoney") || lower.contains("ทรูมันนี่")) return "TrueMoney Wallet"
        if (lower.contains("shopeepay") || lower.contains("ช้อปปี้")) return "ShopeePay"
        if (lower.contains("พร้อมเพย์") || lower.contains("promptpay")) return "พร้อมเพย์ (PromptPay)"
        return "ธนาคารไทย"
    }

    private fun extractSender(text: String): String {
        val patterns = listOf(
            Pattern.compile("(?:จาก|โอนจาก|from|sender)[:\\s]*([ก-๙a-zA-Z\\s]{2,25})", Pattern.CASE_INSENSITIVE),
            Pattern.compile("(?:บจก\\.|บริษัท|นาย|นาง|น\\.ส\\.|ms\\.|mr\\.)[ก-๙a-zA-Z\\s]{2,25}", Pattern.CASE_INSENSITIVE)
        )

        for (p in patterns) {
            val matcher = p.matcher(text)
            if (matcher.find()) {
                val match = matcher.group(1) ?: matcher.group(0)
                if (match != null && match.trim().isNotEmpty()) {
                    return match.trim()
                }
            }
        }
        return ""
    }

    /**
     * Saves income transaction directly to SharedPreferences
     */
    private fun saveIncomeToDatabase(
        id: String,
        title: String,
        amount: Double,
        bankName: String,
        note: String
    ): Boolean {
        return try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val txKey = "flutter.rizqi_transactions_v2"
            val existingJson = prefs.getString(txKey, "[]") ?: "[]"
            val jsonArray = JSONArray(existingJson)

            val isoDateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US)
            val nowIso = isoDateFormat.format(Date())

            val newObj = JSONObject().apply {
                put("id", id)
                put("title", title)
                put("amount", amount)
                put("type", "income")
                put("date", nowIso)
                put("accountId", "acc_bank")
                put("categoryId", "cat_salary")
                put("categoryName", "เงินเดือน & รายได้ (ริซกี)")
                put("note", note)
                put("slipRefId", null)
                put("slipImageUrl", null)
                put("rawOcrText", null)
                put("taxType", "none")
                put("isTaxDeductible", false)
                put("taxDeductibleAmount", 0.0)
                put("tags", JSONArray())
            }

            val updatedArray = JSONArray()
            updatedArray.put(newObj)
            for (i in 0 until jsonArray.length()) {
                updatedArray.put(jsonArray.getJSONObject(i))
            }

            // Update account balance
            val accKey = "flutter.rizqi_accounts_v2"
            val existingAccJson = prefs.getString(accKey, "[]") ?: "[]"
            val accArray = JSONArray(existingAccJson)
            for (i in 0 until accArray.length()) {
                val acc = accArray.getJSONObject(i)
                val allowAuto = acc.optBoolean("allowAutoDeduction", true)
                if (allowAuto) {
                    val currentBal = acc.optDouble("balance", 0.0)
                    acc.put("balance", currentBal + amount)
                    break
                }
            }

            prefs.edit()
                .putString(txKey, updatedArray.toString())
                .putString(accKey, accArray.toString())
                .commit()

            // Update Home Screen Widget
            try {
                RizqiQuotaWidgetProvider.updateAllWidgetsFromStorage(this)
            } catch (e: Exception) {
                e.printStackTrace()
            }

            // Broadcast to Flutter
            try {
                val broadcastIntent = Intent("com.afitree.rizqi.RELOAD_TRANSACTIONS")
                sendBroadcast(broadcastIntent)
            } catch (e: Exception) {
                e.printStackTrace()
            }

            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    /**
     * Shows notification toast and notification bar feedback
     */
    private fun showInstantFeedback(title: String, amount: Double, bankName: String) {
        try {
            Handler(Looper.getMainLooper()).post {
                val formatted = String.format(Locale.getDefault(), "%.2f", amount)
                Toast.makeText(
                    applicationContext,
                    "✨ บันทึกริซกี: บันทึกเงินเข้า +฿$formatted จาก $bankName อัตโนมัติแล้ว!",
                    Toast.LENGTH_LONG
                ).show()
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "แจ้งเตือนเมื่อระบบดึงและบันทึกเงินเข้าให้อัตโนมัติ"
                }
                notificationManager.createNotificationChannel(channel)
            }

            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val formatted = String.format(Locale.getDefault(), "%.2f", amount)
            val catLargeIcon = android.graphics.BitmapFactory.decodeResource(resources, R.drawable.ic_notification_cat_large)
                ?: android.graphics.BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)

            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_cat)
                .setLargeIcon(catLargeIcon)
                .setColor(0xFFFF8A00.toInt())
                .setContentTitle("✨ เหมียวตังค์: เงินเข้า +฿$formatted")
                .setContentText("บันทึก \"$title\" เข้าสมุดบัญชีเรียบร้อยแล้ว")
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .build()

            notificationManager.notify(1001, notification)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
