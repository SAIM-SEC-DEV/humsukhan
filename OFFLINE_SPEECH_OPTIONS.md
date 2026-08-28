# Offline Speech-Recognition Options for HumSukhan

## Recommendation

The strongest replacement for Android `SpeechRecognizer` is **Sherpa-ONNX**, integrated behind HumSukhan’s existing `SpeechToTextProvider` abstraction. Its official project documents offline speech-to-text, both streaming and non-streaming recognition, Android support, Dart/Kotlin APIs, voice-activity detection, and punctuation support.[1] Its official Flutter documentation includes a streaming-ASR example and Android Flutter artifacts.[2] The current `sherpa_onnx` package listing also documents Android and Flutter support for local inference.[3]

Sherpa-ONNX is the best fit when HumSukhan needs continuous listening, predictable privacy behavior, and a future path to VAD and punctuation. It still requires selecting, packaging, and testing an appropriate model. The runtime’s broad model catalog is not a guarantee of Urdu coverage; an Urdu or multilingual model must be validated on target hardware before the UI makes an Urdu-accuracy claim.

## Practical alternatives

| Option | Offline | Streaming | Android / Flutter fit | English and Urdu considerations | Recommendation |
|---|---:|---:|---|---|---|
| **Sherpa-ONNX** | Yes | Yes | Strong: official Flutter streaming example, Android artifacts, Dart/Kotlin/C++ surfaces | English models are available in the catalog; Urdu availability must be confirmed model-by-model | **Preferred production path** |
| **Vosk via `vosk_flutter_service`** | Yes | Yes, through its Android microphone service | Good for a smaller Android-first integration; the package documents bundled Android binaries and asset-loaded models | Model selection is decisive. English is practical; Urdu requires a compatible Vosk model and accuracy testing | **Good lightweight fallback** |
| **Whisper.cpp via `whisper_cpp_flutter_plus`** | Yes | Yes, using managed rolling windows or PCM streams | Strong native Android option, but model size, CPU cost, and packaging complexity are higher | Multilingual Whisper models can handle Urdu in principle, but latency, memory, word timing, and model redistribution terms must be tested | **Best accuracy-oriented fallback** |
| **`speech_to_text`** | Device-dependent | Device-dependent | Easy Flutter API, but it delegates to the platform recognition service | It does not solve the current offline or platform-service reliability dependency | **Not a true offline replacement** |

## Why these options are credible

The Sherpa-ONNX project is Apache-2.0 licensed and explicitly lists local streaming ASR, Android, Dart, VAD, and punctuation capabilities.[1] Its Flutter documentation links a streaming-recognition example and Android Flutter artifacts.[2] The Vosk Flutter package documents offline recognition, Android binaries, asset-loaded models, and an Android microphone service that exposes partial and final results.[4]

Whisper.cpp is an MIT-licensed native C/C++ implementation of Whisper and explicitly lists Android support, CPU-only inference, quantization, VAD, and real-time microphone examples.[5] The `whisper_cpp_flutter_plus` package provides Android/iOS bindings with live microphone transcription, windowed streaming, VAD, language selection, and model management; it also warns that the Whisper and Silero model files are not bundled, so the application must manage model delivery and licensing.[6]

## Recommended HumSukhan rollout

First, keep the current Android provider available as a fallback and preserve the provider abstraction. Second, implement Sherpa-ONNX streaming ASR on a feature branch using a small English model and a local PCM audio path. Third, add a separately validated Urdu or multilingual model only after measuring latency, memory, partial-result quality, punctuation, and sentence stability on target Android hardware. Fourth, use VAD and punctuation as separate capabilities rather than presenting unsupported confidence values. Finally, expose the selected provider in Settings so the user knows whether recognition is platform-based or fully local.

Whisper.cpp is the strongest second implementation if recognition quality is more important than APK size and battery use. Vosk is the simpler lightweight alternative when a suitable language model is available. Neither package should be added blindly: model licensing, model size, ABI coverage, startup time, memory pressure, microphone concurrency, and Android lifecycle behavior must be tested in a release build.

Do not ship a large model directly inside the APK until its size and device performance are measured. A model download on first use can reduce the initial APK size, but it changes the product’s offline-first setup story and must include checksum verification, cancellation, storage visibility, and an explicit user choice.

## References

[1]: https://github.com/k2-fsa/sherpa-onnx "k2-fsa/sherpa-onnx — offline ASR runtime and model catalog"
[2]: https://k2-fsa.github.io/sherpa/onnx/flutter/pre-built-app.html "Sherpa-ONNX pre-built Flutter applications and streaming ASR"
[3]: https://pub.dev/packages/sherpa_onnx "sherpa_onnx package metadata and platform support"
[4]: https://pub.dev/packages/vosk_flutter_service "Vosk Flutter Service package documentation"
[5]: https://github.com/ggml-org/whisper.cpp "ggml-org/whisper.cpp — native offline Whisper inference"
[6]: https://pub.dev/packages/whisper_cpp_flutter_plus "whisper_cpp_flutter_plus package documentation"
[7]: https://pub.dev/packages/speech_to_text "speech_to_text package documentation"

## Implementation record

Sherpa-ONNX is now integrated in `lib/sherpa_speech.dart` behind HumSukhan’s existing `SpeechToTextProvider` abstraction. The provider initializes the native runtime, copies the bundled model files into application-support storage, captures mono 16-bit PCM through the `record` package, feeds streaming samples to an online Zipformer recognizer, and forwards changing hypotheses plus endpointed sentences into `AppController`.

The bundled checkpoint is the official mobile English 20M streaming model. Only the int8 encoder, decoder, int8 joiner, tokens file, and upstream license notice are packaged. The default provider preference is offline English recognition. When the local provider cannot initialize, obtain permission, start the PCM stream, or support the selected language, HumSukhan falls back to Android `SpeechRecognizer`. Urdu Script and Roman Urdu continue to use the platform provider because this bundled checkpoint is English-only.

The Flutter project passes Dart analysis with no errors, passes the existing widget tests, and builds an Android release APK containing the native runtime and model assets. A physical Android test is still required for microphone permission flow, startup latency, real-time factor, memory, thermal behavior, endpoint stability, and recognition accuracy on the intended devices.

[8]: https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17-mobile.tar.bz2 "Official mobile English 20M Sherpa-ONNX model archive and Apache-2.0 notice"
