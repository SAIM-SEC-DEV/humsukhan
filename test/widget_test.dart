import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humsukhan/main.dart';

void main() {
  testWidgets('HumSukhan presents focused privacy-first onboarding', (tester) async {
    final controller = AppController()..localLoginComplete = true;
    await tester.pumpWidget(HumSukhanApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to HumSukhan'), findsOneWidget);
    expect(find.text('Privacy by default'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  test('native partial captions stay in one evolving sentence bubble', () {
    final controller = AppController()
      ..conversationState = ConversationState.active;
    controller.handleNativeMethod(const MethodCall('speechPartial', 'Hello wor'));
    expect(controller.liveTranscript, isEmpty);
    expect(controller.livePartialCaption, 'Hello wor');

    controller.handleNativeMethod(const MethodCall('speechPartial', 'Hello world'));
    expect(controller.liveTranscript, isEmpty);
    expect(controller.livePartialCaption, 'Hello world');

    controller.handleNativeMethod(const MethodCall('speechFinal', 'Hello world.'));
    expect(controller.livePartialCaption, isNull);
    expect(controller.liveTranscript, hasLength(1));
    expect(controller.liveTranscript.single.text, 'Hello world.');
  });

  test('alert history can be cleared', () async {
    final controller = AppController()..environmentalAlertsEnabled = true;
    await controller.runSafeTestEvent('siren');
    expect(controller.soundAlerts, hasLength(1));
    await controller.clearSoundAlerts();
    expect(controller.soundAlerts, isEmpty);
    expect(controller.hazardVisible, isFalse);
  });
}
