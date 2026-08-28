# HumSukhan — Production-Oriented Flutter Architecture Notes

## Product surface

HumSukhan is a privacy-first, accessibility-focused Flutter Android app with Everyday Mode for ephemeral live captions and spoken replies, Professional Mode for saved lecture and meeting records, Environmental Alerts for visible activity notices, and a Sign Language workspace that exposes the selected PSL model integration boundary without fabricating inference.

The interface uses a compact brand header, clear page title and supporting sentence, one primary action per surface, grouped/inset containers, quiet separators, generous spacing, large touch targets, and Material 3 outlined symbols. The supplied HumSukhan logo is used in the first-launch login, onboarding, home header, shared page headers, and navigation menu. Settings is reachable both from the explicit header settings icon and from the hamburger menu.

## Design system and accessibility

The design system is centralized in `lib/main.dart` through `HKSpace`, `HKRadius`, `HKColors`, semantic `ColorScheme` usage, and Material component themes. The bundled palette uses warm ivory and cream light surfaces, deep forest primary, sage secondary, soft leaf accent, and forest-derived dark surfaces. Status colors are reserved for success, warning, error, information, live, and disabled states.

Atkinson Hyperlegible is bundled globally with a larger readable type scale. Urdu-script bubbles and the reply composer use RTL direction and right-aligned text. The reply composer accepts Urdu Unicode text; the device’s Urdu keyboard must be enabled in Android keyboard settings because an app cannot install or switch the system keyboard locale by itself. Live recognition requests `ur-PK` for Urdu Script and uses `en-PK` for Roman Urdu.

## First launch, local account, and tutor

A first-launch local account gate asks for email address, username, password, and gender. No cloud account is created. The password is never stored as plaintext; only a SHA-256 credential digest marker is kept inside the Android Keystore-backed encrypted preference store. After local setup, a five-page walkthrough appears. The tutor is shown only during this first-start guide and selects a generated Pakistani-attire male or female illustration from the stored gender choice. The tutor is not shown on Home, Settings, or later sessions.

## Navigation and Settings

`HomeShell` maintains an in-app navigation stack for Home, Everyday Mode, Professional Mode, Environmental Alerts, Settings, History, and Sign Language. Android back returns through that in-app stack before allowing app exit. The hamburger menu is available from the brand header and shared page scaffolds. Settings contains language, accessibility, visual/haptic alert controls, local profile access, and deterministic retention evaluation.

## Conversation behavior

Everyday Mode remains ephemeral and has no save-conversation action. Speech recognition starts only after an explicit user action and remains continuous until the user stops the conversation. Native `speechPartial` messages populate one temporary evolving sentence bubble, while `speechFinal` commits exactly one cleaned sentence and clears the temporary bubble. Filler words are removed before display. This prevents repeated word prefixes from being rendered as separate chat messages.

The default English provider is now `SherpaOnnxSpeechProvider` in `lib/sherpa_speech.dart`. It initializes the Sherpa-ONNX runtime, copies the bundled model files to application-support storage, captures mono 16-bit PCM through the `record` plugin, feeds streaming samples to an online Zipformer recognizer, and forwards changing hypotheses and endpointed sentences into `AppController`. Raw PCM is processed in memory and is not persisted. The bundled checkpoint is the Apache-2.0 mobile English 20M model; it does not provide Urdu recognition.

When Sherpa-ONNX is disabled, unavailable, unable to start, or unsupported for the selected language, HumSukhan falls back to the Android `SpeechRecognizer` provider. Urdu Script and Roman Urdu therefore continue to use the platform provider until an Urdu-capable offline checkpoint is separately validated. Settings exposes the offline-English preference so the active provider is user-visible and controllable.

A typed response can be sent or spoken from the response composer. Quick replies are locally persisted. The composer exposes a language selector, Urdu-aware directionality, and a note that the system Urdu keyboard must be enabled for Urdu typing. No automatic “I understand” prefix is added.

