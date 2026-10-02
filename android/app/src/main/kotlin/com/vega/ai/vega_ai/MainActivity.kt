package com.vega.ai.vega_ai

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.BatteryManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val AUTOMATION_CHANNEL = "com.vega.ai/automation"
    private val HARDWARE_CHANNEL = "com.vega.ai/hardware"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Safe Hardware Control Channel (Torch & Battery)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HARDWARE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "toggleTorch" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    handleToggleTorch(enabled, result)
                }
                "getBatteryLevel" -> {
                    handleGetBatteryLevel(result)
                }
                "isOfflineEngineReady" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Safe Automation Platform Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTOMATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAvailableActions" -> {
                    val actions = listOf(
                        mapOf("id" to "toggle_torch", "name" to "Flashlight Control", "category" to "deviceHardware"),
                        mapOf("id" to "get_battery_level", "name" to "Battery Diagnostics", "category" to "systemInfo")
                    )
                    result.success(actions)
                }
                "checkActionPermission" -> {
                    val actionId = call.argument<String>("actionId")
                    if (actionId == "toggle_torch") {
                        val hasFlash = packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)
                        result.success(hasFlash)
                    } else {
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleToggleTorch(enabled: Boolean, result: MethodChannel.Result) {
        // Hardware check: does device have flash?
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)) {
            result.error("UNAVAILABLE", "Flash hardware not found on this device", null)
            return
        }

        val cameraManager = getSystemService(Context.CAMERA_SERVICE) as? CameraManager
        if (cameraManager == null) {
            result.error("UNAVAILABLE", "CameraManager service not available", null)
            return
        }

        try {
            val cameraId = cameraManager.cameraIdList.firstOrNull { id ->
                val characteristics = cameraManager.getCameraCharacteristics(id)
                characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }

            if (cameraId == null) {
                result.error("UNAVAILABLE", "No camera with flash unit available", null)
                return
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                cameraManager.setTorchMode(cameraId, enabled)
                result.success(true)
            } else {
                result.error("UNSUPPORTED", "Torch mode requires Android 6.0 (API 23)+", null)
            }
        } catch (e: CameraAccessException) {
            result.error("CAMERA_ERROR", "Camera access exception: ${e.message}", null)
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", "Camera access denied by security policy: ${e.message}", null)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to toggle flashlight: ${e.message}", null)
        }
    }

    private fun handleGetBatteryLevel(result: MethodChannel.Result) {
        try {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
            val level = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && batteryManager != null) {
                batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            } else {
                val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                val rawLevel = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
                val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
                if (rawLevel >= 0 && scale > 0) {
                    (rawLevel * 100) / scale
                } else {
                    -1
                }
            }

            if (level in 0..100) {
                result.success(level)
            } else {
                result.error("UNAVAILABLE", "Battery level could not be determined", null)
            }
        } catch (e: Exception) {
            result.error("ERROR", "Failed to read battery status: ${e.message}", null)
        }
    }
}
