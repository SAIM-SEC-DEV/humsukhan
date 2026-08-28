import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';

import 'sherpa_speech.dart';

const _brandPrimaryLight = Color(0xFF214B3A);
const _brandSecondaryLight = Color(0xFF5F806D);
const _brandAccentLight = Color(0xFF8FAF9F);
const _brandSurfaceLight = Color(0xFFF7F7F0);
const _brandTextLight = Color(0xFF1F2C27);
const _brandPrimaryDark = Color(0xFF8FB7A4);
const _brandSecondaryDark = Color(0xFF79A98F);
const _brandAccentDark = Color(0xFFB7CDBF);
const _brandBackgroundDark = Color(0xFF0F2119);
const _brandSurfaceDark = Color(0xFF183126);
const _brandTextDark = Color(0xFFF4F6F1);

class HKSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const hero = 40.0;
}

class HKRadius {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

BoxShadow _softSurfaceShadow(ColorScheme scheme) => BoxShadow(
  color: scheme.primary.withValues(alpha: 0.08),
  blurRadius: 24,
  offset: const Offset(0, 10),
);

BoxShadow _tightSurfaceShadow(ColorScheme scheme) => BoxShadow(
  color: scheme.primary.withValues(alpha: 0.06),
  blurRadius: 12,
  offset: const Offset(0, 4),
);

class HKColors {
  static const successLight = Color(0xFF4D7A61);
  static const warningLight = Color(0xFFE6DCC1);
  static const errorLight = Color(0xFFB86563);
  static const infoLight = Color(0xFF6F90A7);
  static const live = Color(0xFF4D7A61);
}

bool _containsUrdu(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);

ColorScheme _lightBrandScheme() =>
    ColorScheme.fromSeed(
      seedColor: _brandPrimaryLight,
      brightness: Brightness.light,
    ).copyWith(
      primary: _brandPrimaryLight,
      onPrimary: Colors.white,
      secondary: _brandSecondaryLight,
      onSecondary: Colors.white,
      tertiary: _brandAccentLight,
      onTertiary: _brandTextLight,
      surface: _brandSurfaceLight,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Colors.white,
      surfaceContainer: Color(0xFFEFF3EE),
      surfaceContainerHigh: Color(0xFFE7EEE9),
      surfaceContainerHighest: Color(0xFFDDE9E2),
      onSurface: _brandTextLight,
      onSurfaceVariant: Color(0xFF53645C),
      outline: Color(0xFF718078),
      outlineVariant: Color(0xFFD4DED8),
      primaryContainer: Color(0xFFD7E8DE),
      onPrimaryContainer: _brandTextLight,
      secondaryContainer: Color(0xFFE0EAE5),
      onSecondaryContainer: _brandTextLight,
      tertiaryContainer: Color(0xFFE7EEE9),
      onTertiaryContainer: _brandTextLight,
      error: Color(0xFFB86563),
      errorContainer: Color(0xFFF3D8D5),
      onErrorContainer: Color(0xFF5E292B),
    );

ColorScheme _darkBrandScheme() =>
    ColorScheme.fromSeed(
      seedColor: _brandPrimaryDark,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _brandPrimaryDark,
      onPrimary: _brandBackgroundDark,
      secondary: _brandSecondaryDark,
      onSecondary: _brandBackgroundDark,
      tertiary: _brandAccentDark,
      onTertiary: _brandBackgroundDark,
      surface: _brandBackgroundDark,
      surfaceContainerLowest: _brandBackgroundDark,
      surfaceContainerLow: _brandSurfaceDark,
      surfaceContainer: Color(0xFF1D3A2E),
      surfaceContainerHigh: Color(0xFF234236),
      surfaceContainerHighest: Color(0xFF2C4A3D),
      onSurface: _brandTextDark,
      onSurfaceVariant: Color(0xFFB4C2BB),
      outline: Color(0xFF3B554A),
      outlineVariant: Color(0xFF365246),
      primaryContainer: Color(0xFF2D5746),
      onPrimaryContainer: _brandTextDark,
      secondaryContainer: Color(0xFF2C4A3D),
      onSecondaryContainer: _brandTextDark,
      tertiaryContainer: Color(0xFF315344),
      onTertiaryContainer: _brandTextDark,
      error: Color(0xFFC97474),
      errorContainer: Color(0xFF5A2E2E),
      onErrorContainer: _brandTextDark,
    );

// HumSukhan is intentionally provider-agnostic. UI code depends on these
// interfaces and on AppController, never on a cloud speech/TTS/AI vendor.

enum ConversationState { idle, starting, active, stopping, saveDecision }

enum SessionType { classSession, lecture, meeting }

enum RetentionDays { one, seven, fifteen }

enum CaptionLanguage { english, romanUrdu, urduScript, auto }

enum LocalGender { male, female, other, preferNotToSay }

extension LocalGenderLabel on LocalGender {
  String get label => switch (this) {
    LocalGender.male => 'Male',
    LocalGender.female => 'Female',
    LocalGender.other => 'Other',
    LocalGender.preferNotToSay => 'Prefer not to say',
  };
}

LocalGender _genderFromStored(String? value) => LocalGender.values.firstWhere(
  (gender) => gender.name == value,
  orElse: () => LocalGender.preferNotToSay,
);

enum Capability { speechRecognition, textToSpeech, aiInsights, soundDetection }

extension RetentionDaysValue on RetentionDays {
  int get value => switch (this) {
    RetentionDays.one => 1,
    RetentionDays.seven => 7,
    RetentionDays.fifteen => 15,
  };

  String get label => '$value day${value == 1 ? '' : 's'}';
}

extension CaptionLanguageLabel on CaptionLanguage {
  String get label => switch (this) {
    CaptionLanguage.english => 'English',
    CaptionLanguage.romanUrdu => 'Roman Urdu',
    CaptionLanguage.urduScript => 'Urdu script',
    CaptionLanguage.auto => 'Auto-detect',
  };
}

extension SessionTypeLabel on SessionType {
  String get label => switch (this) {
    SessionType.classSession => 'Class',
    SessionType.lecture => 'Lecture',
    SessionType.meeting => 'Meeting',
  };
}

class RetentionPolicy {
  final DateTime createdAt;
  final DateTime expiresAt;
  final int retentionDays;
  final String deletionStatus;

  const RetentionPolicy({
    required this.createdAt,
    required this.expiresAt,
    required this.retentionDays,
    this.deletionStatus = 'active',
  });

  factory RetentionPolicy.create(RetentionDays days) {
    final now = DateTime.now();
    final expiry = now.add(Duration(days: days.value));
    final hardMax = now.add(const Duration(days: 15));
    return RetentionPolicy(
      createdAt: now,
      expiresAt: expiry.isBefore(hardMax) ? expiry : hardMax,
      retentionDays: days.value,
    );
  }

  Map<String, dynamic> toJson() => {
    'created_at': createdAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
    'retention_days': retentionDays,
    'deletion_status': deletionStatus,
  };
}

class QuickReply {
  final String id;
  String text;
  String category;
  bool favorite;

  QuickReply({
    required this.id,
    required this.text,
    required this.category,
    this.favorite = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'category': category,
    'favorite': favorite,
  };

  factory QuickReply.fromJson(Map<String, dynamic> json) => QuickReply(
    id:
        json['id'] as String? ??
        DateTime.now().microsecondsSinceEpoch.toString(),
    text: json['text'] as String? ?? '',
    category: json['category'] as String? ?? 'Custom',
    favorite: json['favorite'] as bool? ?? false,
  );
}

class TranscriptLine {
  final String speaker;
  final String text;
  final DateTime timestamp;

  TranscriptLine({
    required this.speaker,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'speaker': speaker,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TranscriptLine.fromJson(Map<String, dynamic> json) => TranscriptLine(
    speaker: json['speaker'] as String? ?? 'Speaker',
    text: json['text'] as String? ?? '',
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
  );
}

class ProfessionalInsights {
  final String summary;
  final List<String> vocabulary;
  final List<String> difficultTerms;
  final List<String> themes;
  final List<String> actionItems;
  final List<String> deadlines;
  final List<String> mentionedPeople;

  const ProfessionalInsights({
    required this.summary,
    required this.vocabulary,
    required this.difficultTerms,
    required this.themes,
    required this.actionItems,
    required this.deadlines,
    required this.mentionedPeople,
  });
}

class ProfessionalRecord {
  final String id;
  String title;
  SessionType type;
  String folder;
  CaptionLanguage language;
  RetentionPolicy retention;
  DateTime? startedAt;
  DateTime? stoppedAt;
  List<TranscriptLine> transcript;
  ProfessionalInsights? insights;
  String deletionStatus;

  ProfessionalRecord({
    required this.id,
    required this.title,
    required this.type,
    required this.folder,
    required this.language,
    required this.retention,
    this.startedAt,
    this.stoppedAt,
    List<TranscriptLine>? transcript,
    this.insights,
    this.deletionStatus = 'active',
  }) : transcript = transcript ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'folder': folder,
    'caption_language': language.name,
    'retention': retention.toJson(),
    'created_at': retention.createdAt.toIso8601String(),
    'expires_at': retention.expiresAt.toIso8601String(),
    'retention_days': retention.retentionDays,
    'deletion_status': deletionStatus,
    'started_at': startedAt?.toIso8601String(),
    'stopped_at': stoppedAt?.toIso8601String(),
    'transcript': transcript.map((line) => line.toJson()).toList(),
    // Deliberately no audio field: raw audio is never persistent.
  };

  factory ProfessionalRecord.fromJson(Map<String, dynamic> json) {
    final retentionJson = (json['retention'] as Map?)?.cast<String, dynamic>();
    final created =
        DateTime.tryParse(
          (retentionJson?['created_at'] ?? json['created_at'] ?? '') as String,
        ) ??
        DateTime.now();
    final expires =
        DateTime.tryParse(
          (retentionJson?['expires_at'] ?? json['expires_at'] ?? '') as String,
        ) ??
        created.add(const Duration(days: 7));
    return ProfessionalRecord(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Untitled session',
      type: SessionType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => SessionType.meeting,
      ),
      folder: json['folder'] as String? ?? 'General',
      language: CaptionLanguage.values.firstWhere(
        (value) => value.name == json['caption_language'],
        orElse: () => CaptionLanguage.auto,
      ),
      retention: RetentionPolicy(
        createdAt: created,
        expiresAt: expires,
        retentionDays:
            (retentionJson?['retention_days'] ?? json['retention_days'] ?? 7)
                as int,
        deletionStatus: json['deletion_status'] as String? ?? 'active',
      ),
      startedAt: DateTime.tryParse(json['started_at'] as String? ?? ''),
      stoppedAt: DateTime.tryParse(json['stopped_at'] as String? ?? ''),
      transcript: ((json['transcript'] as List?) ?? const [])
          .whereType<Map>()
          .map((line) => TranscriptLine.fromJson(line.cast<String, dynamic>()))
          .toList(),
      deletionStatus: json['deletion_status'] as String? ?? 'active',
    );
  }
}

abstract class SpeechToTextProvider {
  String get id;
  bool supports(CaptionLanguage language, bool online);
  Future<void> start({required CaptionLanguage language});
  Future<void> stop();
}

abstract class TtsProvider {
  String get id;
  bool supports(CaptionLanguage language);
  Future<void> speak(String text, CaptionLanguage language);
}

abstract class SoundDetectionProvider {
  String get id;
  Future<void> start();
  Future<void> stop();
}

abstract class SummarizationProvider {
  Future<ProfessionalInsights> generate(List<TranscriptLine> transcript);
}

class AndroidSpeechProvider implements SpeechToTextProvider {
  static const channel = MethodChannel('humsukhan/native');
  @override
  String get id => 'android-platform-speech-recognizer';
  @override
  bool supports(CaptionLanguage language, bool online) => true;
  @override
  Future<void> start({required CaptionLanguage language}) async {
    final locale = switch (language) {
      CaptionLanguage.urduScript => 'ur-PK',
      CaptionLanguage.romanUrdu => 'en-PK',
      _ => 'en-US',
    };
    await channel.invokeMethod('speechStart', {'locale': locale});
  }

