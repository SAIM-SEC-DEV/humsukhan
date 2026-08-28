import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import 'main.dart' show CaptionLanguage, SpeechToTextProvider;

enum _SherpaEngine { englishStreaming, urduWhisper }

/// Offline speech provider for HumSukhan.
///
/// English uses the bundled streaming Zipformer checkpoint. Urdu Script uses
/// the bundled multilingual Whisper tiny checkpoint in rolling local windows.
/// Roman Urdu remains on the Android platform provider because Whisper returns
/// Urdu script rather than a reliable romanisation.
class SherpaOnnxSpeechProvider implements SpeechToTextProvider {
  static const englishModelDirectory =
      'assets/models/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17-mobile';
  static const multilingualModelDirectory =
      'assets/models/sherpa-onnx-whisper-tiny';
  static const sampleRate = 16000;
  static const _urduWindowSamples = sampleRate * 8;
  static const _urduHopSamples = sampleRate * 3;

  final AudioRecorder Function() _recorderFactory;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _audioSubscription;

  sherpa_onnx.OnlineRecognizer? _englishRecognizer;
  sherpa_onnx.OnlineStream? _englishStream;
  sherpa_onnx.OfflineRecognizer? _urduRecognizer;

  _SherpaEngine? _engine;
  bool _running = false;
  bool _bindingsReady = false;
  bool _urduInferenceRunning = false;
  String _lastEnglishHypothesis = '';
  String _lastUrduHypothesis = '';
  final List<double> _urduSamples = <double>[];

  void Function(String text)? _onPartial;
  void Function(String text)? _onFinal;
  void Function(String status)? _onStatus;
  void Function(String error)? _onError;

  SherpaOnnxSpeechProvider({AudioRecorder Function()? recorderFactory})
      : _recorderFactory = recorderFactory ?? AudioRecorder.new;

  @override
  String get id => 'sherpa-onnx-offline-multilingual';

  bool get isRunning => _running;

  bool get isInitialized => _englishRecognizer != null || _urduRecognizer != null;

  @override
  bool supports(CaptionLanguage language, bool online) {
    return language == CaptionLanguage.english ||
        language == CaptionLanguage.auto ||
        language == CaptionLanguage.urduScript;
  }

