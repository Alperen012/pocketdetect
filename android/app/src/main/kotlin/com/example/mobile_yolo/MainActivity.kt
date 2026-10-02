package com.example.mobile_yolo

import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "mobile_yolo/device"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"isLowRamDevice" -> {
						val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
						result.success(manager.isLowRamDevice)
					}
					else -> result.notImplemented()
				}
			}
	}
}
