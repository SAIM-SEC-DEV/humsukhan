package com.humsukhan.humsukhan

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.camera2.CameraManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import kotlin.math.sqrt
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import androidx.core.content.FileProvider
import android.util.Base64
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import java.util.Locale
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val nativeChannel = "humsukhan/native"
    private val storageChannel = "humsukhan/storage"
    private val speechPermissionRequest = 701
    private var speechRecognizer: SpeechRecognizer? = null
    private var speechIntent: Intent? = null
    private var speechRestart: Runnable? = null
    private val speechHandler = Handler(Looper.getMainLooper())
    private var continuousListening = false
    private var userRequestedStop = false
    private var nativeMethodChannel: MethodChannel? = null
    private var textToSpeech: TextToSpeech? = null
    private var pendingTtsText: String? = null
    private var pendingTtsLanguage: String = "en"
    private var ttsReady = false
    private var audioRecord: AudioRecord? = null
    @Volatile private var monitoring = false
    private var audioThread: Thread? = null
    private var pendingSpeechLocale: String? = null
    private var recognitionErrorCount = 0
    private lateinit var secureStore: SecureStore

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        secureStore = SecureStore(this)
        textToSpeech = TextToSpeech(this, this)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nativeMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, nativeChannel)
        nativeMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "speechStart" -> startSpeech(call, result)
                "speechStop" -> {
                    stopSpeech()
                    result.success(null)
                }
                "ttsSpeak" -> {
                    pendingTtsText = call.argument<String>("text") ?: ""
                    pendingTtsLanguage = call.argument<String>("language") ?: "en"
                    speakPendingText()
                    result.success(null)
                }
                "hapticAlert" -> {
                    vibrate()
                    result.success(null)
                }
                "soundMonitoringStart" -> startSoundMonitoring(result)
                "soundMonitoringStop" -> {
                    stopSoundMonitoring()
                    result.success(null)
                }
                "flashlight" -> setFlashlight(call.argument<Boolean>("enabled") == true, result)
                "shareTextFile" -> shareTextFile(call, result)
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, storageChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "get" -> result.success(secureStore.get(call.argument<String>("key") ?: ""))
                "set" -> {
                    secureStore.set(call.argument<String>("key") ?: "", call.argument<String>("value") ?: "")
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startSpeech(call: MethodCall, result: MethodChannel.Result) {
        val requestedLocale = call.argument<String>("locale") ?: "en-US"
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            pendingSpeechLocale = requestedLocale
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), speechPermissionRequest)
            result.error("MIC_PERMISSION_REQUIRED", "Microphone permission is required. Captions will begin after permission is granted.", null)
            return
        }
        beginSpeech(requestedLocale)
        result.success(null)
    }

    private fun beginSpeech(locale: String) {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            invokeFlutter("speechStatus", "stopped")
            invokeFlutter("speechError", "Speech recognition is not available on this device.")
            return
        }
        userRequestedStop = false
        continuousListening = true
        speechIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, locale)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
            // Do not force offline mode: many Android devices have no offline pack,
            // which otherwise produces a silent/no-result recognition failure.
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 1200L)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 2500L)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 3500L)
        }
        recognitionErrorCount = 0
        createRecognizerIfNeeded()
        startListeningNow()
    }

    private fun createRecognizerIfNeeded() {
        if (speechRecognizer != null) return
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) { invokeFlutter("speechStatus", "ready") }
            override fun onBeginningOfSpeech() { invokeFlutter("speechStatus", "listening") }
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onPartialResults(partialResults: Bundle?) {
                val text = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                if (!text.isNullOrBlank()) invokeFlutter("speechPartial", text)
            }
            override fun onResults(results: Bundle?) {
                val text = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                if (!text.isNullOrBlank()) invokeFlutter("speechFinal", text)
                recognitionErrorCount = 0
                restartListeningIfNeeded(260)
            }
            override fun onError(error: Int) {
                if (continuousListening && !userRequestedStop && error != SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS) {
                    recognitionErrorCount += 1
                    invokeFlutter("speechStatus", "reconnecting")
                    invokeFlutter("speechError", speechErrorMessage(error))
                    restartListeningIfNeeded(if (error == SpeechRecognizer.ERROR_NO_MATCH) 240 else 700)
                } else {
                    invokeFlutter("speechStatus", "stopped")
                    invokeFlutter("speechError", speechErrorMessage(error))
                }
            }
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
    }

    private fun startListeningNow() {
        if (!continuousListening || userRequestedStop) return
        try {
            speechRecognizer?.startListening(speechIntent ?: return)
            invokeFlutter("speechStatus", "listening")
        } catch (error: Exception) {
            invokeFlutter("speechStatus", "reconnecting")
            invokeFlutter("speechError", error.message ?: "Speech recognition could not start.")
            restartListeningIfNeeded(900)
        }
    }

    private fun restartListeningIfNeeded(delayMs: Long) {
        if (!continuousListening || userRequestedStop) return
        speechRestart?.let { speechHandler.removeCallbacks(it) }
        speechRestart = Runnable { startListeningNow() }
        speechHandler.postDelayed(speechRestart!!, delayMs)
    }

    private fun stopSpeech() {
        userRequestedStop = true
        continuousListening = false
        speechRestart?.let { speechHandler.removeCallbacks(it) }
        speechRestart = null
        speechRecognizer?.stopListening()
        speechRecognizer?.cancel()
        speechRecognizer?.destroy()
        speechRecognizer = null
        speechIntent = null
        invokeFlutter("speechStatus", "stopped")
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == speechPermissionRequest && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            pendingSpeechLocale?.let {
                pendingSpeechLocale = null
                beginSpeech(it)
                invokeFlutter("speechStatus", "listening")
            }
        } else if (requestCode == speechPermissionRequest) {
            invokeFlutter("speechStatus", "stopped")
            invokeFlutter("speechError", "Microphone permission was not granted.")
        }
    }

    private fun startSoundMonitoring(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            result.error("MIC_PERMISSION_REQUIRED", "Microphone permission is required for environmental monitoring.", null)
            return
        }
        if (monitoring) {
            result.success(null)
            return
        }
        val min = AudioRecord.getMinBufferSize(
            16000,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        if (min <= 0) {
            result.error("AUDIO_MONITOR_UNAVAILABLE", "Environmental audio monitoring is unavailable on this device.", null)
            return
        }
        try {
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                16000,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                maxOf(min, 4096),
            )
            monitoring = true
            audioRecord?.startRecording()
            audioThread = Thread {
                val buffer = ShortArray(2048)
                var lastEvent = 0L
                while (monitoring) {
                    val count = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (count > 0) {
                        var sum = 0.0
                        for (i in 0 until count) {
                            val sample = buffer[i].toDouble() / 32768.0
                            sum += sample * sample
                        }
                        val rms = sqrt(sum / count.toDouble())
                        val normalized = (rms * 8.0).coerceIn(0.0, 1.0)
                        val now = System.currentTimeMillis()
                        if (normalized >= 0.18 && now - lastEvent > 2500L) {
                            lastEvent = now
                            invokeFlutter("environmentSoundActivity", normalized.toString())
                        }
                    }
                }
            }.also { it.start() }
            result.success(null)
        } catch (error: Exception) {
            stopSoundMonitoring()
            result.error("AUDIO_MONITOR_UNAVAILABLE", error.message ?: "Environmental audio monitoring failed.", null)
        }
    }

    private fun stopSoundMonitoring() {
        monitoring = false
        try { audioRecord?.stop() } catch (_: Exception) {}
        try { audioRecord?.release() } catch (_: Exception) {}
        audioRecord = null
        audioThread = null
    }

    private fun setFlashlight(enabled: Boolean, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.error("FLASHLIGHT_UNAVAILABLE", "Flashlight control is unavailable on this Android version.", null)
            return
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            result.error("CAMERA_PERMISSION_REQUIRED", "Camera permission is required for flashlight feedback.", null)
            return
        }
        try {
            val manager = getSystemService(CameraManager::class.java)
            val cameraId = manager.cameraIdList.firstOrNull { id ->
                manager.getCameraCharacteristics(id).get(android.hardware.camera2.CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
            if (cameraId == null) {
                result.error("FLASHLIGHT_UNAVAILABLE", "This device has no controllable flashlight.", null)
            } else {
                manager.setTorchMode(cameraId, enabled)
                result.success(null)
            }
        } catch (error: Exception) {
            result.error("FLASHLIGHT_FAILED", error.message ?: "Could not control the flashlight.", null)
        }
    }

    private fun shareTextFile(call: MethodCall, result: MethodChannel.Result) {
        try {
            val directory = File(cacheDir, "shared").apply { mkdirs() }
            val requestedName = call.argument<String>("fileName") ?: "humsukhan-session.txt"
            val safeName = requestedName.replace(Regex("[^A-Za-z0-9_.-]"), "_")
            val file = File(directory, if (safeName.endsWith(".txt")) safeName else "$safeName.txt")
            file.writeText(call.argument<String>("content") ?: "", StandardCharsets.UTF_8)
            val uri: Uri = FileProvider.getUriForFile(this, "${packageName}.fileprovider", file)
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(intent, "Share HumSukhan TXT"))
            result.success(null)
        } catch (error: Exception) {
            result.error("TXT_SHARE_FAILED", error.message ?: "Could not share the TXT file.", null)
        }
    }

    private fun invokeFlutter(method: String, argument: String) {
        runOnUiThread { nativeMethodChannel?.invokeMethod(method, argument) }
    }

    private fun speechErrorMessage(error: Int): String = when (error) {
        SpeechRecognizer.ERROR_NETWORK, SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Online speech recognition is unavailable. Check connectivity or continue with typed captions."
        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Microphone permission was not granted."
        SpeechRecognizer.ERROR_NO_MATCH -> "No speech was recognized. Try again or type a caption."
        else -> "Speech recognition stopped. You can try again or type a caption."
    }

    override fun onInit(status: Int) {
        ttsReady = status == TextToSpeech.SUCCESS
        if (ttsReady) {
            textToSpeech?.language = Locale.US
            speakPendingText()
        }
    }

    private fun speakPendingText() {
        val text = pendingTtsText ?: return
        val tts = textToSpeech ?: return
        if (!ttsReady) return
        val locale = if (pendingTtsLanguage == "ur") Locale("ur") else Locale.US
        val availability = tts.isLanguageAvailable(locale)
        if (availability >= TextToSpeech.LANG_AVAILABLE) tts.language = locale else tts.language = Locale.US
        tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "humsukhan-response")
        pendingTtsText = null
    }

    private fun vibrate() {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION") getSystemService(VIBRATOR_SERVICE) as Vibrator
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) vibrator.vibrate(VibrationEffect.createOneShot(300, VibrationEffect.DEFAULT_AMPLITUDE)) else @Suppress("DEPRECATION") vibrator.vibrate(300)
    }

    override fun onDestroy() {
        stopSpeech()
        stopSoundMonitoring()
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        super.onDestroy()
    }
}