  void setListeners({
    void Function(String text)? onPartial,
    void Function(String text)? onFinal,
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) {
    _onPartial = onPartial;
    _onFinal = onFinal;
    _onStatus = onStatus;
    _onError = onError;
  }

  Future<String> _copyAssetFile(String asset) async {
    final directory = await getApplicationSupportDirectory();
    final target = path.join(directory.path, path.basename(asset));
    final data = await rootBundle.load(asset);
    final file = File(target);
    if (!await file.exists() || await file.length() != data.lengthInBytes) {
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    return target;
  }

  Future<void> _ensureBindings() async {
    if (_bindingsReady) return;
    await sherpa_onnx.initBindingsAsync();
    _bindingsReady = true;
  }

  Future<void> _ensureEnglishRecognizer() async {
    if (_englishRecognizer != null) return;
    await _ensureBindings();
    final encoder = await _copyAssetFile(
      '$englishModelDirectory/encoder-epoch-99-avg-1.int8.onnx',
    );
    final decoder = await _copyAssetFile(
      '$englishModelDirectory/decoder-epoch-99-avg-1.onnx',
    );
    final joiner = await _copyAssetFile(
      '$englishModelDirectory/joiner-epoch-99-avg-1.int8.onnx',
    );
    final tokens = await _copyAssetFile('$englishModelDirectory/tokens.txt');
    _englishRecognizer = sherpa_onnx.OnlineRecognizer(
      sherpa_onnx.OnlineRecognizerConfig(
        model: sherpa_onnx.OnlineModelConfig(
          transducer: sherpa_onnx.OnlineTransducerModelConfig(
            encoder: encoder,
            decoder: decoder,
            joiner: joiner,
          ),
          tokens: tokens,
          numThreads: 2,
          provider: 'cpu',
          debug: false,
          modelType: 'zipformer',
        ),
        ruleFsts: '',
        enableEndpoint: true,
      ),
    );
  }

  Future<void> _ensureUrduRecognizer() async {
    if (_urduRecognizer != null) return;
    await _ensureBindings();
    final encoder = await _copyAssetFile(
      '$multilingualModelDirectory/tiny-encoder.int8.onnx',
    );
    final decoder = await _copyAssetFile(
      '$multilingualModelDirectory/tiny-decoder.int8.onnx',
    );
    final tokens = await _copyAssetFile(
      '$multilingualModelDirectory/tiny-tokens.txt',
    );
    _urduRecognizer = sherpa_onnx.OfflineRecognizer(
      sherpa_onnx.OfflineRecognizerConfig(
        model: sherpa_onnx.OfflineModelConfig(
          whisper: sherpa_onnx.OfflineWhisperModelConfig(
            encoder: encoder,
            decoder: decoder,
            language: 'ur',
            task: 'transcribe',
          ),
          tokens: tokens,
          numThreads: 2,
          debug: false,
          provider: 'cpu',
          modelType: 'whisper',
        ),
      ),
    );
  }

  @override
  Future<void> start({required CaptionLanguage language}) async {
    if (!supports(language, false)) {
      throw UnsupportedError(
        'Sherpa offline supports English and Urdu Script. Roman Urdu uses the Android provider.',
      );
    }
    if (_running) return;

    _engine = language == CaptionLanguage.urduScript
        ? _SherpaEngine.urduWhisper
        : _SherpaEngine.englishStreaming;
    _onStatus?.call('starting');
    try {
      if (_engine == _SherpaEngine.urduWhisper) {
        await _ensureUrduRecognizer();
      } else {
        await _ensureEnglishRecognizer();
      }

      _recorder = _recorderFactory();
      if (!await _recorder!.hasPermission()) {
        throw StateError('Microphone permission was not granted.');
      }
      if (!await _recorder!.isEncoderSupported(AudioEncoder.pcm16bits)) {
        throw StateError('16-bit PCM microphone capture is unavailable on this device.');
      }

      _englishStream?.free();
      _englishStream = _engine == _SherpaEngine.englishStreaming
          ? _englishRecognizer!.createStream()
          : null;
      _urduSamples.clear();
      _lastEnglishHypothesis = '';
      _lastUrduHypothesis = '';
      _urduInferenceRunning = false;

      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
      );
      final audioStream = await _recorder!.startStream(config);
      _running = true;
      _onStatus?.call('listening');
      _audioSubscription = audioStream.listen(
        _consumeAudio,
        onError: (Object error, StackTrace stack) {
          _onError?.call('Offline microphone stream failed: $error');
          _onStatus?.call('stopped');
        },
        onDone: () {
          if (_running) _onStatus?.call('stopped');
        },
      );
    } catch (error) {
      _running = false;
      _onStatus?.call('stopped');
      _onError?.call('Offline speech could not start: $error');
      await _disposeAudioOnly();
      _engine = null;
      rethrow;
    }
  }

  void _consumeAudio(Uint8List bytes) {
    if (!_running || bytes.isEmpty) return;
    try {
      final samples = _pcm16ToFloat32(bytes);
      if (_engine == _SherpaEngine.urduWhisper) {
        _urduSamples.addAll(samples);
        if (_urduSamples.length >= _urduWindowSamples && !_urduInferenceRunning) {
          unawaited(_transcribeUrduWindow());
        }
        return;
      }

      final stream = _englishStream;
      final recognizer = _englishRecognizer;
      if (stream == null || recognizer == null) return;
      stream.acceptWaveform(samples: samples, sampleRate: sampleRate);
      while (recognizer.isReady(stream)) {
        recognizer.decode(stream);
      }
      final text = recognizer.getResult(stream).text.trim();
      if (text.isNotEmpty && text != _lastEnglishHypothesis) {
        _lastEnglishHypothesis = text;
        _onPartial?.call(text);
      }
      if (recognizer.isEndpoint(stream)) {
        if (_lastEnglishHypothesis.isNotEmpty) {
          _onFinal?.call(_lastEnglishHypothesis);
        }
        recognizer.reset(stream);
        _lastEnglishHypothesis = '';
      }
    } catch (error) {
      _onError?.call('Offline speech decoding failed: $error');
    }
  }

  Future<void> _transcribeUrduWindow({bool force = false}) async {
    if (_urduInferenceRunning || _urduRecognizer == null) return;
    if (!force && _urduSamples.length < _urduWindowSamples) return;
    if (_urduSamples.isEmpty) return;

    _urduInferenceRunning = true;
    try {
      final start = _urduSamples.length > _urduWindowSamples
          ? _urduSamples.length - _urduWindowSamples
          : 0;
      final window = Float32List.fromList(_urduSamples.sublist(start));
      final stream = _urduRecognizer!.createStream();
      try {
        stream.acceptWaveform(samples: window, sampleRate: sampleRate);
        _urduRecognizer!.decode(stream);
        final text = _urduRecognizer!.getResult(stream).text.trim();
        if (text.isNotEmpty && text != _lastUrduHypothesis) {
          _lastUrduHypothesis = text;
          _onPartial?.call(text);
        }
      } finally {
        stream.free();
      }
      if (_urduSamples.length > _urduHopSamples) {
        _urduSamples.removeRange(0, _urduHopSamples);
      } else if (force) {
        _urduSamples.clear();
      }
    } catch (error) {
      _onError?.call('Urdu offline speech decoding failed: $error');
    } finally {
      _urduInferenceRunning = false;
    }
  }

  Float32List _pcm16ToFloat32(Uint8List bytes) {
    final result = Float32List(bytes.length ~/ 2);
    final data = ByteData.sublistView(bytes);
    for (var i = 0; i < result.length; i++) {
      result[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return result;
  }

  Future<void> _disposeAudioOnly() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    try {
      await _recorder?.stop();
    } catch (_) {}
    try {
      await _recorder?.dispose();
    } catch (_) {}
    _recorder = null;
  }

  @override
  Future<void> stop() async {
    if (!_running && _audioSubscription == null && _engine == null) return;
    final wasUrdu = _engine == _SherpaEngine.urduWhisper;
    _running = false;
    await _disposeAudioOnly();
    if (wasUrdu) {
      await _transcribeUrduWindow(force: true);
      if (_lastUrduHypothesis.isNotEmpty) _onFinal?.call(_lastUrduHypothesis);
    } else if (_lastEnglishHypothesis.isNotEmpty) {
      _onFinal?.call(_lastEnglishHypothesis);
    }
    _englishStream?.free();
    _englishStream = null;
    _urduSamples.clear();
    _lastEnglishHypothesis = '';
    _lastUrduHypothesis = '';
    _urduInferenceRunning = false;
    _engine = null;
    _onStatus?.call('stopped');
  }

  Future<void> dispose() async {
    await stop();
    _englishRecognizer?.free();
    _englishRecognizer = null;
    _urduRecognizer?.free();
    _urduRecognizer = null;
  }
}
