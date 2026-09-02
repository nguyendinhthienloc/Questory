import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questory/app/app_dependencies.dart';
import 'package:questory/core/fixtures/fake_destination_repository.dart';
import 'package:questory/core/fixtures/fake_run_dependencies.dart';
import 'package:questory/core/fixtures/fake_story_services.dart';
import 'package:questory/features/history/presentation/history_screen.dart';

void main() {
  testWidgets('shows a useful empty history state', (tester) async {
    final dependencies = AppDependencies(
      destinations: FakeDestinationRepository(),
      runs: FakeRunRepository(),
      stories: FakeStoryRepository(),
      achievements: FakeAchievementRepository(),
      locationTracker: FakeLocationTracker(),
      photoStore: FakePhotoStore(),
      clock: FakeClock(DateTime.utc(2026)),
      shareService: FakeShareService(),
    );

    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(dependencies: dependencies)),
    );
    await tester.pumpAndSettle();

    expect(find.text('YOUR JOURNEY'), findsOneWidget);
    expect(find.text('Your first story starts outside'), findsOneWidget);
    expect(find.textContaining('Complete a route'), findsOneWidget);
  });
}