  @override
  Future<void> stop() => channel.invokeMethod('speechStop');
}

class AndroidTtsProvider implements TtsProvider {
  static const channel = MethodChannel('humsukhan/native');
  @override
  String get id => 'android-platform-text-to-speech';
  @override
  bool supports(CaptionLanguage language) => language != CaptionLanguage.auto;
  @override
  Future<void> speak(String text, CaptionLanguage language) =>
      channel.invokeMethod('ttsSpeak', {
        'text': text,
        'language': language == CaptionLanguage.urduScript ? 'ur' : 'en',
      });
}

class LocalSoundDetectionProvider implements SoundDetectionProvider {
  static const channel = MethodChannel('humsukhan/native');
  @override
  String get id => 'android-audio-activity-monitor';
  @override
  Future<void> start() => channel.invokeMethod('soundMonitoringStart');
  @override
  Future<void> stop() => channel.invokeMethod('soundMonitoringStop');
}

class LocalSummarizationProvider implements SummarizationProvider {
  static const _stopWords = {
    'about',
    'after',
    'again',
    'also',
    'could',
    'from',
    'have',
    'into',
    'just',
    'more',
    'need',
    'only',
    'please',
    'should',
    'that',
    'their',
    'there',
    'these',
    'they',
    'this',
    'through',
    'very',
    'were',
    'what',
    'when',
    'where',
    'which',
    'with',
    'would',
    'your',
    'okay',
    'understand',
  };

  @override
  Future<ProfessionalInsights> generate(List<TranscriptLine> transcript) async {
    final lines = transcript
        .map((line) => line.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    final source = lines.join(' ');
    final tokens = source
        .split(RegExp(r'[^\p{L}\p{N}\-]+', unicode: true))
        .map((word) => word.toLowerCase().trim())
        .where((word) => word.length >= 5 && !_stopWords.contains(word))
        .toList();
    final counts = <String, int>{};
    for (final token in tokens) counts[token] = (counts[token] ?? 0) + 1;
    final vocabulary = counts.entries.toList()
      ..sort(
        (a, b) => b.value != a.value
            ? b.value.compareTo(a.value)
            : a.key.compareTo(b.key),
      );
    final actionItems = lines
        .where(
          (line) => RegExp(
            r'\b(need to|should|must|action|follow up|next step|please|remember to)\b',
            caseSensitive: false,
          ).hasMatch(line),
        )
        .take(5)
        .toList();
    final deadlines = lines
        .where(
          (line) => RegExp(
            r'\b(today|tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday|by \w+|\d{1,2}[:/]\d{1,2})\b',
            caseSensitive: false,
          ).hasMatch(line),
        )
        .take(5)
        .toList();
    final people = <String>[];
    for (final line in lines) {
      for (final match in RegExp(
        r'\b(?:Mr|Ms|Mrs|Dr)\.?\s+[A-Z][a-z]+',
      ).allMatches(line)) {
        if (!people.contains(match.group(0))) people.add(match.group(0)!);
      }
    }
    final summary = lines.isEmpty
        ? 'No transcript was captured.'
        : 'Captured ${lines.length} sentence${lines.length == 1 ? '' : 's'} across ${transcript.map((line) => line.speaker).toSet().length} speaker role${transcript.map((line) => line.speaker).toSet().length == 1 ? '' : 's'}. ${lines.take(2).join(' ')}';
    return ProfessionalInsights(
      summary: summary,
      vocabulary: vocabulary.isEmpty
          ? ['No repeated vocabulary detected']
          : vocabulary.take(8).map((entry) => entry.key).toList(),
      difficultTerms: vocabulary.take(3).map((entry) => entry.key).toList(),
      themes: [
        if (lines.any((line) => line.toLowerCase().contains('class'))) 'Class',
        if (lines.any((line) => line.toLowerCase().contains('meeting')))
          'Meeting',
        'Communication',
      ],
      actionItems: actionItems.isEmpty
          ? ['No explicit action item detected; review the transcript manually.']
          : actionItems,
      deadlines: deadlines.isEmpty
          ? ['No explicit deadline detected.']
          : deadlines,
      mentionedPeople: people.isEmpty
          ? ['No named person confidently detected.']
          : people,
    );
  }
}

class LocalStore {
  static const channel = MethodChannel('humsukhan/storage');
  final Map<String, String> _fallback = {};

  Future<String?> get(String key) async {
    try {
      return await channel.invokeMethod<String>('get', {'key': key});
    } catch (_) {
      return _fallback[key];
    }
  }

  Future<void> set(String key, String value) async {
    _fallback[key] = value;
    try {
      await channel.invokeMethod('set', {'key': key, 'value': value});
    } catch (_) {}
  }
}

class CapabilityRouter {
  final SpeechToTextProvider Function() speech;
  final TtsProvider tts;
  final SoundDetectionProvider sound;

  const CapabilityRouter({
    required this.speech,
    required this.tts,
    required this.sound,
  });

  String status(
    Capability capability, {
    bool online = true,
    CaptionLanguage language = CaptionLanguage.auto,
  }) {
    final currentSpeech = speech();
    return switch (capability) {
      Capability.speechRecognition =>
        currentSpeech.supports(language, online)
            ? 'Available • ${currentSpeech.id}'
            : 'Unavailable for ${language.label}; choose another language',
      Capability.textToSpeech =>
        tts.supports(language)
            ? 'Available • ${tts.id}'
            : 'Select a supported language',
      Capability.aiInsights =>
        online
            ? 'Available • local deterministic insight provider'
            : 'Available for saved transcript review',
      Capability.soundDetection =>
        'Architecture ready • detector availability is device-dependent',
    };
  }
}

class PslRecognitionProvider {
  static const repository = 'github.com/AbdulMueez456/handlytics';
  static const modelDescription = 'Pakistan Sign Language word/sentence ConvLSTM reference';
  String get status => 'PSL reference selected; mobile inference weights are not bundled in this build';
}

class AppController extends ChangeNotifier {
  final LocalStore store = LocalStore();

  AppController() {
    sherpaSpeechProvider.setListeners(
      onPartial: (text) => handleOfflineSpeechEvent(text: text, isFinal: false),
      onFinal: (text) => handleOfflineSpeechEvent(text: text, isFinal: true),
      onStatus: handleOfflineSpeechStatus,
      onError: handleOfflineSpeechError,
    );
  }
  final AndroidSpeechProvider platformSpeechProvider = AndroidSpeechProvider();
  final SherpaOnnxSpeechProvider sherpaSpeechProvider = SherpaOnnxSpeechProvider();
  final TtsProvider ttsProvider = AndroidTtsProvider();
  SpeechToTextProvider? _activeSpeechProvider;
  final SoundDetectionProvider soundProvider = LocalSoundDetectionProvider();
  final SummarizationProvider summarizationProvider =
      LocalSummarizationProvider();
  final PslRecognitionProvider pslProvider = PslRecognitionProvider();
  late final CapabilityRouter capabilityRouter = CapabilityRouter(
    speech: () => speechProvider,
    tts: ttsProvider,
    sound: soundProvider,
  );

  final List<QuickReply> quickReplies = [
    QuickReply(id: 'hello', text: 'Hello', category: 'Conversation'),
    QuickReply(id: 'thanks', text: 'Thank you', category: 'Conversation'),
    QuickReply(id: 'wait', text: 'Please wait', category: 'Conversation'),
    QuickReply(
      id: 'repeat',
      text: 'Please repeat that',
      category: 'Conversation',
    ),
    QuickReply(id: 'type', text: 'Please type it', category: 'Conversation'),
    QuickReply(
      id: 'understand',
      text: 'I did not understand',
      category: 'Conversation',
    ),
    QuickReply(id: 'yes', text: 'Yes', category: 'Response'),
    QuickReply(id: 'no', text: 'No', category: 'Response'),
    QuickReply(id: 'moment', text: 'One moment, please', category: 'Response'),
    QuickReply(id: 'help', text: 'I need help', category: 'Response'),
  ];
  final List<ProfessionalRecord> records = [];
  final List<String> folders = ['General', 'Classes', 'Meetings'];
  final List<TranscriptLine> liveTranscript = [];
  final List<String> liveCaptions = [];
  final List<String> soundAlerts = [];
  String? livePartialCaption;

  ConversationState conversationState = ConversationState.idle;
  bool onboardingComplete = false;
  bool online = true;
  bool highContrast = false;
  bool largeText = false;
  bool darkMode = false;
  bool hapticAlerts = true;
  bool visualAlerts = true;
  bool flashAlerts = false;
  bool screenFlashAlerts = true;
  bool flashlightAlerts = false;
  bool environmentalAlertsEnabled = false;
  bool hazardVisible = false;
  String? activeHazardType;
  String hazardColorName = 'blue';
  CaptionLanguage captionLanguage = CaptionLanguage.auto;
  String detectedLanguage = 'Ready';
  ProfessionalRecord? activeRecord;
  String? nativeError;
  DateTime? _lastSoundAlert;
  bool microphoneListening = false;
  String? suggestedResponseText;
  String localDisplayName = '';
  String localUsername = '';
  String localEmail = '';
  LocalGender localGender = LocalGender.preferNotToSay;
  String localAvatar = 'person';
  bool localCredentialConfigured = false;
  bool localLoginComplete = false;
  bool preferOfflineSpeech = true;

  SpeechToTextProvider get speechProvider => preferOfflineSpeech
      ? sherpaSpeechProvider
      : platformSpeechProvider;

  String get tutorAsset => localGender == LocalGender.female
      ? 'assets/tutor_female_transparent.png'
      : 'assets/tutor_male_transparent.png';

  String get tutorName => localGender == LocalGender.female
      ? 'Ayesha, your HumSukhan guide'
      : 'Hamza, your HumSukhan guide';
  String? settingsMessage;

  final detectorTypes = [
    'fire alarm',
    'siren',
    'doorbell',
    'knock',
    'police or ambulance',
  ];

  Future<void> load() async {
    onboardingComplete = (await store.get('onboarding_complete')) == 'true';
    final settingsJson = await store.get('settings');
    if (settingsJson != null) {
      try {
        final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
        highContrast = settings['high_contrast'] as bool? ?? false;
        largeText = settings['large_text'] as bool? ?? false;
        darkMode = settings['dark_mode'] as bool? ?? false;
        hapticAlerts = settings['haptic_alerts'] as bool? ?? true;
        visualAlerts = settings['visual_alerts'] as bool? ?? true;
        flashAlerts = settings['flash_alerts'] as bool? ?? false;
        screenFlashAlerts = settings['screen_flash_alerts'] as bool? ?? true;
        flashlightAlerts = settings['flashlight_alerts'] as bool? ?? false;
        preferOfflineSpeech = settings['prefer_offline_speech'] as bool? ?? true;
      } catch (_) {}
    }
    final profileJson = await store.get('local_profile');
    if (profileJson != null) {
      try {
        final profile = jsonDecode(profileJson) as Map<String, dynamic>;
        localDisplayName = profile['display_name'] as String? ?? '';
        localUsername = profile['username'] as String? ?? '';
        localEmail = profile['email'] as String? ?? '';
        localGender = _genderFromStored(profile['gender'] as String?);
        localAvatar = profile['avatar'] as String? ?? 'person';
        localCredentialConfigured =
            profile['credential_configured'] as bool? ?? false;
        localLoginComplete = profile['login_complete'] as bool? ??
            (localCredentialConfigured && localEmail.isNotEmpty);
      } catch (_) {}
    }
    final quickRepliesJson = await store.get('quick_replies');
    if (quickRepliesJson != null) {
      try {
        final list = jsonDecode(quickRepliesJson) as List;
        quickReplies
          ..clear()
          ..addAll(
            list.whereType<Map>().map(
              (item) => QuickReply.fromJson(item.cast<String, dynamic>()),
            ),
          );
      } catch (_) {}
    }
    final foldersJson = await store.get('professional_folders');
    if (foldersJson != null) {
      try {
        final list = jsonDecode(foldersJson) as List;
        folders
          ..clear()
          ..addAll(
            list
                .whereType<String>()
                .map((name) => name.trim())
                .where((name) => name.isNotEmpty),
          );
      } catch (_) {}
    }
    for (final name in ['General', 'Classes', 'Meetings']) {
      if (!folders.contains(name)) folders.add(name);
    }
    final recordsJson = await store.get('professional_records');
    if (recordsJson != null) {
      try {
        final list = jsonDecode(recordsJson) as List;
        records.addAll(
          list.whereType<Map>().map(
            (record) =>
                ProfessionalRecord.fromJson(record.cast<String, dynamic>()),
          ),
        );
      } catch (_) {}
    }
    evaluateRetention();
  }

