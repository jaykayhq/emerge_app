package com.emerge.emerge_app

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ScreenTimePlugin(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        private const val CHANNEL = "com.emerge.emerge_app/screen_time"
        fun registerWith(engine: FlutterEngine, context: Context) {
            val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            channel.setMethodCallHandler(ScreenTimePlugin(context))
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestUsageStatsPermission" -> {
                if (!isUsageStatsPermissionGranted()) {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    context.startActivity(intent)
                }
                result.success(isUsageStatsPermissionGranted())
            }
            "getTodayScreenTime" -> result.success(getTodayScreenTimeMinutes())
            "isUsageStatsPermissionGranted" -> result.success(isUsageStatsPermissionGranted())
            else -> result.notImplemented()
        }
    }

    private fun isUsageStatsPermissionGranted(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return false
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.unsafeCheckOp(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getTodayScreenTimeMinutes(): Int {
        if (!isUsageStatsPermissionGranted()) return 0
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return 0
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE)
                as android.app.usage.UsageStatsManager
        val calendar = java.util.Calendar.getInstance()
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar.set(java.util.Calendar.MINUTE, 0)
        calendar.set(java.util.Calendar.SECOND, 0)
        calendar.set(java.util.Calendar.MILLISECOND, 0)
        val startOfDay = calendar.timeInMillis
        val endOfDay = System.currentTimeMillis()
        val stats = usageStatsManager.queryUsageStats(
            android.app.usage.UsageStatsManager.INTERVAL_DAILY, startOfDay, endOfDay
        )
        var totalMillis = 0L
        stats?.forEach { totalMillis += it.totalTimeInForeground }
        return (totalMillis / 60000).toInt()
    }
}