Professional Mode creates only Professional records. A selected folder is the destination for a new session, user-created folders can be deleted, and a saved record opens into its transcript and insights detail view. Professional live captions use the same native recognition bridge and render distinct Speaker, Listening, and You bubbles. TXT export contains captions and metadata only.

## Environmental Alerts

The Android native bridge now exposes a temporary `AudioRecord` RMS activity monitor and a guarded flashlight handler. The monitor never persists or exports raw audio. Environmental Alerts exposes only fire alarm, siren, doorbell, knock, and police/ambulance profiles. A qualified activity event produces a clear activity notice and optional red/blue screen flash, haptic feedback, and flashlight pulse. The alert history has an explicit Clear action.

The activity monitor is not an acoustic classifier. It cannot honestly identify a fire alarm, siren, doorbell, knock, or police/ambulance sound by itself. Controlled test buttons label the selected event as a test. Confidence is intentionally not presented as class confidence; only the monitor’s threshold is used internally for activity gating.

## Sign-language recognition boundary

The selected Pakistan Sign Language reference is `AbdulMueez456/handlytics`, whose project describes word- and sentence-level PSL recognition using a ConvLSTM research pipeline. Its published repository is a Python/Flask application and does not provide a mobile-ready TFLite/ONNX artifact in this build. HumSukhan therefore exposes the repository and model description as a provider boundary but does not claim camera recognition, PSL vocabulary coverage, or confidence. A future production integration must obtain licensed mobile weights, camera frames, a native inference bridge, label mapping, and a validation set before enabling recognition.

## Privacy and retention

Raw audio is not represented as a persistent application field. The app stores captions and metadata only. Professional records have deterministic retention with a hard maximum of 15 days in this transformation. Export warnings explain that files shared outside the app are outside HumSukhan’s deletion control. The current insight provider is deterministic and local; no API key is embedded in the APK.

## Offline speech assets

The bundled Sherpa-ONNX model is registered under `assets/models/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17-mobile/` and contains only the mobile int8 encoder, decoder, int8 joiner, tokens file, and upstream model license notice. The app copies these assets into application-support storage on first use. Because the model adds approximately 34 MB of model files before APK compression and the native Sherpa runtime adds additional ABI libraries, the release APK is materially larger than the platform-only build. Model memory and latency must be measured on target Android hardware before production rollout.

## Platform assets and build

The supplied HumSukhan logo is bundled at `assets/HUMSUKHANLOGO.png`. Platform declaration files are registered at `assets/platform/HUMSUKHAN_Android_512.png` and `assets/platform/HUMSUKHAN_iOS_1024.png`. Generated first-start tutor illustrations are bundled at `assets/tutor_male.png` and `assets/tutor_female.png`; transparent onboarding variants are `assets/tutor_male_transparent.png` and `assets/tutor_female_transparent.png`. Atkinson Hyperlegible regular and bold fonts are bundled under `assets/fonts/`.

Use Flutter 3.47.1, Android SDK 36, and Java 17. The release build uses the default debug signing configuration for installation/testing and is not store-distribution signed. Recommended validation commands are:

```bash
flutter test
flutter analyze
flutter build apk --release --no-pub
```

The generated artifact is `build/app/outputs/flutter-apk/app-release.apk`.


## Multilingual Urdu offline fallback

`SherpaOnnxSpeechProvider` now routes Urdu Script to a bundled multilingual Whisper tiny checkpoint through Sherpa-ONNX `OfflineRecognizer`. Because the Whisper path is an offline recognizer rather than an online transducer, the provider captures PCM in memory and decodes rolling eight-second windows with a three-second hop. Changing Urdu hypotheses are sent to the same live-caption surface; the final hypothesis is flushed when the user stops. This is intentionally described as rolling-window live transcription, not low-latency streaming ASR.

The multilingual model is configured with language `ur` and task `transcribe`. Roman Urdu remains on the Android provider because the local Whisper path returns Urdu script and does not perform reliable romanisation. The bundled multilingual model adds approximately 99 MB of model files before APK compression, so the APK is substantially larger. Urdu word-error rate, real-time factor, memory, thermal behavior, and sentence stability must be measured on physical target devices before production release.