  Future<void> addQuickReply(String text, String category) async {
    quickReplies.add(
      QuickReply(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        category: category,
      ),
    );
    await store.set(
      'quick_replies',
      jsonEncode(quickReplies.map((reply) => reply.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> addFolder(String name) async {
    final clean = name.trim();
    if (clean.isEmpty ||
        folders.any((folder) => folder.toLowerCase() == clean.toLowerCase()))
      return;
    folders.add(clean);
    await persistFolders();
    notifyListeners();
  }

  Future<void> persistFolders() async {
    await store.set('professional_folders', jsonEncode(folders));
  }

  Future<bool> deleteFolder(String name) async {
    const defaults = {'General', 'Classes', 'Meetings'};
    if (defaults.contains(name) || !folders.contains(name)) return false;
    for (final record in records) {
      if (record.folder == name) record.folder = 'General';
    }
    folders.remove(name);
    await persistFolders();
    await persistRecords();
    notifyListeners();
    return true;
  }

  void openRecord(ProfessionalRecord record) {
    activeRecord = record;
    notifyListeners();
  }

  Future<void> deleteProfessionalRecord(ProfessionalRecord record) async {
    records.removeWhere((item) => item.id == record.id);
    if (activeRecord?.id == record.id) activeRecord = null;
    await persistRecords();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboardingComplete = true;
    await store.set('onboarding_complete', 'true');
    notifyListeners();
  }

  Future<void> saveLocalAccount({
    required String email,
    required String username,
    required String password,
    required LocalGender gender,
    String? displayName,
  }) async {
    final cleanEmail = email.trim();
    final cleanUsername = username.trim();
    final cleanDisplayName = (displayName ?? cleanUsername).trim();
    localEmail = cleanEmail;
    localUsername = cleanUsername;
    localDisplayName = cleanDisplayName.isEmpty ? cleanUsername : cleanDisplayName;
    localGender = gender;
    localAvatar = gender == LocalGender.female ? 'face' : 'person';
    // Only a salted digest is retained; the plaintext password never enters the store.
    final digest = sha256.convert(utf8.encode('humsukhan-local-v1:$cleanEmail:$password')).toString();
    localCredentialConfigured = password.trim().isNotEmpty;
    localLoginComplete = true;
    await store.set(
      'local_profile',
      jsonEncode({
        'display_name': localDisplayName,
        'username': localUsername,
        'email': localEmail,
        'gender': localGender.name,
        'avatar': localAvatar,
        'credential_configured': localCredentialConfigured,
        'credential_digest': digest,
        'login_complete': localLoginComplete,
      }),
    );
    notifyListeners();
  }

  Future<void> saveLocalProfile({
    required String displayName,
    required String username,
    required String avatar,
    required bool credentialConfigured,
  }) async {
    localDisplayName = displayName.trim();
    localUsername = username.trim();
    localAvatar = avatar;
    localCredentialConfigured = credentialConfigured;
    await store.set(
      'local_profile',
      jsonEncode({
        'display_name': localDisplayName,
        'username': localUsername,
        'email': localEmail,
        'gender': localGender.name,
        'avatar': localAvatar,
        'credential_configured': localCredentialConfigured,
        'login_complete': localLoginComplete,
      }),
    );
    notifyListeners();
  }

  Future<void> saveSettings() async {
    await store.set(
      'settings',
      jsonEncode({
        'high_contrast': highContrast,
        'large_text': largeText,
        'dark_mode': darkMode,
        'haptic_alerts': hapticAlerts,
        'visual_alerts': visualAlerts,
        'flash_alerts': flashAlerts,
        'screen_flash_alerts': screenFlashAlerts,
        'flashlight_alerts': flashlightAlerts,
        'prefer_offline_speech': preferOfflineSpeech,
      }),
    );
    notifyListeners();
  }

  void setOnline(bool value) {
    online = value;
    notifyListeners();
  }

  void setLanguage(CaptionLanguage value) {
    captionLanguage = value;
    notifyListeners();
  }

  Future<void> startConversation() async {
    if (conversationState != ConversationState.idle) return;
    nativeError = null;
    conversationState = ConversationState.starting;
    liveCaptions.clear();
    liveTranscript.clear();
    livePartialCaption = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    conversationState = ConversationState.active;
    liveCaptions.add(
      'Listening is active. Speak clearly; audio is processed temporarily and released.',
    );
    notifyListeners();
    // Starting the conversation also starts the microphone. It remains active
    // until the user explicitly stops the conversation.
    await startNativeSpeech();
  }

  Future<void> startNativeSpeech() async {
    final professionalLive =
        activeRecord != null &&
        activeRecord!.startedAt != null &&
        activeRecord!.stoppedAt == null;
    final everydayLive = conversationState == ConversationState.active;
    if (!professionalLive && !everydayLive) return;
    nativeError = null;
    final language = professionalLive
        ? activeRecord!.language
        : captionLanguage;
    final provider = speechProvider;
    if (!provider.supports(language, online)) {
      nativeError = capabilityRouter.status(
        Capability.speechRecognition,
        online: online,
        language: language,
      );
      notifyListeners();
      if (provider == sherpaSpeechProvider) {
        await _startPlatformSpeechFallback(language);
      }
      return;
    }
    try {
      await provider.start(language: language);
      _activeSpeechProvider = provider;
    } on UnsupportedError catch (error) {
      nativeError = error.message?.toString() ?? 'This speech language is unavailable offline.';
      notifyListeners();
      if (provider == sherpaSpeechProvider) {
        await _startPlatformSpeechFallback(language);
      }
    } on PlatformException catch (error) {
      nativeError = error.message ?? 'Speech recognition is unavailable on this device.';
      notifyListeners();
      if (provider == sherpaSpeechProvider) {
        await _startPlatformSpeechFallback(language);
      }
    } catch (error) {
      nativeError = 'Offline speech could not start: $error';
      notifyListeners();
      if (provider == sherpaSpeechProvider) {
        await _startPlatformSpeechFallback(language);
      }
    }
  }

  Future<void> _startPlatformSpeechFallback(CaptionLanguage language) async {
    try {
      await platformSpeechProvider.start(language: language);
      _activeSpeechProvider = platformSpeechProvider;
      nativeError = 'Using Android speech fallback.';
      notifyListeners();
    } catch (error) {
      nativeError = 'Speech recognition could not start: $error';
      notifyListeners();
    }
  }

  Future<void> stopNativeSpeech() async {
    try {
      await (_activeSpeechProvider ?? speechProvider).stop();
    } catch (_) {}
    _activeSpeechProvider = null;
  }

  void handleOfflineSpeechEvent({required String text, required bool isFinal}) {
    if (isFinal) {
      handleNativeMethod(MethodCall('speechFinal', text));
    } else {
      handleNativeMethod(MethodCall('speechPartial', text));
    }
  }

  void handleOfflineSpeechStatus(String status) {
    handleNativeMethod(MethodCall('speechStatus', status));
  }

  void handleOfflineSpeechError(String error) {
    handleNativeMethod(MethodCall('speechError', error));
  }

  void setPreferOfflineSpeech(bool value) {
    preferOfflineSpeech = value;
    saveSettings();
  }

  void handleNativeMethod(MethodCall call) {
    switch (call.method) {
      case 'speechPartial':
        final partial = cleanCaption(call.arguments as String? ?? '');
        final professionalLive =
            activeRecord != null &&
            activeRecord!.startedAt != null &&
            activeRecord!.stoppedAt == null;
        if (partial.isNotEmpty &&
            (conversationState == ConversationState.active ||
                professionalLive)) {
          // Keep one evolving sentence rather than appending every word as a new bubble.
          livePartialCaption = partial;
          notifyListeners();
        }
        break;
      case 'speechStatus':
        microphoneListening =
            call.arguments == 'listening' || call.arguments == 'ready';
        notifyListeners();
      case 'speechFinal':
        final text = cleanCaption(call.arguments as String? ?? '');
        final professionalLive =
            activeRecord != null &&
            activeRecord!.startedAt != null &&
            activeRecord!.stoppedAt == null;
        if (text.isEmpty) break;
        if (conversationState == ConversationState.active || professionalLive) {
          livePartialCaption = null;
          _appendSpeakerCaption(text);
          detectedLanguage = detectLanguage(text);
          if (conversationState == ConversationState.active) {
            suggestedResponseText = suggestedResponse(text);
          }
          if (professionalLive) {
            activeRecord!.transcript = List.of(liveTranscript);
            persistRecords();
          }
          notifyListeners();
        }
      case 'speechError':
        microphoneListening = false;
        nativeError =
            call.arguments as String? ?? 'Speech recognition is unavailable.';
        notifyListeners();
      case 'environmentSoundActivity':
        final confidence =
            double.tryParse(call.arguments as String? ?? '') ?? 0.0;
        handleEnvironmentActivity(confidence);
      default:
        break;
    }
  }

  String detectLanguage(String text) {
    final romanUrduHints = RegExp(
      r'\b(aap|kal|mein|mujhe|kya|hai|hain|kar|karenge|please|nahin|shukriya)\b',
      caseSensitive: false,
    );
    if (romanUrduHints.hasMatch(text)) return 'Roman Urdu detected';
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(text))
      return 'Urdu script detected';
    return 'English detected';
  }

  String cleanCaption(String input) {
    var text = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    text = text.replaceAll(
      RegExp(r'^(um+|uh+|erm|hmm|you know)[, ]*', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'[, ]+(um+|uh+|erm|hmm|you know)(?=[,.!? ]|$)',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(r'\b(um+|uh+|erm|hmm)\b', caseSensitive: false),
      '',
    );
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  void _appendSpeakerCaption(String clean) {
    if (liveTranscript.isNotEmpty &&
        liveTranscript.last.speaker == 'Speaker' &&
        liveTranscript.last.text.trim().toLowerCase() == clean.trim().toLowerCase()) {
      return;
    }
    liveTranscript.add(TranscriptLine(speaker: 'Speaker', text: clean));
  }

  void setReplyPreview(String text) {
    final clean = cleanCaption(text);
    if (clean.isEmpty) return;
    suggestedResponseText = clean;
    notifyListeners();
  }

  Future<void> sendReply(String text, {bool speak = false}) async {
    final clean = cleanCaption(text);
    if (clean.isEmpty || conversationState != ConversationState.active) return;
    if (liveTranscript.isEmpty ||
        liveTranscript.last.text != clean ||
        liveTranscript.last.speaker != 'Responder') {
      liveTranscript.add(TranscriptLine(speaker: 'Responder', text: clean));
    }
    suggestedResponseText = null;
    notifyListeners();
    if (speak) await this.speak(clean);
  }

  String suggestedResponse(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('thank')) return 'You are welcome.';
    if (lower.contains('hello') || lower.contains('hi'))
      return 'Hello. How can I help?';
    if (lower.contains('repeat')) return 'Of course. I will repeat that.';
    return 'Okay, I understand.';
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    final language = captionLanguage == CaptionLanguage.auto
        ? CaptionLanguage.english
        : captionLanguage;
    if (!ttsProvider.supports(language)) {
      nativeError = capabilityRouter.status(
        Capability.textToSpeech,
        language: language,
      );
      notifyListeners();
      return;
    }
    try {
      await ttsProvider.speak(text, language);
    } on PlatformException catch (error) {
      nativeError =
          error.message ?? 'Text-to-speech is unavailable on this device.';
      notifyListeners();
    }
  }

  Future<void> requestStopConversation() async {
    if (conversationState != ConversationState.active) return;
    conversationState = ConversationState.stopping;
    await stopNativeSpeech();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    // Everyday conversations are intentionally ephemeral. Professional
    // sessions remain the explicit persistence path.
    resetConversation();
  }

  void resetConversation() {
    conversationState = ConversationState.idle;
    liveTranscript.clear();
    liveCaptions.clear();
    nativeError = null;
    microphoneListening = false;
    suggestedResponseText = null;
    livePartialCaption = null;
    notifyListeners();
  }

  Future<void> createProfessionalSession({
    required String title,
    required SessionType type,
    required String folder,
    required CaptionLanguage language,
    required RetentionDays retention,
  }) async {
    final record = ProfessionalRecord(
      id: 'session-${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim().isEmpty ? 'Untitled session' : title.trim(),
      type: type,
      folder: folder.trim().isEmpty ? 'General' : folder.trim(),
      language: language,
      retention: RetentionPolicy.create(retention),
    );
    records.insert(0, record);
    activeRecord = record;
    await persistRecords();
    notifyListeners();
  }

  Future<void> startProfessionalSession() async {
    final record = activeRecord;
    if (record == null || record.startedAt != null || record.stoppedAt != null)
      return;
    captionLanguage = record.language;
    record.startedAt = DateTime.now();
    liveCaptions.clear();
    liveTranscript.clear();
    livePartialCaption = null;
    await persistRecords();
    notifyListeners();
    await startNativeSpeech();
  }

  Future<void> addProfessionalCaption(String text) async {
    final record = activeRecord;
    if (record == null || record.startedAt == null || record.stoppedAt != null)
      return;
    final clean = cleanCaption(text);
    if (clean.isEmpty) return;
    _appendSpeakerCaption(clean);
    record.transcript = List.of(liveTranscript);
    await persistRecords();
    notifyListeners();
  }

  Future<void> stopProfessionalSession() async {
    final record = activeRecord;
    if (record == null || record.startedAt == null || record.stoppedAt != null)
      return;
    await stopNativeSpeech();
    record.stoppedAt = DateTime.now();
    record.transcript = List.of(liveTranscript);
    record.insights = await summarizationProvider.generate(record.transcript);
    await persistRecords();
    notifyListeners();
  }

  Future<void> generateInsightsForActiveRecord() async {
    final record = activeRecord;
    if (record == null || record.stoppedAt == null) return;
    record.insights = await summarizationProvider.generate(record.transcript);
    await persistRecords();
    notifyListeners();
  }

  Future<void> closeProfessionalDetail() async {
    activeRecord = null;
    liveCaptions.clear();
    liveTranscript.clear();
    notifyListeners();
  }

  Future<void> persistRecords() async {
    await store.set(
      'professional_records',
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }

  void evaluateRetention() {
    final now = DateTime.now();
    records.removeWhere(
      (record) =>
          record.deletionStatus == 'deleted' ||
          record.retention.expiresAt.isBefore(now),
    );
  }

  Future<void> enforceRetention() async {
    final before = records.length;
    evaluateRetention();
    final removed = before - records.length;
    if (removed > 0) await persistRecords();
    settingsMessage = removed == 0
        ? 'Retention checked. No records were ready to expire.'
        : 'Retention checked. $removed expired record${removed == 1 ? '' : 's'} removed.';
    notifyListeners();
  }

  Future<void> enableEnvironmentalAlerts(bool enabled) async {
    environmentalAlertsEnabled = enabled;
    if (enabled) {
      try {
        await soundProvider.start();
        nativeError = null;
      } on PlatformException catch (error) {
        environmentalAlertsEnabled = false;
        nativeError =
            error.message ??
            'Microphone monitoring is unavailable on this device.';
      }
    } else {
      await soundProvider.stop();
      await dismissHazard();
    }
    notifyListeners();
  }

  void handleEnvironmentActivity(double confidence) {
    if (!environmentalAlertsEnabled) return;
    emitSoundEvent('environmental activity', confidence);
  }

  Future<bool> emitSoundEvent(String type, double confidence) async {
    if (!environmentalAlertsEnabled || confidence < 0.55) return false;
    final now = DateTime.now();
    if (_lastSoundAlert != null &&
        now.difference(_lastSoundAlert!) < const Duration(seconds: 8))
      return false;
    _lastSoundAlert = now;
    final title = _titleCase(type);
    final event = type == 'environmental activity'
        ? 'Environmental activity detected • ${_time(now)}'
        : 'Test alert: $title • ${_time(now)}';
    soundAlerts.insert(0, event);
    activeHazardType = type;
    hazardColorName = type == 'fire alarm' ? 'red' : 'blue';
    hazardVisible = true;
    if (flashlightAlerts) {
      try {
        await AndroidTtsProvider.channel.invokeMethod('flashlight', {
          'enabled': true,
        });
        Future<void>.delayed(const Duration(milliseconds: 1600), () async {
          try {
            await AndroidTtsProvider.channel.invokeMethod('flashlight', {
              'enabled': false,
            });
          } catch (_) {}
        });
      } catch (_) {}
    }
    if (hapticAlerts) {
      try {
        await AndroidTtsProvider.channel.invokeMethod('hapticAlert');
      } catch (_) {}
    }
    notifyListeners();
    return true;
  }

  Future<void> clearSoundAlerts() async {
    soundAlerts.clear();
    await dismissHazard();
    notifyListeners();
  }

  Future<void> dismissHazard() async {
    hazardVisible = false;
    activeHazardType = null;
    try {
      await AndroidTtsProvider.channel.invokeMethod('flashlight', {
        'enabled': false,
      });
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> runSafeTestEvent(String type) async {
    _lastSoundAlert = null;
    return emitSoundEvent(type, 0.91);
  }

  Future<void> shareTxtFile(ProfessionalRecord record) async {
    final content = exportText(record);
    try {
      await AndroidSpeechProvider.channel.invokeMethod('shareTextFile', {
        'fileName':
            '${record.title.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')}.txt',
        'content': content,
      });
    } on PlatformException catch (error) {
      nativeError =
          error.message ?? 'TXT sharing is unavailable on this device.';
      notifyListeners();
    }
  }

  String _time(DateTime value) => '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String exportText(ProfessionalRecord record) {
    final buffer = StringBuffer()
      ..writeln('HumSukhan export')
      ..writeln('Session: ${record.title}')
      ..writeln('Type: ${record.type.label}')
      ..writeln('Date: ${_dateTime(record.retention.createdAt)}')
      ..writeln('\nTranscript');
    for (final line in record.transcript) {
      buffer.writeln('${line.speaker}: ${line.text}');
    }
    final insights = record.insights;
    if (insights != null) {
      buffer
        ..writeln('\nSummary')
        ..writeln(insights.summary)
        ..writeln('\nVocabulary')
        ..writeln(insights.vocabulary.join(', '))
        ..writeln('\nThemes')
        ..writeln(insights.themes.join(', '))
        ..writeln('\nAction items')
        ..writeln(insights.actionItems.join('\n'))
        ..writeln('\nAI-generated — may contain errors');
    }
    return buffer.toString();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  await controller.load();
  try {
    AndroidSpeechProvider.channel.setMethodCallHandler(
      (call) async => controller.handleNativeMethod(call),
    );
  } catch (_) {}
  runApp(HumSukhanApp(controller: controller));
}

class HumSukhanApp extends StatelessWidget {
  final AppController controller;
  const HumSukhanApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final baseScheme = controller.darkMode
            ? _darkBrandScheme()
            : _lightBrandScheme();
        final scheme = controller.highContrast
            ? baseScheme.copyWith(
                onSurface: controller.darkMode ? Colors.white : Colors.black,
                onSurfaceVariant: controller.darkMode
                    ? Colors.white
                    : Colors.black,
                outline: controller.darkMode
                    ? _brandAccentDark
                    : _brandTextLight,
              )
            : baseScheme;
        final theme = ThemeData(
          useMaterial3: true,
          fontFamily: 'Atkinson Hyperlegible',
          textTheme: const TextTheme(
            displaySmall: TextStyle(
              fontSize: 34,
              height: 1.12,
              fontWeight: FontWeight.w800,
            ),
            headlineMedium: TextStyle(
              fontSize: 28,
              height: 1.16,
              fontWeight: FontWeight.w800,
            ),
            headlineSmall: TextStyle(
              fontSize: 24,
              height: 1.18,
              fontWeight: FontWeight.w800,
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
            titleMedium: TextStyle(
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: TextStyle(fontSize: 17, height: 1.45),
            bodyMedium: TextStyle(fontSize: 15, height: 1.42),
            bodySmall: TextStyle(fontSize: 14, height: 1.35),
            labelLarge: TextStyle(
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
            labelMedium: TextStyle(
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          colorScheme: scheme,
          scaffoldBackgroundColor: scheme.surface,
          cardTheme: CardThemeData(
            margin: EdgeInsets.zero,
            color: scheme.surfaceContainerLow,
            elevation: 1,
            shadowColor: scheme.primary.withValues(alpha: 0.08),
            surfaceTintColor: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HKRadius.lg),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.72),
              ),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(
                horizontal: HKSpace.lg,
                vertical: HKSpace.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HKRadius.md),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 50),
              padding: const EdgeInsets.symmetric(
                horizontal: HKSpace.lg,
                vertical: HKSpace.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HKRadius.md),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            height: 72,
            backgroundColor: scheme.surfaceContainerLow,
            indicatorColor: scheme.secondaryContainer,
            labelTextStyle: WidgetStatePropertyAll(
              TextStyle(fontFamily: 'Atkinson Hyperlegible', fontWeight: FontWeight.w700),
            ),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              shape: const CircleBorder(),
            ),
          ),
          chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: scheme.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: scheme.inverseSurface,
            contentTextStyle: TextStyle(
              color: scheme.onInverseSurface,
              fontFamily: 'Atkinson Hyperlegible',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HKRadius.xl),
            ),
          ),
          dividerTheme: DividerThemeData(
            color: scheme.outlineVariant,
            thickness: 1,
          ),
        );
        return MaterialApp(
          title: 'HumSukhan',
          debugShowCheckedModeBanner: false,
          theme: theme,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final scale = controller.largeText ? 1.18 : 1.0;
            return MediaQuery(
              data: media.copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            );
          },
          home: !controller.localLoginComplete
              ? LocalLoginScreen(controller: controller)
              : controller.onboardingComplete
              ? HomeShell(controller: controller)
              : OnboardingScreen(controller: controller),
        );
      },
    );
  }
}

class LocalLoginScreen extends StatefulWidget {
  final AppController controller;
  const LocalLoginScreen({super.key, required this.controller});