private class SecureStore(private val activity: MainActivity) {
    private val alias = "humsukhan_local_aes"
    private val prefs = activity.getSharedPreferences("humsukhan_secure_store", Context.MODE_PRIVATE)

    private fun key(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val existing = keyStore.getKey(alias, null)
        if (existing is SecretKey) return existing
        val generator = KeyGenerator.getInstance("AES", "AndroidKeyStore")
        generator.init(android.security.keystore.KeyGenParameterSpec.Builder(alias, android.security.keystore.KeyProperties.PURPOSE_ENCRYPT or android.security.keystore.KeyProperties.PURPOSE_DECRYPT).setBlockModes(android.security.keystore.KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(android.security.keystore.KeyProperties.ENCRYPTION_PADDING_NONE).build())
        return generator.generateKey()
    }

    fun set(name: String, value: String) {
        try {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, key())
            val iv = Base64.encodeToString(cipher.iv, Base64.NO_WRAP)
            val encrypted = Base64.encodeToString(cipher.doFinal(value.toByteArray(StandardCharsets.UTF_8)), Base64.NO_WRAP)
            prefs.edit().putString(name, "$iv:$encrypted").apply()
        } catch (_: Exception) {
            // Do not log sensitive values. Failure simply leaves the previous value intact.
        }
    }

    fun get(name: String): String? {
        return try {
            val packed = prefs.getString(name, null) ?: return null
            val parts = packed.split(":", limit = 2)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, Base64.decode(parts[0], Base64.NO_WRAP)))
            String(cipher.doFinal(Base64.decode(parts[1], Base64.NO_WRAP)), StandardCharsets.UTF_8)
        } catch (_: Exception) {
            null
        }
    }
}
