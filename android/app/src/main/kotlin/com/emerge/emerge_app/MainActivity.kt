package com.emerge.emerge_app

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.activity.enableEdgeToEdge
import com.google.android.gms.ads.MobileAds
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)

        // Suppress verbose AdMob GMA Debug logs that spam the terminal.
        // The Ads SDK auto-enables verbose logging for debuggable apps.
        // We disable it here and again after initialization via MethodChannel.
        try {
            MobileAds.setVerboseLogging(false)
        } catch (_: Exception) {
            // SDK not yet initialized - will retry via MethodChannel
        }
    }
}