  @override
  State<LocalLoginScreen> createState() => _LocalLoginScreenState();
}

class _LocalLoginScreenState extends State<LocalLoginScreen> {
  final email = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  LocalGender gender = LocalGender.preferNotToSay;
  String? error;
  bool saving = false;

  @override
  void dispose() {
    email.dispose();
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> continueToGuide() async {
    final e = email.text.trim();
    final u = username.text.trim();
    final p = password.text;
    setState(() {
      error = e.contains('@') && e.contains('.') && u.length >= 2 && p.length >= 4
          ? null
          : 'Enter a valid email, a username, and a password of at least 4 characters.';
    });
    if (error != null) return;
    setState(() => saving = true);
    await widget.controller.saveLocalAccount(
      email: e,
      username: u,
      password: p,
      gender: gender,
    );
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(HKSpace.xl),
              children: [
                Center(child: _BrandLogo(size: 86)),
                const SizedBox(height: HKSpace.lg),
                Text('Set up HumSukhan', style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center),
                const SizedBox(height: HKSpace.sm),
                Text('Create a private profile for this device. No cloud account or network sign-in is created.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
                const SizedBox(height: HKSpace.xl),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(HKSpace.lg),
                    child: Column(
                      children: [
                        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.alternate_email))),
                        const SizedBox(height: HKSpace.sm),
                        TextField(controller: username, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline))),
                        const SizedBox(height: HKSpace.sm),
                        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', helperText: 'Only a secure digest is kept on this device.', prefixIcon: Icon(Icons.lock_outline))),
                        const SizedBox(height: HKSpace.sm),
                        _DropdownField<LocalGender>(label: 'Gender for your first-start tutor', value: gender, values: LocalGender.values, labelOf: (value) => value.label, onChanged: (value) => setState(() => gender = value)),
                        if (error != null) ...[
                          const SizedBox(height: HKSpace.sm),
                          Align(alignment: Alignment.centerLeft, child: Text(error!, style: TextStyle(color: scheme.error))),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: HKSpace.lg),
                FilledButton.icon(onPressed: saving ? null : continueToGuide, icon: const Icon(Icons.arrow_forward_rounded), label: Text(saving ? 'Saving locally…' : 'Continue to your guide')),
                const SizedBox(height: HKSpace.sm),
                Text('You can edit your local profile later from Settings.', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  final AppController controller;
  const OnboardingScreen({super.key, required this.controller});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController pageController;
  int page = 0;

  final slides = const [
    _OnboardingSlide(
      icon: Icons.waving_hand_outlined,
      title: 'Welcome to HumSukhan',
      text: 'A calm, inclusive companion for conversations, captions, and professional listening.',
      accent: true,
    ),
    _OnboardingSlide(
      icon: Icons.record_voice_over_outlined,
      title: 'Speak → Text',
      text: 'Follow spoken conversations through clear, readable live captions. You decide when listening begins.',
    ),
    _OnboardingSlide(
      icon: Icons.volume_up_outlined,
      title: 'Type → Speech',
      text: 'Write a reply and let HumSukhan speak it aloud in a supported language.',
    ),
    _OnboardingSlide(
      icon: Icons.forum_outlined,
      title: 'Everyday and Professional',
      text: 'Use Everyday Mode for the moment. Use Professional Mode for organized saved transcripts and insights.',
    ),
    _OnboardingSlide(
      icon: Icons.visibility_outlined,
      title: 'Visible support, private by default',
      text: 'Environmental alerts use clear visual and haptic cues. Professional records expire within 15 days. Raw audio is never saved.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> finish() => widget.controller.completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last = page == slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                HKSpace.lg,
                HKSpace.lg,
                HKSpace.lg,
                HKSpace.md,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BrandLogo(size: 48),
                      TextButton(onPressed: finish, child: const Text('Skip')),
                    ],
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: slides.length,
                      onPageChanged: (value) => setState(() => page = value),
                      itemBuilder: (context, index) =>
                          _OnboardingSlideView(
                            slide: slides[index],
                            tutorAsset: widget.controller.tutorAsset,
                            tutorName: widget.controller.tutorName,
                          ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: index == page ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: index == page
                              ? scheme.primary
                              : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: HKSpace.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        if (last) {
                          await finish();
                        } else {
                          await pageController.nextPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      icon: Icon(
                        last ? Icons.check : Icons.arrow_forward_rounded,
                      ),
                      label: Text(last ? 'Get Started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String text;
  final bool accent;
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.text,
    this.accent = false,
  });
}

class _OnboardingSlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  final String tutorAsset;
  final String tutorName;
  const _OnboardingSlideView({
    required this.slide,
    required this.tutorAsset,
    required this.tutorName,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: HKSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 168,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(HKSpace.md),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(HKRadius.lg),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tutorName, style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: HKSpace.xs),
                          Text(
                            'I will point out what matters on this screen.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 156,
                    height: 168,
                    child: Image.asset(tutorAsset, fit: BoxFit.contain),
                  ),
                ],
              ),
            ),
            const SizedBox(height: HKSpace.lg),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
                borderRadius: BorderRadius.circular(HKRadius.lg),
              ),
              child: Icon(slide.icon, size: 36, color: scheme.onPrimary),
            ),
            const SizedBox(height: HKSpace.lg),
            Text(slide.title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: HKSpace.md),
            Text(
              slide.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: HKSpace.lg),
            if (slide.accent)
              const _InfoPanel(
                icon: Icons.lock_outline,
                title: 'Privacy by default',
                text: 'Audio is processed temporarily and released. Saved Professional records contain captions and metadata only.',
              ),
          ],
        ),
      ),
    );
  }
}

