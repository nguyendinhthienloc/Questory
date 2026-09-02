import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/domain/destination_models.dart';
import 'package:questory/core/domain/run_models.dart';
import 'package:questory/features/quest_camera/presentation/quest_camera_screen.dart';

void main() {
  testWidgets('caption sheet handles keyboard, validation, and closing safely',
      (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => QuestCaptionSheet(
                    path: '/missing-test-photo.jpg',
                    quest: _quest(),
                  ),
                );
              },
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quest-caption')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-quest-evidence')));
    await tester.pump();
    expect(find.text('Add a short caption.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('quest-caption')),
      'City light and river colour',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-quest-evidence')));
    await tester.pumpAndSettle();

    expect(result, 'City light and river colour');
    expect(tester.takeException(), isNull);
  });
}

Quest _quest() {
  final point = GeoPoint(
    latitude: 10.772,
    longitude: 106.7058,
    timestampUtc: DateTime.utc(2026),
  );
  return Quest(
    id: 'caption-test',
    title: 'River Color Story',
    prompt: 'Capture three colours.',
    point: point,
    radiusMeters: 100,
    captionRequired: true,
    fallback: const QuestFallback(
      type: QuestFallbackType.manualConfirmation,
      instructions: 'Confirm your location.',
    ),
  );
}
