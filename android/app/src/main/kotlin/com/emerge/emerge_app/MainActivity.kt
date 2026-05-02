package com.emerge.emerge_app

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import androidx.activity.enableEdgeToEdge

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
