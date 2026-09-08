package com.afitree.rizqi

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.widget.RemoteViews

class RizqiVoiceWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val intent = Intent(context, VoiceRecordActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            fun buildRemoteViews(layoutId: Int): RemoteViews {
                return RemoteViews(context.packageName, layoutId).apply {
                    setOnClickPendingIntent(R.id.btn_widget_mic, pendingIntent)
                    setOnClickPendingIntent(R.id.widget_voice_container, pendingIntent)
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Responsive layout mapping for modern Android launchers (Android 12+)
                val viewMapping = mapOf(
                    SizeF(40f, 40f) to buildRemoteViews(R.layout.widget_voice_circle),      // 1x1 small (app-icon size)
                    SizeF(130f, 40f) to buildRemoteViews(R.layout.widget_voice_wide),       // Wide bar (2x1, 3x1, 4x1)
                    SizeF(110f, 110f) to buildRemoteViews(R.layout.widget_voice_expanded)   // Large box (2x2, 3x3+)
                )
                appWidgetManager.updateAppWidget(appWidgetId, RemoteViews(viewMapping))
            } else {
                // Fallback for older Android versions based on current widget options
                val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
                val minWidth = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 0
                val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 0

                val layoutId = when {
                    minWidth >= 130 && minHeight in 1..95 && minWidth > (minHeight * 1.35f) -> {
                        R.layout.widget_voice_wide
                    }
                    minWidth >= 110 && minHeight >= 110 -> {
                        R.layout.widget_voice_expanded
                    }
                    else -> {
                        R.layout.widget_voice_circle
                    }
                }
                appWidgetManager.updateAppWidget(appWidgetId, buildRemoteViews(layoutId))
            }
        }
    }
}
