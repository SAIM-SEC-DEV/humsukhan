# HumSukhan physical-device speech benchmark

This benchmark must be run on a physical Android phone because the current sandbox has no connected Android device or emulator.

## Setup

Install the release APK and grant microphone permission:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell pm grant com.humsukhan.humsukhan android.permission.RECORD_AUDIO
```

Open Everyday Mode, select English, enable bundled offline speech in Settings, and start a conversation. Repeat with Urdu Script. Use the same three scripted sentences for each run and record the wall-clock time from tapping Start Conversation to the first live caption and to the first finalized sentence.

## Accuracy set

Use a quiet-room English set and a quiet-room Urdu set with at least 10 known sentences each. Compare the displayed final captions against the reference text. Report word error rate separately for English and Urdu; do not combine languages into one score. Also record missed captions, duplicated phrases, and endpoint delays.

## Memory and latency capture

While a session is active, collect Android process memory at one-minute intervals:

```bash
adb shell dumpsys meminfo com.humsukhan.humsukhan | tee -a meminfo.log
adb shell pidof com.humsukhan.humsukhan
adb shell top -b -n 1 -p "$(adb shell pidof com.humsukhan.humsukhan)"
```

Record the following for each language and model path: cold model-load time, time to microphone-ready state, time to first partial caption, time to final caption, peak PSS, CPU percentage, battery drain over a fixed session, and whether the app falls back to Android speech.

## Acceptance criteria

A candidate device is not production-ready until the English and Urdu paths have stable microphone startup, no unbounded memory growth, acceptable real-time factor, no repeated caption windows, and an accuracy result documented against the fixed sentence set. The Urdu path is currently a rolling-window offline Whisper path, so its latency is expected to be higher than the English streaming Zipformer path.
