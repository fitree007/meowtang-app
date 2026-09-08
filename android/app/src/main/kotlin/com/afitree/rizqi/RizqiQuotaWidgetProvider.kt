package com.afitree.rizqi

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import java.text.DecimalFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class RizqiQuotaWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "com.afitree.rizqi.UPDATE_QUOTA_WIDGET" ||
            intent.action == "com.afitree.rizqi.RELOAD_TRANSACTIONS" ||
            intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, RizqiQuotaWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private val formatter = DecimalFormat("#,##0")

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val (todayIncome, todayExpense, todayNet) = calculateTodayStats(context)

            val views = RemoteViews(context.packageName, R.layout.widget_quota_balance)

            // Format numbers for Today's Income and Today's Expense
            views.setTextViewText(R.id.tv_today_income, "+฿ ${formatter.format(todayIncome)}")
            views.setTextViewText(R.id.tv_today_expense, "-฿ ${formatter.format(todayExpense)}")

            // Date Badge (e.g. "วันนี้ 31 ส.ค.")
            try {
                val thaiDateFormat = SimpleDateFormat("d MMM", Locale("th", "TH"))
                views.setTextViewText(R.id.tv_widget_badge, "วันนี้ ${thaiDateFormat.format(Date())}")
            } catch (_: Exception) {
                views.setTextViewText(R.id.tv_widget_badge, "วันนี้")
            }

            // 1. Root tap -> Open Main App
            val mainIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val mainPendingIntent = PendingIntent.getActivity(
                context, 101, mainIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, mainPendingIntent)

            // 2. Add Button -> Open Main App to add transaction
            val addIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                action = "com.afitree.rizqi.ACTION_QUICK_ADD"
            }
            val addPendingIntent = PendingIntent.getActivity(
                context, 102, addIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_widget_add, addPendingIntent)

            // 3. Voice Button -> Open Transparent Voice Recorder
            val voiceIntent = Intent(context, VoiceRecordActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val voicePendingIntent = PendingIntent.getActivity(
                context, 103, voiceIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_widget_voice, voicePendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun calculateTodayStats(context: Context): Triple<Double, Double, Double> {
            var todayIncome = 0.0
            var todayExpense = 0.0
            var hasCalculated = false

            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

                // 1. Try reading direct cached stats from Flutter updateWidgets method channel first
                if (prefs.contains("widget_today_income") || prefs.contains("widget_today_expense")) {
                    todayIncome = prefs.getFloat("widget_today_income", 0f).toDouble()
                    todayExpense = prefs.getFloat("widget_today_expense", 0f).toDouble()
                    hasCalculated = true
                }

                // 2. Compute from persistent JSON storage if not cached or to verify
                val todayFormats = listOf(
                    SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date()),
                    SimpleDateFormat("yyyy/MM/dd", Locale.US).format(Date()),
                    SimpleDateFormat("dd/MM/yyyy", Locale.US).format(Date())
                )

                val keys = listOf("flutter.rizqi_transactions_v2", "rizqi_transactions_v2")
                var computedIncome = 0.0
                var computedExpense = 0.0
                var foundAny = false

                for (k in keys) {
                    val jsonStr = prefs.getString(k, null)
                    if (!jsonStr.isNullOrEmpty() && jsonStr != "[]") {
                        val jsonArray = JSONArray(jsonStr)
                        for (i in 0 until jsonArray.length()) {
                            val obj = jsonArray.getJSONObject(i)
                            val dateStr = obj.optString("date", "")
                            val matchesToday = todayFormats.any { dateStr.contains(it) || dateStr.startsWith(it) }
                            if (matchesToday) {
                                foundAny = true
                                val type = obj.optString("type", "expense").lowercase()
                                val amount = obj.optDouble("amount", 0.0)
                                if (type == "income") {
                                    computedIncome += amount
                                } else if (type == "expense") {
                                    computedExpense += amount
                                }
                            }
                        }
                        if (foundAny) break
                    }
                }

                if (foundAny) {
                    todayIncome = computedIncome
                    todayExpense = computedExpense
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            val todayNet = todayIncome - todayExpense
            return Triple(todayIncome, todayExpense, todayNet)
        }

        fun updateAllWidgets(
            context: Context,
            todayIncome: Double,
            todayExpense: Double,
            todayNet: Double,
            dailyQuota: Double,
            monthlyExpense: Double
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putFloat("widget_today_income", todayIncome.toFloat())
                .putFloat("widget_today_expense", todayExpense.toFloat())
                .putFloat("widget_today_net", todayNet.toFloat())
                .putFloat("widget_daily_quota", dailyQuota.toFloat())
                .putFloat("widget_monthly_expense", monthlyExpense.toFloat())
                .apply()

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, RizqiQuotaWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }

        fun updateAllWidgetsFromStorage(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, RizqiQuotaWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }
}
