package com.vega.ai.vega_ai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val AUTOMATION_CHANNEL = "com.vega.ai/automation"
    private val HARDWARE_CHANNEL = "com.vega.ai/hardware"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Safe Automation Platform Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTOMATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAvailableActions" -> {
                    // Returns list of approved Android actions safe to execute
                    val actions = listOf(
                        mapOf("id" to "phone_torch", "name" to "Flashlight", "category" to "device"),
                        mapOf("id" to "phone_volume", "name" to "Set Volume", "category" to "audio"),
                        mapOf("id" to "launch_app", "name" to "Launch App", "category" to "system")
                    )
                    result.success(actions)
                }
                "checkActionPermission" -> {
                    val actionId = call.argument<String>("actionId")
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Hardware Controls Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HARDWARE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isOfflineEngineReady" -> result.success(true)
                else -> result.notImplemented()
            }
        }
    }
}