class _NavigationScope extends InheritedWidget {

  final ValueChanged<int> onNavigate;
  const _NavigationScope({required this.onNavigate, required super.child});

  static ValueChanged<int>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_NavigationScope>()
      ?.onNavigate;

  @override
  bool updateShouldNotify(_NavigationScope oldWidget) =>
      onNavigate != oldWidget.onNavigate;
}

class HomeShell extends StatefulWidget {
  final AppController controller;
  const HomeShell({super.key, required this.controller});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final List<int> navigationStack = [0];

  void navigateTo(int value) {
    if (value == index) return;
    setState(() {
      navigationStack.remove(value);
      navigationStack.add(value);
      index = value;
    });
  }

  Future<void> handleBack() async {
    if (widget.controller.activeRecord != null) {
      await widget.controller.closeProfessionalDetail();
      return;
    }
    if (navigationStack.length > 1) {
      setState(() {
        navigationStack.removeLast();
        index = navigationStack.last;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(controller: widget.controller, onNavigate: navigateTo),
      EverydayPage(controller: widget.controller),
      ProfessionalPage(controller: widget.controller),
      AlertsPage(controller: widget.controller),
      SettingsPage(controller: widget.controller),
      HistoryPage(controller: widget.controller, onNavigate: navigateTo),
      PslPage(onNavigate: navigateTo),
    ];
    return PopScope(
      canPop:
          navigationStack.length <= 1 && widget.controller.activeRecord == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) handleBack();
      },
      child: _NavigationScope(
        onNavigate: navigateTo,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Scaffold(body: pages[index]),
            if (widget.controller.hazardVisible &&
                widget.controller.visualAlerts)
              _HazardOverlay(
                title: widget.controller.activeHazardType == null
                    ? 'Environmental hazard'
                    : _titleCase(widget.controller.activeHazardType!),
                color: widget.controller.hazardColorName == 'red'
                    ? Colors.red
                    : Colors.blue,
                onDismiss: widget.controller.dismissHazard,
                screenFlash: widget.controller.screenFlashAlerts,
              ),
          ],
        ),
      ),
    );
  }
}

class _HazardOverlay extends StatefulWidget {
  final String title;
  final Color color;
  final VoidCallback onDismiss;
  final bool screenFlash;
  const _HazardOverlay({
    required this.title,
    required this.color,
    required this.onDismiss,
    required this.screenFlash,
  });

  @override
  State<_HazardOverlay> createState() => _HazardOverlayState();
}

class _HazardOverlayState extends State<_HazardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final alpha = widget.screenFlash
                ? 0.74 + controller.value * 0.18
                : 0.94;
            return Container(
              color: widget.color.withValues(alpha: alpha),
              padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
              child: Center(
                child: Card(
                  color: scheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 56,
                          color: widget.color,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Hazard detected',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The screen is flashing to make the alert visible. Dismiss this notice when you are safe.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: widget.onDismiss,
                            icon: const Icon(Icons.check),
                            label: const Text('Dismiss alert'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final double size;
  const _BrandLogo({required this.size});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.24),
    child: Image.asset(
      'assets/HUMSUKHANLOGO.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => Container(
        width: size,
        height: size,
        color: Theme.of(context).colorScheme.primary,
        alignment: Alignment.center,
        child: Text('HS', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w800, fontSize: size * 0.34)),
      ),
    ),
  );
}

