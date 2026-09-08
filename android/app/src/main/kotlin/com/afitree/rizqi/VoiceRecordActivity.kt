package com.afitree.rizqi

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.MotionEvent
import android.view.View
import android.animation.ValueAnimator
import android.view.animation.Animation
import android.view.animation.ScaleAnimation
import android.widget.Button
import android.widget.FrameLayout
import android.widget.TextView
import android.widget.Toast
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class VoiceRecordActivity : Activity() {

    private val RECORD_AUDIO_REQUEST = 3001
    private var speechRecognizer: SpeechRecognizer? = null
    private lateinit var tvStatus: TextView
    private lateinit var tvSpokenText: TextView
    private lateinit var micPulseContainer: FrameLayout
    private lateinit var btnCancel: Button
    private lateinit var pulseAnimation: ScaleAnimation
    private lateinit var waveBars: List<View>
    private var waveAnimator: ValueAnimator? = null
    private var isRecording = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.dialog_voice_record)

        tvStatus = findViewById(R.id.tv_voice_status)
        tvSpokenText = findViewById(R.id.tv_recognized_text)
        micPulseContainer = findViewById(R.id.mic_pulse_container)
        btnCancel = findViewById(R.id.btn_cancel_voice)

        waveBars = listOf(
            findViewById(R.id.wave_bar_1),
            findViewById(R.id.wave_bar_2),
            findViewById(R.id.wave_bar_3),
            findViewById(R.id.wave_bar_4),
            findViewById(R.id.wave_bar_5),
            findViewById(R.id.wave_bar_6),
            findViewById(R.id.wave_bar_7)
        )

        setupPulseAnimation()

        btnCancel.setOnClickListener {
            stopAndClose()
        }

        micPulseContainer.setOnClickListener {
            if (!isRecording) {
                checkPermissionAndStartSpeech()
            }
        }

        checkPermissionAndStartSpeech()
    }

    private fun setupPulseAnimation() {
        pulseAnimation = ScaleAnimation(
            1.0f, 1.25f, 1.0f, 1.25f,
            Animation.RELATIVE_TO_SELF, 0.5f,
            Animation.RELATIVE_TO_SELF, 0.5f
        ).apply {
            duration = 800
            repeatCount = Animation.INFINITE
            repeatMode = Animation.REVERSE
        }
    }

    private fun startWaveAnimation() {
        waveAnimator?.cancel()
        waveAnimator = ValueAnimator.ofFloat(0.3f, 1.2f).apply {
            duration = 500
            repeatMode = ValueAnimator.REVERSE
            repeatCount = ValueAnimator.INFINITE
            addUpdateListener { anim ->
                val factor = anim.animatedValue as Float
                waveBars.forEachIndexed { index, bar ->
                    val waveOffset = kotlin.math.sin((factor * Math.PI) + (index * 0.6f)).toFloat()
                    val scale = (0.5f + (waveOffset * 0.5f)).coerceIn(0.25f, 1.4f)
                    bar.scaleY = scale
                }
            }
            start()
        }
    }

    private fun updateWaveByRms(rmsdB: Float) {
        val normalized = ((rmsdB.coerceIn(-2f, 10f) + 2f) / 12f).coerceIn(0.15f, 1.0f)
        val multipliers = listOf(0.4f, 0.7f, 1.1f, 1.4f, 1.1f, 0.7f, 0.4f)
        waveBars.forEachIndexed { index, bar ->
            val scale = (normalized * multipliers.getOrElse(index) { 1.0f } + 0.35f).coerceIn(0.25f, 1.8f)
            bar.animate()
                .scaleY(scale)
                .setDuration(70)
                .start()
        }
    }

    private fun stopWaveAnimation() {
        waveAnimator?.cancel()
        waveAnimator = null
        waveBars.forEach { bar ->
            bar.animate().scaleY(1.0f).setDuration(120).start()
        }
    }

    private fun checkPermissionAndStartSpeech() {
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(
                arrayOf(Manifest.permission.RECORD_AUDIO),
                RECORD_AUDIO_REQUEST
            )
        } else {
            initAndStartSpeechRecognizer()
        }
    }

    private fun initAndStartSpeechRecognizer() {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            Toast.makeText(this, "อุปกรณ์นี้ไม่รองรับระบบฟังเสียงของ Google", Toast.LENGTH_LONG).show()
            finish()
            return
        }

        speechRecognizer?.destroy()
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)

        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                isRecording = true
                tvStatus.text = "🎙️ กำลังฟังเสียง... พูดได้เลยค่ะ"
                micPulseContainer.startAnimation(pulseAnimation)
                startWaveAnimation()
            }

            override fun onBeginningOfSpeech() {
                tvStatus.text = "🎙️ กำลังฟังเสียง... พูดได้เลยค่ะ"
            }

            override fun onRmsChanged(rmsdB: Float) {
                if (isRecording) {
                    updateWaveByRms(rmsdB)
                }
            }

            override fun onBufferReceived(buffer: ByteArray?) {}

            override fun onEndOfSpeech() {
                tvStatus.text = "✨ กำลังประมวลผล..."
                micPulseContainer.clearAnimation()
                stopWaveAnimation()
            }

            override fun onError(error: Int) {
                isRecording = false
                micPulseContainer.clearAnimation()
                stopWaveAnimation()
                val errMsg = when (error) {
                    SpeechRecognizer.ERROR_NO_MATCH -> "ไม่ได้ยินเสียงชัดเจน กรุณาลองใหม่อีกครั้ง"
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "หมดเวลาการฟัง กรุณาลองใหม่"
                    SpeechRecognizer.ERROR_AUDIO -> "เกิดข้อผิดพลาดของไมโครโฟน"
                    SpeechRecognizer.ERROR_NETWORK -> "ไม่มีการเชื่อมต่อเครือข่าย"
                    else -> "เกิดข้อผิดพลาดในการฟังเสียง ($error)"
                }
                tvStatus.text = errMsg
                Handler(Looper.getMainLooper()).postDelayed({
                    stopAndClose()
                }, 1500)
            }

            override fun onResults(results: Bundle?) {
                isRecording = false
                micPulseContainer.clearAnimation()
                stopWaveAnimation()

                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty()) {
                    val spokenText = matches[0]
                    tvSpokenText.text = "\"$spokenText\""
                    tvStatus.text = "✨ กำลังบันทึกข้อมูล..."

                    processAndSaveSpokenTransactionAsync(spokenText)
                } else {
                    tvStatus.text = "ไม่พบข้อความเสียง"
                    Handler(Looper.getMainLooper()).postDelayed({
                        stopAndClose()
                    }, 1000)
                }
            }

            override fun onPartialResults(partialResults: Bundle?) {
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty()) {
                    tvSpokenText.text = "\"${matches[0]}\""
                }
            }

            override fun onEvent(eventType: Int, params: Bundle?) {}
        })

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "th-TH")
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, "th-TH")
            putExtra(RecognizerIntent.EXTRA_ONLY_RETURN_LANGUAGE_PREFERENCE, "th-TH")
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_PROMPT, "พูดบันทึกรายรับ-รายจ่าย (เช่น กินข้าว 60 บาท)")
        }

        speechRecognizer?.startListening(intent)
    }

    /**
     * Converts spoken Thai number words to numeric representation
     */
    private fun normalizeThaiSpokenText(input: String): String {
        var text = input
        val thaiNumberMap = listOf(
            "หนึ่งหมื่น" to "10000", "สองหมื่น" to "20000", "สามหมื่น" to "30000", "สี่หมื่น" to "40000", "ห้าหมื่น" to "50000",
            "หนึ่งพัน" to "1000", "สองพัน" to "2000", "สามพัน" to "3000", "สี่พัน" to "4000", "ห้าพัน" to "5000", "พัน" to "1000",
            "หนึ่งร้อย" to "100", "สองร้อย" to "200", "สามร้อย" to "300", "สี่ร้อย" to "400", "ห้าร้อย" to "500",
            "หกร้อย" to "600", "เจ็ดร้อย" to "700", "แปดร้อย" to "800", "เก้าร้อย" to "900", "ร้อย" to "100",
            "เก้าสิบ" to "90", "แปดสิบ" to "80", "เจ็ดสิบ" to "70", "หกสิบ" to "60", "ห้าสิบ" to "50",
            "สี่สิบ" to "40", "สามสิบ" to "30", "ยี่สิบ" to "20", "สิบ" to "10",
            "เก้า" to "9", "แปด" to "8", "เจ็ด" to "7", "หก" to "6", "ห้า" to "5",
            "สี่" to "4", "สาม" to "3", "สอง" to "2", "หนึ่ง" to "1", "ศูนย์" to "0"
        )
        for ((word, num) in thaiNumberMap) {
            text = text.replace(word, " $num ")
        }
        return text.replace(Regex("""\s+"""), " ").trim()
    }

    /**
     * Extracts number as amount and remaining text as category/note,
     * and saves to database strictly on a Background Thread (CoroutineScope Dispatchers.IO).
     */
    private fun processAndSaveSpokenTransactionAsync(spokenText: String) {
        val clean = spokenText.trim()
        val normalized = normalizeThaiSpokenText(clean)
        val lower = clean.lowercase(Locale.getDefault())

        // 1. Amount Extraction via RegEx
        var amount = 0.0
        var matchedNumberStr = ""

        val amountRegexes = listOf(
            Regex("""([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)\s*(?:บาท|บ\.|thb)""", RegexOption.IGNORE_CASE),
            Regex("""(?:จำนวนเงิน|ยอดเงิน|เป็นเงิน|ราคา|จ่าย|ได้|ยอด)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)""", RegexOption.IGNORE_CASE),
            Regex("""\b([0-9]{1,6}(?:\.[0-9]{1,2})?)\b""")
        )

        for (reg in amountRegexes) {
            val match = reg.find(normalized) ?: reg.find(clean)
            if (match != null && match.groupValues.size > 1) {
                matchedNumberStr = match.groupValues[1]
                val amtClean = matchedNumberStr.replace(",", "")
                val parsed = amtClean.toDoubleOrNull()
                if (parsed != null && parsed > 0) {
                    amount = parsed
                    break
                }
            }
        }

        // 2. Extract Category / Memo from remaining text by stripping number and currency keywords
        var remainingNote = clean
        if (matchedNumberStr.isNotEmpty()) {
            remainingNote = remainingNote.replace(matchedNumberStr, "")
        }
        remainingNote = remainingNote
            .replace(Regex("""(?:บาท|บ\.|thb|จำนวนเงิน|ยอดเงิน|ราคา|จ่าย|ได้)""", RegexOption.IGNORE_CASE), "")
            .replace(Regex("""\s+"""), " ")
            .trim()

        if (remainingNote.isEmpty()) {
            remainingNote = "บันทึกเสียง"
        }

        // 3. Type & Category Detection
        var isIncome = false
        val incomeKeywords = listOf("ได้เงิน", "เงินเข้า", "รับเงิน", "ค่าคอม", "คอมมิชชั่น", "เงินเดือน", "โบนัส", "ขายได้", "ยอดขาย", "ริซกี")
        if (incomeKeywords.any { lower.contains(it) }) {
            isIncome = true
        }

        var catId = if (isIncome) "cat_salary" else "cat_food"
        var catName = if (isIncome) "เงินเดือน & ค่าจ้าง" else "อาหาร & เครื่องดื่ม"

        if (!isIncome) {
            if (lower.contains("น้ำมัน") || lower.contains("เดินทาง") || lower.contains("รถ") || lower.contains("bts") || lower.contains("mrt") || lower.contains("วิน") || lower.contains("แท็กซี่") || lower.contains("grab")) {
                catId = "cat_transport"
                catName = "เดินทาง & น้ำมัน"
            } else if (lower.contains("ช้อป") || lower.contains("เสื้อ") || lower.contains("ของใช้") || lower.contains("lazada") || lower.contains("shopee") || lower.contains("เซเว่น") || lower.contains("7-11")) {
                catId = "cat_shopping"
                catName = "ช้อปปิ้ง & ของใช้"
            } else if (lower.contains("ค่าไฟ") || lower.contains("ค่าน้ำ") || lower.contains("ค่าเน็ต") || lower.contains("ค่าโทร") || lower.contains("ค่าห้อง") || lower.contains("ค่าบ้าน") || lower.contains("บิล")) {
                catId = "cat_bills"
                catName = "บิลค่าน้ำค่าไฟ & ค่าเน็ต"
            } else if (lower.contains("ยา") || lower.contains("หมอ") || lower.contains("ฟัน") || lower.contains("คลินิก") || lower.contains("โรงพยาบาล")) {
                catId = "cat_health"
                catName = "สุขภาพ & ยา"
            } else if (lower.contains("บริจาค") || lower.contains("ซะกาต") || lower.contains("ทำบุญ") || lower.contains("มัสยิด") || lower.contains("ศอดะเกาะฮ์")) {
                catId = "cat_charity"
                catName = "บริจาค & ทำบุญ (เศาะดะเกาะฮ์)"
            }
        }

        val typeStr = if (isIncome) "income" else "expense"
        val titleStr = if (remainingNote.length in 1..25) remainingNote else catName

        // 4. Save to Database strictly on Background Thread (Dispatchers.IO)
        CoroutineScope(Dispatchers.IO).launch {
            val success = saveTransactionToDatabaseBackground(
                id = "tx_voice_${System.currentTimeMillis()}",
                title = titleStr,
                amount = amount,
                type = typeStr,
                categoryId = catId,
                categoryName = catName,
                note = "🎙️ $clean"
            )

            withContext(Dispatchers.Main) {
                if (success) {
                    val formattedAmt = String.format(Locale.getDefault(), "%.2f", amount)
                    Toast.makeText(this@VoiceRecordActivity, "✨ บันทึก \"$titleStr\" ฿$formattedAmt เรียบร้อยแล้ว!", Toast.LENGTH_LONG).show()
                } else {
                    Toast.makeText(this@VoiceRecordActivity, "บันทึกข้อมูลเรียบร้อยแล้ว", Toast.LENGTH_SHORT).show()
                }

                Handler(Looper.getMainLooper()).postDelayed({
                    stopAndClose()
                }, 500)
            }
        }
    }

    /**
     * Executes database operations on Background Thread
     */
    private fun saveTransactionToDatabaseBackground(
        id: String,
        title: String,
        amount: Double,
        type: String,
        categoryId: String,
        categoryName: String,
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
                put("type", type)
                put("date", nowIso)
                put("accountId", "acc_cash")
                put("categoryId", categoryId)
                put("categoryName", categoryName)
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

            // Also update account balance in storage
            val accKey = "flutter.rizqi_accounts_v2"
            val existingAccJson = prefs.getString(accKey, "[]") ?: "[]"
            val accArray = JSONArray(existingAccJson)
            for (i in 0 until accArray.length()) {
                val acc = accArray.getJSONObject(i)
                if (acc.optString("id") == "acc_cash" || (i == 0 && accArray.length() == 1)) {
                    val currentBal = acc.optDouble("balance", 0.0)
                    val newBal = if (type == "income") currentBal + amount else currentBal - amount
                    acc.put("balance", newBal)
                    break
                }
            }

            prefs.edit()
                .putString(txKey, updatedArray.toString())
                .putString(accKey, accArray.toString())
                .commit()

            // 1. Immediately update Home Screen Widget
            try {
                RizqiQuotaWidgetProvider.updateAllWidgetsFromStorage(this@VoiceRecordActivity)
            } catch (e: Exception) {
                e.printStackTrace()
            }

            // 2. Broadcast to Flutter if running in memory
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

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == RECORD_AUDIO_REQUEST) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                initAndStartSpeechRecognizer()
            } else {
                Toast.makeText(this, "จำเป็นต้องอนุญาตการใช้ไมโครโฟนเพื่อพูดบันทึก", Toast.LENGTH_SHORT).show()
                stopAndClose()
            }
        }
    }

    override fun onTouchEvent(event: MotionEvent?): Boolean {
        if (event?.action == MotionEvent.ACTION_DOWN) {
            stopAndClose()
            return true
        }
        return super.onTouchEvent(event)
    }

    private fun stopAndClose() {
        stopWaveAnimation()
        try {
            speechRecognizer?.stopListening()
            speechRecognizer?.destroy()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        speechRecognizer = null
        finish()
    }

    override fun onDestroy() {
        stopAndClose()
        super.onDestroy()
    }
}
