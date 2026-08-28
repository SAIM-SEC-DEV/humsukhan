from pathlib import Path

p = Path('/home/ubuntu/projects/humsukhan/android/app/src/main/kotlin/com/humsukhan/humsukhan/MainActivity.kt')
s = p.read_text()

s = s.replace('import android.content.pm.PackageManager\n', 'import android.content.pm.PackageManager\nimport android.hardware.camera2.CameraManager\nimport android.media.AudioFormat\nimport android.media.AudioRecord\nimport android.media.MediaRecorder\nimport kotlin.math.sqrt\n')
s = s.replace('    private var ttsReady = false\n', '    private var ttsReady = false\n    private var audioRecord: AudioRecord? = null\n    @Volatile private var monitoring = false\n    private var audioThread: Thread? = null\n')
s = s.replace('                "hapticAlert" -> {\n                    vibrate()\n                    result.success(null)\n                }\n', '                "hapticAlert" -> {\n                    vibrate()\n                    result.success(null)\n                }\n                "soundMonitoringStart" -> startSoundMonitoring(result)\n                "soundMonitoringStop" -> {\n                    stopSoundMonitoring()\n                    result.success(null)\n                }\n                "flashlight" -> setFlashlight(call.argument<Boolean>("enabled") == true, result)\n')

needle = '    private fun shareTextFile(call: MethodCall, result: MethodChannel.Result) {\n'
insert = r'''    private fun startSoundMonitoring(result: MethodChannel.Result) {
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

'''
if needle not in s:
    raise SystemExit('shareTextFile marker not found')
s = s.replace(needle, insert + needle)
s = s.replace('        stopSpeech()\n        textToSpeech?.stop()', '        stopSpeech()\n        stopSoundMonitoring()\n        textToSpeech?.stop()')
p.write_text(s)
print('patched MainActivity.kt')
'''}Rhumela 和盛? 和盛? 精品国产? 
