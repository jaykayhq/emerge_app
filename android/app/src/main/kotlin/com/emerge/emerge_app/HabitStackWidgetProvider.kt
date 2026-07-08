package com.emerge.emerge_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class HabitStackWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.habit_stack_widget)
            
            val habitsJson = widgetData.getString("top_habits", "[]") ?: "[]"
            try {
                val habits = JSONArray(habitsJson)
                
                // Reset visibility
                views.setViewVisibility(R.id.habit_1, android.view.View.GONE)
                views.setViewVisibility(R.id.habit_2, android.view.View.GONE)
                views.setViewVisibility(R.id.habit_3, android.view.View.GONE)

                if (habits.length() > 0) {
                    views.setTextViewText(R.id.habit_1, habits.getString(0))
                    views.setViewVisibility(R.id.habit_1, android.view.View.VISIBLE)
                }
                if (habits.length() > 1) {
                    views.setTextViewText(R.id.habit_2, habits.getString(1))
                    views.setViewVisibility(R.id.habit_2, android.view.View.VISIBLE)
                }
                if (habits.length() > 2) {
                    views.setTextViewText(R.id.habit_3, habits.getString(2))
                    views.setViewVisibility(R.id.habit_3, android.view.View.VISIBLE)
                }
                if (habits.length() == 0) {
                    views.setTextViewText(R.id.habit_1, "All habits complete!")
                    views.setViewVisibility(R.id.habit_1, android.view.View.VISIBLE)
                }
            } catch (e: Exception) {
                views.setTextViewText(R.id.habit_1, "Error loading habits")
                views.setViewVisibility(R.id.habit_1, android.view.View.VISIBLE)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
