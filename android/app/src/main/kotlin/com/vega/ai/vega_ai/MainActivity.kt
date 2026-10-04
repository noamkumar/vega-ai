package com.vega.ai.vega_ai

import android.app.SearchManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.AlarmClock
import android.provider.MediaStore
import android.provider.Settings
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val AUTOMATION_CHANNEL = "com.vega.ai/automation"
    private val HARDWARE_CHANNEL = "com.vega.ai/hardware"
    private val SPEECH_CHANNEL = "com.vega.ai/speech"
    private val TTS_CHANNEL = "com.vega.ai/tts"

    private var speechChannel: MethodChannel? = null
    private var ttsChannel: MethodChannel? = null
    private var textToSpeech: TextToSpeech? = null
    private var isTtsInitialized = false
    private var speechRecognizer: SpeechRecognizer? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize Android Text-to-Speech
        textToSpeech = TextToSpeech(applicationContext, this)

        // Hardware Channel
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
                    val modelPath = call.argument<String>("modelPath")
                    if (modelPath != null) {
                        val file = File(modelPath)
                        result.success(file.exists() && file.length() > 1024 * 1024)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Automation Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTOMATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAvailableActions" -> {
                    handleGetAvailableActions(result)
                }
                "checkActionPermission" -> {
                    val actionId = call.argument<String>("actionId")
                    handleCheckPermission(actionId, result)
                }
                "getInstalledApps" -> {
                    handleGetInstalledApps(result)
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    val appName = call.argument<String>("appName")
                    handleLaunchApp(packageName, appName, result)
                }
                "openCamera" -> {
                    handleOpenCamera(result)
                }
                "openSettings" -> {
                    val type = call.argument<String>("type") ?: "general"
                    handleOpenSettings(type, result)
                }
                "setVolume" -> {
                    val mode = call.argument<String>("mode") ?: "increase"
                    val level = call.argument<Int>("level")
                    handleSetVolume(mode, level, result)
                }
                "getVolume" -> {
                    handleGetVolume(result)
                }
                "controlMedia" -> {
                    val action = call.argument<String>("action") ?: "play_pause"
                    handleControlMedia(action, result)
                }
                "playMusic" -> {
                    val query = call.argument<String>("query")
                    val app = call.argument<String>("app")
                    handlePlayMusic(query, app, result)
                }
                "setTimer" -> {
                    val seconds = call.argument<Int>("seconds") ?: 60
                    val message = call.argument<String>("message") ?: "VEGA Timer"
                    handleSetTimer(seconds, message, result)
                }
                "setAlarm" -> {
                    val hour = call.argument<Int>("hour") ?: 7
                    val minute = call.argument<Int>("minute") ?: 0
                    val message = call.argument<String>("message") ?: "VEGA Alarm"
                    handleSetAlarm(hour, minute, message, result)
                }
                else -> result.notImplemented()
            }
        }

        // Native Speech Recognition Channel
        speechChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SPEECH_CHANNEL)
        speechChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    handleStartSpeechRecognition(result)
                }
                "stopListening" -> {
                    handleStopSpeechRecognition(result)
                }
                else -> result.notImplemented()
            }
        }

        // Native Text-to-Speech Channel
        ttsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TTS_CHANNEL)
        ttsChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text") ?: ""
                    handleSpeak(text, result)
                }
                "stop" -> {
                    handleStopTts(result)
                }
                "setVoiceParameters" -> {
                    val pitch = call.argument<Double>("pitch")?.toFloat() ?: 1.0f
                    val rate = call.argument<Double>("rate")?.toFloat() ?: 1.0f
                    textToSpeech?.setPitch(pitch)
                    textToSpeech?.setSpeechRate(rate)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // --- HARDWARE HANDLERS ---

    private fun handleToggleTorch(enabled: Boolean, result: MethodChannel.Result) {
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

    // --- AUTOMATION HANDLERS ---

    private fun handleGetAvailableActions(result: MethodChannel.Result) {
        val actions = listOf(
            mapOf("id" to "toggle_torch", "name" to "Flashlight Control", "category" to "deviceHardware"),
            mapOf("id" to "get_battery_level", "name" to "Battery Diagnostics", "category" to "systemInfo"),
            mapOf("id" to "launch_app", "name" to "Launch Application", "category" to "appShortcuts"),
            mapOf("id" to "open_camera", "name" to "Camera Launch", "category" to "deviceHardware"),
            mapOf("id" to "open_settings", "name" to "System Settings", "category" to "systemInfo"),
            mapOf("id" to "set_volume", "name" to "Volume Adjustment", "category" to "mediaAudio"),
            mapOf("id" to "get_volume", "name" to "Volume Diagnostics", "category" to "systemInfo"),
            mapOf("id" to "play_music", "name" to "Music Playback", "category" to "mediaAudio"),
            mapOf("id" to "control_media", "name" to "Media Control", "category" to "mediaAudio"),
            mapOf("id" to "set_timer", "name" to "Countdown Timer", "category" to "systemInfo"),
            mapOf("id" to "set_alarm", "name" to "Clock Alarm", "category" to "systemInfo")
        )
        result.success(actions)
    }

    private fun handleCheckPermission(actionId: String?, result: MethodChannel.Result) {
        when (actionId) {
            "toggle_torch" -> {
                val hasFlash = packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)
                result.success(hasFlash)
            }
            "open_camera" -> {
                val hasCam = packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
                result.success(hasCam)
            }
            else -> result.success(true)
        }
    }

    private fun handleGetInstalledApps(result: MethodChannel.Result) {
        try {
            val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            val activities = packageManager.queryIntentActivities(mainIntent, 0)
            val apps = activities.mapNotNull { resolveInfo ->
                val pkg = resolveInfo.activityInfo?.packageName
                val label = resolveInfo.loadLabel(packageManager)?.toString()
                if (pkg != null && label != null) {
                    mapOf("appName" to label, "packageName" to pkg)
                } else null
            }
            result.success(apps)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to retrieve installed apps: ${e.message}", null)
        }
    }

    private fun handleLaunchApp(packageName: String?, appName: String?, result: MethodChannel.Result) {
        try {
            var launchIntent: Intent? = null
            if (!packageName.isNullOrBlank()) {
                launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            }

            if (launchIntent == null && !appName.isNullOrBlank()) {
                val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
                    addCategory(Intent.CATEGORY_LAUNCHER)
                }
                val activities = packageManager.queryIntentActivities(mainIntent, 0)
                val target = activities.firstOrNull {
                    val label = it.loadLabel(packageManager)?.toString() ?: ""
                    label.equals(appName, ignoreCase = true) || label.contains(appName, ignoreCase = true)
                }
                if (target != null) {
                    launchIntent = packageManager.getLaunchIntentForPackage(target.activityInfo.packageName)
                }
            }

            // Common aliases
            if (launchIntent == null && !appName.isNullOrBlank()) {
                val lower = appName.lowercase()
                val targetPkg = when {
                    lower.contains("spotify") -> "com.spotify.music"
                    lower.contains("youtube music") -> "com.google.android.apps.youtube.music"
                    lower.contains("youtube") -> "com.google.android.youtube"
                    lower.contains("chrome") -> "com.android.chrome"
                    lower.contains("whatsapp") -> "com.whatsapp"
                    lower.contains("instagram") -> "com.instagram.android"
                    lower.contains("telegram") -> "org.telegram.messenger"
                    lower.contains("facebook") || lower.contains("fb") -> "com.facebook.katana"
                    lower.contains("twitter") || lower.contains(" x ") || lower == "x" -> "com.twitter.android"
                    lower.contains("snapchat") -> "com.snapchat.android"
                    lower.contains("netflix") -> "com.netflix.mediaclient"
                    lower.contains("amazon") || lower.contains("shopping") -> "com.amazon.mShop.android.shopping"
                    lower.contains("maps") || lower.contains("navigation") -> "com.google.android.apps.maps"
                    lower.contains("gmail") || lower.contains("email") || lower.contains("mail") -> "com.google.android.gm"
                    lower.contains("files") || lower.contains("file manager") -> "com.google.android.documentsui"
                    lower.contains("calculator") || lower.contains("calc") -> "com.google.android.calculator"
                    lower.contains("clock") || lower.contains("alarm") -> "com.google.android.deskclock"
                    lower.contains("notes") || lower.contains("keep") -> "com.google.android.keep"
                    lower.contains("gallery") || lower.contains("photos") -> "com.google.android.apps.photos"
                    lower.contains("contacts") -> "com.google.android.contacts"
                    lower.contains("phone") || lower.contains("dialer") || lower.contains("call") -> "com.google.android.dialer"
                    lower.contains("messages") || lower.contains("sms") || lower.contains("text") -> "com.google.android.apps.messaging"
                    lower.contains("camera") -> "com.google.android.GoogleCamera"
                    lower.contains("settings") -> "com.android.settings"
                    lower.contains("play store") || lower.contains("app store") -> "com.android.vending"
                    lower.contains("calendar") -> "com.google.android.calendar"
                    lower.contains("drive") -> "com.google.android.apps.docs"
                    lower.contains("music") -> "com.google.android.music"
                    else -> null
                }
                if (targetPkg != null) {
                    launchIntent = packageManager.getLaunchIntentForPackage(targetPkg)
                }
            }

            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(launchIntent)
                result.success(true)
            } else {
                result.error("APP_NOT_FOUND", "Application ${appName ?: packageName} not installed on device", null)
            }
        } catch (e: Exception) {
            result.error("ERROR", "Failed to launch application: ${e.message}", null)
        }
    }

    private fun handleOpenCamera(result: MethodChannel.Result) {
        try {
            val cameraIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (cameraIntent.resolveActivity(packageManager) != null) {
                startActivity(cameraIntent)
                result.success(true)
            } else {
                val fallbackIntent = packageManager.getLaunchIntentForPackage("com.google.android.GoogleCamera")
                    ?: packageManager.getLaunchIntentForPackage("com.android.camera")
                if (fallbackIntent != null) {
                    fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(fallbackIntent)
                    result.success(true)
                } else {
                    result.error("UNAVAILABLE", "Camera app not found", null)
                }
            }
        } catch (e: Exception) {
            result.error("ERROR", "Failed to open camera: ${e.message}", null)
        }
    }

    private fun handleOpenSettings(type: String, result: MethodChannel.Result) {
        try {
            val action = when (type.lowercase()) {
                "wifi" -> Settings.ACTION_WIFI_SETTINGS
                "bluetooth" -> Settings.ACTION_BLUETOOTH_SETTINGS
                "sound", "volume" -> Settings.ACTION_SOUND_SETTINGS
                "display" -> Settings.ACTION_DISPLAY_SETTINGS
                "battery" -> Settings.ACTION_BATTERY_SAVER_SETTINGS
                else -> Settings.ACTION_SETTINGS
            }
            val intent = Intent(action).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to open settings: ${e.message}", null)
        }
    }

    private fun handleSetVolume(mode: String, level: Int?, result: MethodChannel.Result) {
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            if (audioManager == null) {
                result.error("UNAVAILABLE", "AudioManager not available", null)
                return
            }

            if (level != null) {
                audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, level, AudioManager.FLAG_SHOW_UI)
                result.success(true)
            } else {
                val direction = when (mode.lowercase()) {
                    "increase", "up" -> AudioManager.ADJUST_RAISE
                    "decrease", "down" -> AudioManager.ADJUST_LOWER
                    "mute" -> AudioManager.ADJUST_MUTE
                    "unmute" -> AudioManager.ADJUST_UNMUTE
                    else -> AudioManager.ADJUST_SAME
                }
                audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, direction, AudioManager.FLAG_SHOW_UI)
                result.success(true)
            }
        } catch (e: Exception) {
            result.error("ERROR", "Failed to adjust volume: ${e.message}", null)
        }
    }

    private fun handleGetVolume(result: MethodChannel.Result) {
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            if (audioManager == null) {
                result.error("UNAVAILABLE", "AudioManager not available", null)
                return
            }
            val current = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
            val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            result.success(mapOf("current" to current, "max" to max))
        } catch (e: Exception) {
            result.error("ERROR", "Failed to get volume: ${e.message}", null)
        }
    }

    private fun handleControlMedia(action: String, result: MethodChannel.Result) {
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            val keyCode = when (action.lowercase()) {
                "play" -> KeyEvent.KEYCODE_MEDIA_PLAY
                "pause" -> KeyEvent.KEYCODE_MEDIA_PAUSE
                "next" -> KeyEvent.KEYCODE_MEDIA_NEXT
                "previous", "prev" -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
                "stop" -> KeyEvent.KEYCODE_MEDIA_STOP
                else -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            }
            val down = KeyEvent(KeyEvent.ACTION_DOWN, keyCode)
            val up = KeyEvent(KeyEvent.ACTION_UP, keyCode)
            audioManager?.dispatchMediaKeyEvent(down)
            audioManager?.dispatchMediaKeyEvent(up)
            result.success(true)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to dispatch media key event: ${e.message}", null)
        }
    }

    private fun handlePlayMusic(query: String?, app: String?, result: MethodChannel.Result) {
        try {
            // 1. Spotify Integration
            if (app.equals("spotify", ignoreCase = true) && !query.isNullOrBlank()) {
                val uri = Uri.parse("spotify:search:${Uri.encode(query)}")
                val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                    setPackage("com.spotify.music")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    result.success(mapOf("app" to "Spotify", "confirmed" to true))
                    return
                }
            }

            // 2. YouTube / YouTube Music Integration
            if ((app.equals("youtube", ignoreCase = true) || app.equals("youtube_music", ignoreCase = true)) && !query.isNullOrBlank()) {
                val uri = Uri.parse("https://www.youtube.com/results?search_query=${Uri.encode(query)}")
                val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
                result.success(mapOf("app" to "YouTube", "confirmed" to true))
                return
            }

            // 3. System Media Play from Search
            val mediaIntent = Intent(MediaStore.INTENT_ACTION_MEDIA_PLAY_FROM_SEARCH).apply {
                putExtra(SearchManager.QUERY, query ?: "")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (mediaIntent.resolveActivity(packageManager) != null) {
                startActivity(mediaIntent)
                result.success(mapOf("app" to "Default Media Player", "confirmed" to true))
            } else {
                result.error("UNAVAILABLE", "No media playback application found", null)
            }
        } catch (e: Exception) {
            result.error("ERROR", "Failed to execute music playback: ${e.message}", null)
        }
    }

    private fun handleSetTimer(seconds: Int, message: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(AlarmClock.ACTION_SET_TIMER).apply {
                putExtra(AlarmClock.EXTRA_LENGTH, seconds)
                putExtra(AlarmClock.EXTRA_MESSAGE, message)
                putExtra(AlarmClock.EXTRA_SKIP_UI, false)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                result.success(true)
            } else {
                result.error("UNAVAILABLE", "Timer clock application not available", null)
            }
        } catch (e: Exception) {
            result.error("ERROR", "Failed to set timer: ${e.message}", null)
        }
    }

    private fun handleSetAlarm(hour: Int, minute: Int, message: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                putExtra(AlarmClock.EXTRA_HOUR, hour)
                putExtra(AlarmClock.EXTRA_MINUTES, minute)
                putExtra(AlarmClock.EXTRA_MESSAGE, message)
                putExtra(AlarmClock.EXTRA_SKIP_UI, false)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                result.success(true)
            } else {
                result.error("UNAVAILABLE", "Alarm clock application not available", null)
            }
        } catch (e: Exception) {
            result.error("ERROR", "Failed to set alarm: ${e.message}", null)
        }
    }

    // --- SPEECH RECOGNITION HANDLERS ---

    private fun handleStartSpeechRecognition(result: MethodChannel.Result) {
        mainHandler.post {
            try {
                if (speechRecognizer == null) {
                    speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
                }

                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
                    putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)
                }

                speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {}
                    override fun onBeginningOfSpeech() {}
                    override fun onRmsChanged(rmsdB: Float) {}
                    override fun onBufferReceived(buffer: ByteArray?) {}
                    override fun onEndOfSpeech() {}

                    override fun onError(error: Int) {
                        mainHandler.post {
                            speechChannel?.invokeMethod("onError", mapOf("code" to error))
                        }
                    }

                    override fun onResults(results: Bundle?) {
                        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val scores = results?.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)
                        val text = matches?.firstOrNull() ?: ""
                        val conf = scores?.firstOrNull()?.toDouble() ?: 0.90
                        mainHandler.post {
                            speechChannel?.invokeMethod("onResult", mapOf("transcript" to text, "confidence" to conf))
                        }
                    }

                    override fun onPartialResults(partialResults: Bundle?) {
                        val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val partial = matches?.firstOrNull() ?: ""
                        if (partial.isNotEmpty()) {
                            mainHandler.post {
                                speechChannel?.invokeMethod("onPartialResult", mapOf("partial" to partial))
                            }
                        }
                    }

                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })

                speechRecognizer?.startListening(intent)
                result.success(true)
            } catch (e: Exception) {
                result.error("ERROR", "Failed to start speech recognizer: ${e.message}", null)
            }
        }
    }

    private fun handleStopSpeechRecognition(result: MethodChannel.Result) {
        mainHandler.post {
            try {
                speechRecognizer?.stopListening()
                result.success(true)
            } catch (e: Exception) {
                result.error("ERROR", "Failed to stop speech recognizer: ${e.message}", null)
            }
        }
    }

    // --- TEXT-TO-SPEECH HANDLERS ---

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            isTtsInitialized = true
            textToSpeech?.language = Locale.US
            // Try to find a female natural voice
            try {
                val femaleVoice = textToSpeech?.voices?.firstOrNull {
                    it.name.contains("female", ignoreCase = true) || it.name.contains("sfg", ignoreCase = true)
                }
                if (femaleVoice != null) {
                    textToSpeech?.voice = femaleVoice
                }
            } catch (_: Exception) {}

            textToSpeech?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {}
                override fun onDone(utteranceId: String?) {
                    mainHandler.post {
                        ttsChannel?.invokeMethod("onDone", mapOf("utteranceId" to utteranceId))
                    }
                }
                override fun onError(utteranceId: String?) {
                    mainHandler.post {
                        ttsChannel?.invokeMethod("onError", mapOf("utteranceId" to utteranceId))
                    }
                }
            })
        }
    }

    private fun handleSpeak(text: String, result: MethodChannel.Result) {
        if (!isTtsInitialized || textToSpeech == null) {
            result.error("UNAVAILABLE", "Text-to-speech engine is initializing", null)
            return
        }

        try {
            val utteranceId = "vega_${System.currentTimeMillis()}"
            textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
            result.success(true)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to speak: ${e.message}", null)
        }
    }

    private fun handleStopTts(result: MethodChannel.Result) {
        try {
            textToSpeech?.stop()
            result.success(true)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to stop TTS: ${e.message}", null)
        }
    }

    override fun onDestroy() {
        speechRecognizer?.destroy()
        speechRecognizer = null
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        super.onDestroy()
    }
}