class _LandingHeader extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _LandingHeader({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _BrandLogo(size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HumSukhan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Your voice, your connection',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Open Settings',
              onPressed: () => onNavigate(4),
              icon: const Icon(Icons.settings_outlined),
            ),
            IconButton(
              tooltip: 'Open navigation menu',
              onPressed: () => _showNavigationMenu(context, onNavigate),
              icon: const Icon(Icons.menu_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final AppController controller;
  final ValueChanged<int> onNavigate;
  const HomePage({
    super.key,
    required this.controller,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = controller.localDisplayName.trim();
    final greeting = name.isEmpty ? 'Welcome back' : 'Good to see you, $name';
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _LandingHeader(onNavigate: onNavigate),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  HKSpace.lg,
                  HKSpace.sm,
                  HKSpace.lg,
                  HKSpace.hero,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: HKSpace.xs),
                    Text(
                      'Clear communication, made visible.',
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: HKSpace.lg),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(HKSpace.xl),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary,
                            Color.lerp(scheme.primary, scheme.secondary, 0.62)!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(HKRadius.xl),
                        boxShadow: [_softSurfaceShadow(scheme)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: scheme.onPrimary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: scheme.onPrimary.withValues(alpha: 0.22)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline, size: 15, color: scheme.onPrimary),
                                const SizedBox(width: 6),
                                Text('PRIVATE BY DEFAULT', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onPrimary, letterSpacing: 0.6)),
                              ],
                            ),
                          ),
                          const SizedBox(height: HKSpace.md),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start a conversation',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(color: scheme.onPrimary),
                                    ),
                                    const SizedBox(height: HKSpace.xs),
                                    Text(
                                      'Speak and follow every sentence with calm, readable captions.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: scheme.onPrimary.withValues(
                                              alpha: 0.86,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.forum_rounded,
                                color: scheme.onPrimary,
                                size: 36,
                              ),
                            ],
                          ),
                          const SizedBox(height: HKSpace.lg),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: scheme.surface,
                                foregroundColor: scheme.primary,
                              ),
                              onPressed: () => onNavigate(1),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text(
                                controller.conversationState ==
                                        ConversationState.active
                                    ? 'Open live conversation'
                                    : 'Start Conversation',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: HKSpace.md),
                    _ConnectionBadge(online: controller.online),
                    const SizedBox(height: HKSpace.xxl),
                    _SectionTitle(title: 'Start here'),
                    const SizedBox(height: HKSpace.sm),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 560 ? 2 : 1;
                        return GridView.count(
                          crossAxisCount: columns,
                          mainAxisSpacing: HKSpace.sm,
                          crossAxisSpacing: HKSpace.sm,
                          childAspectRatio: columns == 2 ? 2.25 : 3.5,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _HomeFeatureTile(
                              icon: Icons.forum_outlined,
                              title: 'Everyday Mode',
                              text: 'Live captions and spoken replies',
                              onTap: () => onNavigate(1),
                              emphasis: true,
                            ),
                            _HomeFeatureTile(
                              icon: Icons.work_outline,
                              title: 'Professional',
                              text: 'Organized saved sessions',
                              onTap: () => onNavigate(2),
                              emphasis: true,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: HKSpace.xxl),
                    _SectionTitle(title: 'Support tools'),
                    const SizedBox(height: HKSpace.sm),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 560 ? 2 : 1;
                        return GridView.count(
                          crossAxisCount: columns,
                          mainAxisSpacing: HKSpace.sm,
                          crossAxisSpacing: HKSpace.sm,
                          childAspectRatio: columns == 2 ? 2.25 : 3.5,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _HomeFeatureTile(
                              icon: Icons.notifications_none,
                              title: 'Sound Alerts',
                              text: 'Visible environmental notices',
                              onTap: () => onNavigate(3),
                            ),
                            _HomeFeatureTile(
                              icon: Icons.history,
                              title: 'History',
                              text: 'Review saved transcripts',
                              onTap: () => onNavigate(5),
                            ),
                            _HomeFeatureTile(
                              icon: Icons.sign_language,
                              title: 'Sign language',
                              text: 'PSL workspace status',
                              onTap: () => onNavigate(6),
                            ),
                            _HomeFeatureTile(
                              icon: Icons.settings_outlined,
                              title: 'Settings',
                              text: 'Language, privacy, and profile',
                              onTap: () => onNavigate(4),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: HKSpace.xxl),
                    _SectionTitle(title: 'Recent professional sessions'),
                    const SizedBox(height: HKSpace.sm),
                    if (controller.records.isEmpty)
                      _EmptyState(
                        icon: Icons.history,
                        title: 'No saved sessions yet',
                        text: 'Create a Professional session when you are ready to capture a lecture or meeting.',
                      )
                    else
                      ...controller.records
                          .take(3)
                          .map(
                            (record) => _RecentRecordTile(
                              record: record,
                              onTap: () {
                                controller.openRecord(record);
                                onNavigate(2);
                              },
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final bool online;
  const _ConnectionBadge({required this.online});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HKSpace.md,
        vertical: HKSpace.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            size: 18,
            color: online ? HKColors.live : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: HKSpace.xs),
          Text(
            online
                ? 'Online · offline fallback ready'
                : 'Offline · local tools available',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _HomeFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onTap;
  final bool emphasis;
  const _HomeFeatureTile({
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HKRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(emphasis ? HKSpace.lg : HKSpace.md),
          child: Row(
            children: [
              Container(
                width: emphasis ? 50 : 46,
                height: emphasis ? 50 : 46,
                decoration: BoxDecoration(
                  color: emphasis ? scheme.secondaryContainer : scheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
                ),
                child: Icon(icon, color: emphasis ? scheme.onSecondaryContainer : scheme.onPrimaryContainer),
              ),
              const SizedBox(width: HKSpace.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: HKSpace.xxs),
                    Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: scheme.surfaceContainerHighest, shape: BoxShape.circle),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _RecentRecordTile extends StatelessWidget {
  final ProfessionalRecord record;
  final VoidCallback onTap;
  const _RecentRecordTile({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: HKSpace.sm),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: HKSpace.md,
        vertical: HKSpace.xs,
      ),
      leading: CircleAvatar(
        child: Icon(
          record.type == SessionType.meeting
              ? Icons.groups
              : Icons.school_outlined,
        ),
      ),
      title: Text(record.title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(
        '${_dateTime(record.retention.createdAt)} · ${record.folder} · expires ${_date(record.retention.expiresAt)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class HistoryPage extends StatelessWidget {
  final AppController controller;
  final ValueChanged<int> onNavigate;
  const HistoryPage({
    super.key,
    required this.controller,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) => _PageScaffold(
    title: 'History',
    subtitle: 'Saved Professional transcripts and insights.',
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            HKSpace.lg,
            HKSpace.sm,
            HKSpace.lg,
            HKSpace.hero,
          ),
          children: [
            if (controller.records.isEmpty)
              _EmptyState(
                icon: Icons.history,
                title: 'No saved conversations yet',
                text: 'Start a Professional session and your saved transcript will appear here.',
              )
            else
              ...controller.records.map(
                (record) => _RecentRecordTile(
                  record: record,
                  onTap: () {
                    controller.openRecord(record);
                    onNavigate(2);
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class PslPage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const PslPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) => _PageScaffold(
    title: 'Sign language workspace',
    subtitle: 'Pakistani Sign Language support, represented honestly.',
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            HKSpace.lg,
            HKSpace.sm,
            HKSpace.lg,
            HKSpace.hero,
          ),
          children: [
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(HKRadius.xl),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: const Center(
                child: Icon(Icons.videocam_off_outlined, size: 56),
              ),
            ),
            const SizedBox(height: HKSpace.lg),
            const _InfoPanel(
              icon: Icons.info_outline,
              title: 'Recognition provider unavailable',
              text: 'No camera sign-recognition model is connected in this build, so HumSukhan will not claim a sign or confidence value. Use Everyday Mode for text and speech communication.',
            ),
            const SizedBox(height: HKSpace.lg),
            OutlinedButton.icon(
              onPressed: () => onNavigate(1),
              icon: const Icon(Icons.forum_outlined),
              label: const Text('Open Everyday Mode'),
            ),
          ],
        ),
      ),
    ),
  );
}

class EverydayPage extends StatefulWidget {
  final AppController controller;
  const EverydayPage({super.key, required this.controller});
  @override
  State<EverydayPage> createState() => _EverydayPageState();
}

class _EverydayPageState extends State<EverydayPage> {
  final textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> submitText() async {
    final value = textController.text.trim();
    if (value.isEmpty) return;
    widget.controller.setReplyPreview(value);
    textController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final active = c.conversationState == ConversationState.active;
    final scheme = Theme.of(context).colorScheme;
    return _PageScaffold(
      title: 'Everyday Mode',
      subtitle: 'A calm, caption-first conversation space.',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              HKSpace.lg,
              HKSpace.sm,
              HKSpace.lg,
              HKSpace.hero,
            ),
            children: [
              Card(
                color: scheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(HKSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Conversation',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          _StatusBadge(
                            label: active ? 'LIVE' : 'READY',
                            active: active,
                          ),
                        ],
                      ),
                      const SizedBox(height: HKSpace.xs),
                      Text(
                        active
                            ? (c.microphoneListening
                                  ? 'Microphone active. Speak naturally.'
                                  : 'Waiting for the speech service…')
                            : 'Start when you are ready. Nothing listens automatically.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: HKSpace.md),
                      if (!active)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: c.startConversation,
                            icon: const Icon(Icons.mic_none_rounded),
                            label: const Text('Start Conversation'),
                          ),
                        )
                      else
                        _AttentionCue(
                          active: c.microphoneListening,
                          title: c.microphoneListening ? 'Listening for speech' : 'Reconnecting microphone',
                          subtitle: c.microphoneListening
                              ? 'Speak naturally. Your next sentence will appear below.'
                              : 'Keep this screen open while the speech service reconnects.',
                        ),
                    ],
                  ),
                ),
              ),
              if (c.conversationState == ConversationState.starting ||
                  c.conversationState == ConversationState.stopping) ...[
                const SizedBox(height: HKSpace.xs),
                const LinearProgressIndicator(minHeight: 3),
              ],
              const SizedBox(height: HKSpace.lg),
              _CaptionPanel(lines: c.liveTranscript, enabled: active, partial: c.livePartialCaption),
              if (c.nativeError != null) ...[
                const SizedBox(height: HKSpace.sm),
                _ErrorPanel(text: c.nativeError!),
              ],
              const SizedBox(height: HKSpace.lg),
              _SectionTitle(title: 'Your response'),
              const SizedBox(height: HKSpace.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(HKSpace.md),
                  child: Column(
                    children: [
                      TextField(
                        controller: textController,
                        enabled: active,
                        minLines: 2,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        textDirection: c.captionLanguage == CaptionLanguage.urduScript || _containsUrdu(textController.text) ? TextDirection.rtl : TextDirection.ltr,
                        textAlign: c.captionLanguage == CaptionLanguage.urduScript || _containsUrdu(textController.text) ? TextAlign.right : TextAlign.left,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Type your reply',
                          hintText: 'Your words can be spoken aloud',
                          prefixIcon: Icon(Icons.keyboard_outlined),
                        ),
                      ),
                      Align(alignment: Alignment.centerLeft, child: Text('For Urdu typing, enable the Urdu keyboard in Android keyboard settings.', style: Theme.of(context).textTheme.bodySmall)),
                      const SizedBox(height: HKSpace.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _DropdownField<CaptionLanguage>(
                              label: 'Language',
                              value: c.captionLanguage,
                              values: CaptionLanguage.values,
                              labelOf: (value) => value.label,
                              onChanged: c.setLanguage,
                            ),
                          ),
                          const SizedBox(width: HKSpace.sm),
                          IconButton.filled(
                            tooltip: 'Speak written reply',
                            onPressed:
                                active && textController.text.trim().isNotEmpty
                                ? () => c.sendReply(
                                    textController.text,
                                    speak: true,
                                  )
                                : null,
                            icon: const Icon(Icons.volume_up_outlined),
                          ),
                          const SizedBox(width: HKSpace.xs),
                          FilledButton.icon(
                            onPressed:
                                active && textController.text.trim().isNotEmpty
                                ? submitText
                                : null,
                            icon: const Icon(Icons.record_voice_over_outlined),
                            label: const Text('Speak'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (c.suggestedResponseText != null && active) ...[
                const SizedBox(height: HKSpace.sm),
                Card(
                  color: scheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(HKSpace.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.suggestedResponseText!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Speak suggested reply',
                          onPressed: () => c.sendReply(
                            c.suggestedResponseText!,
                            speak: true,
                          ),
                          icon: const Icon(Icons.volume_up_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: HKSpace.lg),
              _SectionTitle(
                title: 'Quick replies',
                trailing: IconButton(
                  tooltip: 'Add a quick reply',
                  onPressed: () => _showQuickReplyDialog(context, c),
                  icon: const Icon(Icons.add),
                ),
              ),
              const SizedBox(height: HKSpace.xs),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: c.quickReplies.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: HKSpace.xs),
                  itemBuilder: (context, index) {
                    final reply = c.quickReplies[index];
                    return ActionChip(
                      avatar: const Icon(Icons.chat_bubble_outline, size: 17),
                      label: Text(reply.text),
                      onPressed: active
                          ? () => c.sendReply(reply.text, speak: true)
                          : null,
                    );
                  },
                ),
              ),
              if (active) ...[
                const SizedBox(height: HKSpace.xxl),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: c.requestStopConversation,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Stop Conversation'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ProfessionalPage extends StatefulWidget {
  final AppController controller;
  const ProfessionalPage({super.key, required this.controller});
  @override
  State<ProfessionalPage> createState() => _ProfessionalPageState();
}

class _ProfessionalPageState extends State<ProfessionalPage> {
  String selectedFolder = 'All';

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (c.activeRecord != null)
      return _ProfessionalDetail(controller: c, record: c.activeRecord!);
    final visibleRecords = selectedFolder == 'All'
        ? c.records
        : c.records.where((record) => record.folder == selectedFolder).toList();
    final scheme = Theme.of(context).colorScheme;
    return _PageScaffold(
      title: 'Professional Mode',
      subtitle: 'An organized workspace for lectures, classes, and meetings.',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              HKSpace.lg,
              HKSpace.sm,
              HKSpace.lg,
              HKSpace.hero,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      value: '${c.records.length}',
                      label: 'Saved sessions',
                      icon: Icons.description_outlined,
                    ),
                  ),
                  const SizedBox(width: HKSpace.sm),
                  Expanded(
                    child: _MetricCard(
                      value: '15d',
                      label: 'Maximum retention',
                      icon: Icons.schedule,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HKSpace.xxl),
              _SectionTitle(
                title: 'Workspace folders',
                trailing: FilledButton.tonalIcon(
                  onPressed: () => _showNewFolder(context, c),
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: const Text('New folder'),
                ),
              ),
              const SizedBox(height: HKSpace.sm),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 620 ? 3 : 1;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: HKSpace.sm,
                    crossAxisSpacing: HKSpace.sm,
                    childAspectRatio: columns == 3 ? 1.55 : 3.4,
                    children: c.folders.map((folder) {
                      final count = c.records
                          .where((record) => record.folder == folder)
                          .length;
                      final selected = selectedFolder == folder;
                      final isDefault = const {
                        'General',
                        'Classes',
                        'Meetings',
                      }.contains(folder);
                      return Card(
                        color: selected ? scheme.primaryContainer : null,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(HKRadius.lg),
                          onTap: () => setState(
                            () => selectedFolder = selected ? 'All' : folder,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(HKSpace.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.folder_outlined,
                                      color: selected
                                          ? scheme.onPrimaryContainer
                                          : scheme.primary,
                                    ),
                                    const Spacer(),
                                    if (!isDefault)
                                      IconButton(
                                        tooltip: 'Delete folder',
                                        onPressed: () => _confirmDeleteFolder(
                                          context,
                                          c,
                                          folder,
                                        ),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 19,
                                        ),
                                      ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  folder,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: selected
                                            ? scheme.onPrimaryContainer
                                            : null,
                                      ),
                                ),
                                Text(
                                  '$count session${count == 1 ? '' : 's'}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: selected
                                            ? scheme.onPrimaryContainer
                                            : scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: HKSpace.xxl),
              _SectionTitle(
                title: selectedFolder == 'All'
                    ? 'Recent sessions'
                    : selectedFolder,
                trailing: FilledButton.icon(
                  onPressed: () => _showNewSession(
                    context,
                    c,
                    selectedFolder == 'All' ? 'General' : selectedFolder,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('New session'),
                ),
              ),
              const SizedBox(height: HKSpace.sm),
              if (visibleRecords.isEmpty)
                const _EmptyState(
                  icon: Icons.event_note_outlined,
                  title: 'No sessions in this folder',
                  text: 'Start a Professional session when you are ready. It will be saved here with its transcript and insights.',
                )
              else
                ...visibleRecords.map(
                  (record) => _ProfessionalRecordTile(
                    record: record,
                    onTap: () => c.openRecord(record),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfessionalRecordTile extends StatelessWidget {
  final ProfessionalRecord record;
  final VoidCallback onTap;
  const _ProfessionalRecordTile({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final live = record.startedAt != null && record.stoppedAt == null;
    final duration = record.startedAt == null
        ? 'Not started'
        : record.stoppedAt == null
        ? 'Live'
        : _durationLabel(record.startedAt!, record.stoppedAt!);
    return Card(
      margin: const EdgeInsets.only(bottom: HKSpace.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: HKSpace.md,
          vertical: HKSpace.xs,
        ),
        leading: CircleAvatar(
          child: Icon(
            record.type == SessionType.meeting
                ? Icons.groups_outlined
                : Icons.school_outlined,
          ),
        ),
        title: Text(
          record.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${record.type.label} · ${_dateTime(record.retention.createdAt)}\n$duration · Expires ${_date(record.retention.expiresAt)}',
        ),
        isThreeLine: true,
        trailing: _StatusBadge(
          label: live
              ? 'LIVE'
              : record.stoppedAt != null
              ? 'SAVED'
              : 'READY',
          active: live,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ProfessionalDetail extends StatelessWidget {
  final AppController controller;
  final ProfessionalRecord record;
  const _ProfessionalDetail({required this.controller, required this.record});

  @override
  Widget build(BuildContext context) {
    final started = record.startedAt != null && record.stoppedAt == null;
    final done = record.stoppedAt != null;
    final scheme = Theme.of(context).colorScheme;
    return _PageScaffold(
      title: record.title,
      subtitle: '${record.type.label} · ${record.folder}',
      actions: [
        IconButton(
          tooltip: 'Delete session',
          onPressed: () => _confirmDeleteRecord(context, controller, record),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              HKSpace.lg,
              HKSpace.sm,
              HKSpace.lg,
              HKSpace.hero,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      done
                          ? 'Saved transcript'
                          : started
                          ? 'Live lecture'
                          : 'Ready to begin',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  _StatusBadge(
                    label: done
                        ? 'SAVED'
                        : started
                        ? 'LIVE'
                        : 'READY',
                    active: started,
                  ),
                ],
              ),
              const SizedBox(height: HKSpace.xs),
              Text(
                'Created ${_dateTime(record.retention.createdAt)} · ${done ? _durationLabel(record.startedAt!, record.stoppedAt!) : 'Duration will appear after stopping'}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: HKSpace.lg),
              if (!started && !done)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: controller.startProfessionalSession,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start session and live captions'),
                  ),
                ),
              if (started) ...[
                _AttentionCue(
                  active: controller.microphoneListening,
                  title: controller.microphoneListening ? 'Live captions are listening' : 'Reconnecting microphone',
                  subtitle: controller.microphoneListening
                      ? 'Speak naturally. Complete sentences will appear in the transcript.'
                      : 'The speech service is restarting its listening window.',
                ),
                const SizedBox(height: HKSpace.md),
                _CaptionPanel(lines: controller.liveTranscript, enabled: true, partial: controller.livePartialCaption),
                const SizedBox(height: HKSpace.md),
                _DemoCaptionInput(onSubmit: controller.addProfessionalCaption),
                const SizedBox(height: HKSpace.lg),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: controller.stopProfessionalSession,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Stop lecture'),
                  ),
                ),
              ],
              if (done) ...[
                _TranscriptPanel(lines: record.transcript),
                const SizedBox(height: HKSpace.lg),
                if (record.insights != null)
                  _InsightsPanel(
                    insights: record.insights!,
                    onExport: () =>
                        _showExportDialog(context, controller, record),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: controller.generateInsightsForActiveRecord,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate insights'),
                    ),
                  ),
                const SizedBox(height: HKSpace.sm),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showExportDialog(context, controller, record),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Export transcript as .txt'),
                ),
              ],
              const SizedBox(height: HKSpace.lg),
              Text(
                'Expires ${_date(record.retention.expiresAt)} · ${record.retention.retentionDays}-day retention',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlertsPage extends StatelessWidget {
  final AppController controller;
  const AlertsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _PageScaffold(
      title: 'Environmental Alerts',
      subtitle: 'Visible alerts with a clear history and honest detector limits.',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Environment monitoring',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Switch(
                        value: controller.environmentalAlertsEnabled,
                        onChanged: controller.enableEnvironmentalAlerts,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.environmentalAlertsEnabled
                        ? 'Monitoring is active. Audio energy activity can trigger a visible notice; this build does not claim to identify a specific sound without a classifier model.'
                        : 'Monitoring is off. Enable it to listen for audio activity while this app is open.',
                  ),
                  if (controller.nativeError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      controller.nativeError!,
                      style: TextStyle(color: scheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Detector status'),
              subtitle: const Text('Activity monitor only. Fire alarm, siren, doorbell, knock, and emergency labels are available as controlled tests until a licensed on-device classifier is added.'),
            ),
          ),
          const SizedBox(height: 14),
          _SectionTitle(title: 'Allowed alerts'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.detectorTypes
                .map(
                  (text) => Chip(
                    avatar: const Icon(Icons.hearing, size: 16),
                    label: Text(_titleCase(text)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'Safe detector tests',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Each test uses the same hazard notification flow but identifies the selected alert by name and color.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.detectorTypes
                .map(
                  (detector) => OutlinedButton.icon(
                    onPressed: controller.environmentalAlertsEnabled
                        ? () => controller.runSafeTestEvent(detector)
                        : null,
                    icon: Icon(
                      detector == 'fire alarm'
                          ? Icons.local_fire_department_outlined
                          : Icons.campaign_outlined,
                    ),
                    label: Text('Test ${_titleCase(detector)}'),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _SectionTitle(title: 'Alert history')),
              if (controller.soundAlerts.isNotEmpty)
                TextButton.icon(onPressed: controller.clearSoundAlerts, icon: const Icon(Icons.delete_sweep_outlined), label: const Text('Clear')),
            ],
          ),
          if (controller.soundAlerts.isEmpty)
            const _EmptyState(
              icon: Icons.notifications_none,
              title: 'No alerts yet',
              text: 'Qualified activity will appear here with a visible notice and optional flashlight/haptic feedback.',
            ),
          ...controller.soundAlerts.map(
            (alert) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text(alert),
                subtitle: const Text(
                  'This record is an activity event or a controlled test; confidence is intentionally not shown as sound-class confidence.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final AppController controller;
  const SettingsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Settings',
      subtitle: 'Accessibility, privacy, and capability preferences.',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _SectionTitle(title: 'Local account'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(_avatarIcon(controller.localAvatar)),
              ),
              title: Text(
                controller.localDisplayName.isEmpty
                    ? 'Create a local profile'
                    : controller.localDisplayName,
              ),
              subtitle: Text(
                controller.localUsername.isEmpty
                    ? 'Username, avatar, and local credentials stay on this device.'
                    : '@${controller.localUsername}',
              ),
              trailing: FilledButton.tonal(
                onPressed: () => _showLocalAccountDialog(context, controller),
                child: Text(
                  controller.localDisplayName.isEmpty ? 'Create' : 'Edit',
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(title: 'Language & speech'),
          const SizedBox(height: HKSpace.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(HKSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caption language',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: HKSpace.xs),
                  _DropdownField<CaptionLanguage>(
                    label: 'Choose a caption language',
                    value: controller.captionLanguage,
                    values: CaptionLanguage.values,
                    labelOf: (value) => value.label,
                    onChanged: controller.setLanguage,
                  ),
                  const SizedBox(height: HKSpace.sm),
                  Text(
                    'Text-to-speech uses the device voice when the selected language is supported.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: HKSpace.md),
                  _SettingSwitch(
                    title: 'Use bundled offline speech',
                    subtitle: 'Sherpa-ONNX keeps English and Urdu Script recognition on this device. Roman Urdu uses Android speech because the bundled model returns Urdu script.',
                    value: controller.preferOfflineSpeech,
                    onChanged: controller.setPreferOfflineSpeech,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: HKSpace.xxl),
          _SectionTitle(title: 'Accessibility'),
          const SizedBox(height: 8),
          _SettingSwitch(
            title: 'Large text',
            subtitle: 'Increase readable text throughout HumSukhan',
            value: controller.largeText,
            onChanged: (value) {
              controller.largeText = value;
              controller.saveSettings();
            },
          ),
          _SettingSwitch(
            title: 'Dark mode',
            subtitle: 'Use a dark surface palette',
            value: controller.darkMode,
            onChanged: (value) {
              controller.darkMode = value;
              controller.saveSettings();
            },
          ),
          _SettingSwitch(
            title: 'Haptic alerts',
            subtitle: 'Vibrate for qualified environmental events',
            value: controller.hapticAlerts,
            onChanged: (value) {
              controller.hapticAlerts = value;
              controller.saveSettings();
            },
          ),
          _SettingSwitch(
            title: 'Visual alerts',
            subtitle: 'Show clear visual alerts for qualified events',
            value: controller.visualAlerts,
            onChanged: (value) {
              controller.visualAlerts = value;
              controller.saveSettings();
            },
          ),
          _SettingSwitch(
            title: 'Screen-flash alerts',
            subtitle: 'Flash the app screen red or blue for a hazard event',
            value: controller.screenFlashAlerts,
            onChanged: (value) {
              controller.screenFlashAlerts = value;
              controller.saveSettings();
            },
          ),
          _SettingSwitch(
            title: 'Flashlight alerts',
            subtitle: 'Use the device flashlight briefly when supported',
            value: controller.flashlightAlerts,
            onChanged: (value) {
              controller.flashlightAlerts = value;
              controller.saveSettings();
            },
          ),
          const SizedBox(height: HKSpace.xxl),
          _SectionTitle(title: 'Notifications & sound alerts'),
          const SizedBox(height: HKSpace.sm),
          Text(
            'Visual, screen-flash, flashlight, and haptic preferences are available here and in Environmental Alerts.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: HKSpace.xxl),
          _SectionTitle(title: 'Privacy & retention'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined),
                      SizedBox(width: 10),
                      Text(
                        'Privacy guardrails',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Raw audio is not a persistent data field. Records contain captions and metadata only. Retention and deletion are deterministic and never delegated to AI.',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Stored records: ${controller.records.length} • maximum retention: 15 days',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: controller.enforceRetention,
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Evaluate retention now'),
          ),
          if (controller.settingsMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              controller.settingsMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget child;
  const _PageScaffold({
    required this.title,
    required this.subtitle,
    this.actions = const [],
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              HKSpace.md,
              HKSpace.md,
              HKSpace.sm,
              HKSpace.sm,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(HKRadius.xl),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.8)),
                boxShadow: [_tightSurfaceShadow(scheme)],
              ),
              padding: const EdgeInsets.fromLTRB(
                HKSpace.sm,
                HKSpace.sm,
                HKSpace.xs,
                HKSpace.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _BrandLogo(size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  ...actions,
                  if (_NavigationScope.maybeOf(context) != null)
                    IconButton(
                      tooltip: 'Open navigation menu',
                      onPressed: () => _showNavigationMenu(
                        context,
                        _NavigationScope.maybeOf(context)!,
                      ),
                      icon: const Icon(Icons.menu_rounded),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.text,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CaptionPanel extends StatelessWidget {
  final List<TranscriptLine> lines;
  final bool enabled;
  final String? partial;
  const _CaptionPanel({required this.lines, required this.enabled, this.partial});

  @override
  Widget build(BuildContext context) {
    final visibleLines = lines.takeLast(12).toList();
    final hasUrdu = visibleLines.any((line) => _containsUrdu(line.text)) || _containsUrdu(partial ?? '');
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: enabled,
      label: enabled ? 'Live captions' : 'Saved transcript',
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(HKSpace.lg),
          child: Directionality(
            textDirection: hasUrdu ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.closed_caption_outlined, color: scheme.primary),
                    const SizedBox(width: HKSpace.xs),
                    Expanded(
                      child: Text(
                        enabled ? 'Live captions' : 'Saved transcript',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _StatusBadge(
                      label: enabled ? 'LIVE' : 'SAVED',
                      active: enabled,
                    ),
                  ],
                ),
                const SizedBox(height: HKSpace.md),
                Divider(color: scheme.outlineVariant.withValues(alpha: 0.72), height: 1),
                const SizedBox(height: HKSpace.md),
                if (visibleLines.isEmpty)
                  Text(
                    enabled
                        ? 'Waiting for a complete sentence…'
                        : 'No saved sentences.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  )
                else
                  ...visibleLines.map((line) => _ChatBubble(line: line)),
                  if (partial != null && partial!.trim().isNotEmpty)
                    _ChatBubble(line: TranscriptLine(speaker: 'Listening', text: partial!), partial: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool active;
  const _StatusBadge({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HKSpace.sm,
        vertical: HKSpace.xs,
      ),
      decoration: BoxDecoration(
        color: active
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.circle : Icons.check_circle_outline,
            size: 10,
            color: active ? HKColors.live : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: HKSpace.xxs),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _AttentionCue extends StatefulWidget {
  final bool active;
  final String title;
  final String subtitle;
  const _AttentionCue({required this.active, required this.title, required this.subtitle});

  @override
  State<_AttentionCue> createState() => _AttentionCueState();
}

class _AttentionCueState extends State<_AttentionCue> with SingleTickerProviderStateMixin {
  late final AnimationController pulse;

  @override
  void initState() {
    super.initState();
    pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    if (widget.active) pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _AttentionCue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !pulse.isAnimating) pulse.repeat(reverse: true);
    if (!widget.active && pulse.isAnimating) pulse.stop();
  }

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.active ? HKColors.live : scheme.tertiary;
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final glow = widget.active ? 0.08 + pulse.value * 0.11 : 0.05;
        return Container(
          padding: const EdgeInsets.all(HKSpace.md),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(HKRadius.md),
            border: Border.all(color: accent.withValues(alpha: 0.34)),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: glow), blurRadius: 18, spreadRadius: widget.active ? pulse.value * 2 : 0)],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: Icon(widget.active ? Icons.mic_rounded : Icons.sync_rounded, color: accent),
              ),
              const SizedBox(width: HKSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: HKSpace.xxs),
                    Text(widget.subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (widget.active) Container(width: 10, height: 10, decoration: const BoxDecoration(color: HKColors.live, shape: BoxShape.circle)),
            ],
          ),
        );
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final TranscriptLine line;
  final bool partial;
  const _ChatBubble({required this.line, this.partial = false});

  @override
  Widget build(BuildContext context) {
    final responder = line.speaker == 'Responder';
    final isPartial = partial || line.speaker == 'Listening';
    final scheme = Theme.of(context).colorScheme;
    final color = responder
        ? scheme.primaryContainer
        : isPartial
        ? scheme.tertiaryContainer
        : scheme.surfaceContainerHighest;
    final foreground = responder ? scheme.onPrimaryContainer : scheme.onSurface;
    final label = responder ? 'You' : isPartial ? 'Listening' : 'Speaker';
    final rtl = _containsUrdu(line.text);
    return Align(
      alignment: responder ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: HKSpace.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: HKSpace.md,
          vertical: HKSpace.sm,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(HKRadius.md),
            topRight: const Radius.circular(HKRadius.md),
            bottomLeft: Radius.circular(responder ? HKRadius.md : HKRadius.xs),
            bottomRight: Radius.circular(responder ? HKRadius.xs : HKRadius.md),
          ),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: responder ? 0.08 : 0.035),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Semantics(
          label: '$label: ${line.text}',
          liveRegion: true,
          child: Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: foreground),
                ),
                const SizedBox(height: HKSpace.xxs),
                Text(
                  line.text,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: foreground, fontSize: 18, height: 1.42),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TranscriptPanel extends StatelessWidget {
  final List<TranscriptLine> lines;
  const _TranscriptPanel({required this.lines});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transcript',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const Divider(),
          if (lines.isEmpty)
            const Text('No transcript captured.')
          else
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text('${line.speaker}: ${line.text}'),
              ),
            ),
        ],
      ),
    ),
  );
}

class _InsightsPanel extends StatelessWidget {
  final ProfessionalInsights insights;
  final VoidCallback onExport;
  const _InsightsPanel({required this.insights, required this.onExport});
  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Professional insights',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              IconButton(
                tooltip: 'Export',
                onPressed: onExport,
                icon: const Icon(Icons.ios_share),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'AI-generated — may contain errors',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          _InsightRow(title: 'Summary', value: insights.summary),
          _InsightRow(
            title: 'Vocabulary',
            value: insights.vocabulary.join(', '),
          ),
          _InsightRow(title: 'Themes', value: insights.themes.join(', ')),
          _InsightRow(
            title: 'Action items',
            value: insights.actionItems.join(' '),
          ),
          _InsightRow(title: 'Deadlines', value: insights.deadlines.join(', ')),
        ],
      ),
    ),
  );
}

class _InsightRow extends StatelessWidget {
  final String title;
  final String value;
  const _InsightRow({required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(value),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(label),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionTitle({required this.title, this.trailing});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      if (trailing != null) trailing!,
    ],
  );
}

class _ErrorPanel extends StatelessWidget {
  final String text;
  const _ErrorPanel({required this.text});
  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.text,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 42),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 5),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _SettingSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    ),
  );
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  const _DropdownField({
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: values
        .map(
          (item) =>
              DropdownMenuItem<T>(value: item, child: Text(labelOf(item))),
        )
        .toList(),
    onChanged: (item) {
      if (item != null) onChanged(item);
    },
  );
}

class _DemoCaptionInput extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  const _DemoCaptionInput({required this.onSubmit});
  @override
  State<_DemoCaptionInput> createState() => _DemoCaptionInputState();
}

class _DemoCaptionInputState extends State<_DemoCaptionInput> {
  final field = TextEditingController();
  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: TextField(
          controller: field,
          decoration: const InputDecoration(
            labelText: 'Add a caption for review',
          ),
        ),
      ),
      const SizedBox(width: 8),
      IconButton.filled(
        tooltip: 'Add caption',
        onPressed: () {
          widget.onSubmit(field.text);
          field.clear();
        },
        icon: const Icon(Icons.add),
      ),
    ],
  );
}

IconData _avatarIcon(String id) => switch (id) {
  'face' => Icons.face_retouching_natural,
  'accessibility' => Icons.accessibility_new,
  'school' => Icons.school_outlined,
  'work' => Icons.work_outline,
  _ => Icons.person,
};

void _confirmDeleteFolder(
  BuildContext context,
  AppController c,
  String folder,
) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete $folder?'),
      content: const Text(
        'Existing sessions will be moved to the General folder. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await c.deleteFolder(folder);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: const Text('Delete folder'),
        ),
      ],
    ),
  );
}

void _showLocalAccountDialog(BuildContext context, AppController c) {
  final displayName = TextEditingController(text: c.localDisplayName);
  final username = TextEditingController(text: c.localUsername);
  final passcode = TextEditingController();
  var avatar = c.localAvatar;
  const avatarOptions = ['person', 'face', 'accessibility', 'school', 'work'];
  showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: const Text('Create local account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: displayName,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Your name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: username,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passcode,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Local passcode',
                  helperText:
                      'Used only to mark this device profile as configured.',
                ),
              ),
              const SizedBox(height: 14),
              const Text('Profile picture'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: avatarOptions
                    .map(
                      (option) => ChoiceChip(
                        avatar: Icon(_avatarIcon(option), size: 18),
                        label: Text(
                          option == 'person'
                              ? 'Person'
                              : option[0].toUpperCase() + option.substring(1),
                        ),
                        selected: avatar == option,
                        onSelected: (_) => setState(() => avatar = option),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              const Text(
                'This account is stored on this device only. No cloud account or network sign-in is created.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (displayName.text.trim().isEmpty ||
                  username.text.trim().isEmpty)
                return;
              await c.saveLocalProfile(
                displayName: displayName.text,
                username: username.text,
                avatar: avatar,
                credentialConfigured:
                    passcode.text.trim().isNotEmpty ||
                    c.localCredentialConfigured,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save profile'),
          ),
        ],
      ),
    ),
  );
}

void _showNewFolder(BuildContext context, AppController c) {
  final name = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New folder'),
      content: TextField(
        controller: name,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Folder name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final clean = name.text.trim();
            if (clean.isEmpty) return;
            await c.addFolder(clean);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Create folder'),
        ),
      ],
    ),
  );
}

void _showNewSession(BuildContext context, AppController c, String folder) {
  final title = TextEditingController();
  var type = SessionType.meeting;
  var language = CaptionLanguage.auto;
  var retention = RetentionDays.seven;
  showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('New professional session'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              _DropdownField<SessionType>(
                label: 'Type',
                value: type,
                values: SessionType.values,
                labelOf: (v) => v.label,
                onChanged: (v) => setState(() => type = v),
              ),
              const SizedBox(height: 12),
              Text('This session will be saved in $folder.'),
              const SizedBox(height: 12),
              _DropdownField<CaptionLanguage>(
                label: 'Caption language',
                value: language,
                values: CaptionLanguage.values,
                labelOf: (v) => v.label,
                onChanged: (v) => setState(() => language = v),
              ),
              const SizedBox(height: 12),
              _DropdownField<RetentionDays>(
                label: 'Retention',
                value: retention,
                values: RetentionDays.values,
                labelOf: (v) => v.label,
                onChanged: (v) => setState(() => retention = v),
              ),
              const SizedBox(height: 8),
              const Text(
                'Only Professional Mode sessions are saved. Maximum retention is 15 days.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await c.createProfessionalSession(
                title: title.text,
                type: type,
                folder: folder,
                language: language,
                retention: retention,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create session'),
          ),
        ],
      ),
    ),
  );
}

void _showQuickReplyDialog(BuildContext context, AppController c) {
  final text = TextEditingController();
  var category = 'Custom';
  showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Custom quick reply'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: text,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Phrase'),
            ),
            const SizedBox(height: 12),
            _DropdownField<String>(
              label: 'Category',
              value: category,
              values: const ['Custom', 'Conversation', 'Response'],
              labelOf: (v) => v,
              onChanged: (v) => setState(() => category = v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (text.text.trim().isNotEmpty)
                c.addQuickReply(text.text.trim(), category);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    ),
  );
}

void _confirmDeleteRecord(
  BuildContext context,
  AppController c,
  ProfessionalRecord record,
) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete session?'),
      content: Text(
        'Delete “${record.title}” and its transcript? This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await c.deleteProfessionalRecord(record);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Delete permanently'),
        ),
      ],
    ),
  );
}

