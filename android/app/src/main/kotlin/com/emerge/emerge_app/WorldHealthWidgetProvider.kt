package com.emerge.emerge_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WorldHealthWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.world_health_widget)
            
            val healthStr = widgetData.getString("world_health_percentage", "--%") ?: "--%"
            val momentumStr = widgetData.getString("momentum_streak", "Streak: --") ?: "Streak: --"
            
            views.setTextViewText(R.id.world_health_percentage, healthStr)
            views.setTextViewText(R.id.momentum_text, momentumStr)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