void _showNavigationMenu(BuildContext context, ValueChanged<int> onNavigate) {
  final items = <(IconData, String, int)>[
    (Icons.home_outlined, 'Home', 0),
    (Icons.forum_outlined, 'Everyday Mode', 1),
    (Icons.history, 'History', 5),
    (Icons.work_outline, 'Professional Mode', 2),
    (Icons.sign_language, 'Sign Language', 6),
    (Icons.notifications_none, 'Environmental Alerts', 3),
    (Icons.settings_outlined, 'Settings', 4),
  ];
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(
                children: [
                  _BrandLogo(size: 34),
                  const SizedBox(width: 10),
                  Text(
                    'HumSukhan',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            ...items.map(
              (item) => ListTile(
                leading: Icon(item.$1),
                title: Text(item.$2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onNavigate(item.$3);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showExportDialog(
  BuildContext context,
  AppController c,
  ProfessionalRecord record,
) {
  final content = c.exportText(record);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Export session'),
      content: const Text(
        "Exported files are stored outside HumSukhan and won't be automatically deleted by HumSukhan. HumSukhan cannot delete files already exported outside the app.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: content));
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('TXT content copied to clipboard.'),
                ),
              );
            }
          },
          child: const Text('Copy TXT'),
        ),
        FilledButton(
          onPressed: () async {
            await c.shareTxtFile(record);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Share .txt file'),
        ),
      ],
    ),
  );
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _durationLabel(DateTime start, DateTime end) {
  final duration = end.difference(start);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m';
  if (minutes > 0) return '${minutes}m ${seconds}s';
  return '${seconds}s';
}

String _dateTime(DateTime date) =>
    '${_date(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';

String _titleCase(String value) => value
    .split(' ')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

extension<T> on List<T> {
  Iterable<T> takeLast(int count) => skip(length > count ? length - count : 0);
}
