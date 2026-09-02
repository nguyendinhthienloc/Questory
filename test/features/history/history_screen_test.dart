import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questory/app/app_dependencies.dart';
import 'package:questory/core/domain/achievement.dart';
import 'package:questory/core/domain/run_models.dart';
import 'package:questory/core/fixtures/fake_destination_repository.dart';
import 'package:questory/core/fixtures/fake_run_dependencies.dart';
import 'package:questory/core/fixtures/fake_story_services.dart';
import 'package:questory/features/history/presentation/history_screen.dart';
import 'package:questory/features/story_studio/data/story_templates.dart';

void main() {
  testWidgets('shows a useful empty history state', (tester) async {
    await _pumpHistory(tester, _dependencies());
    expect(find.text('YOUR JOURNEY'), findsOneWidget);
    expect(find.text('Your first story starts outside'), findsOneWidget);
    expect(find.textContaining('Complete a route'), findsOneWidget);
  });

  testWidgets('shows saved runs, stories, and achievement progress', (
    tester,
  ) async {
    final run = _run();
    final runs = FakeRunRepository()..summaries[run.id] = run;
    final story = storyTemplates.first.createDocument(
      documentId: 'story-1',
      sourceRunId: run.id,
    );
    final stories = FakeStoryRepository(seed: [story]);
    final achievements = FakeAchievementRepository()
      ..achievements = [
        Achievement(
          id: 'first-run',
          title: 'First Footstep',
          description: 'Complete your first Questory run.',
          progress: 1,
          target: 1,
          unlockedAtUtc: DateTime.utc(2026, 9, 2),
        ),
        const Achievement(
          id: 'quest-hunter',
          title: 'Quest Hunter',
          description: 'Complete three photo quests.',
          progress: 1,
          target: 3,
        ),
      ];

    await _pumpHistory(
      tester,
      _dependencies(
        runs: runs,
        stories: stories,
        achievements: achievements,
      ),
    );

    expect(find.text('RUNS  1'), findsOneWidget);
    expect(find.text('Nha Trang, Vietnam'), findsOneWidget);
    expect(find.textContaining('1.25 km'), findsOneWidget);
    expect(find.text('STORY PROJECTS  1'), findsOneWidget);
    expect(find.text(story.title), findsOneWidget);
    expect(find.text('First Footstep'), findsOneWidget);
    expect(find.text('Quest Hunter'), findsOneWidget);
    expect(find.textContaining('1/1'), findsOneWidget);
    expect(find.textContaining('1/3'), findsOneWidget);
  });

  testWidgets('shows an error and retries loading history', (tester) async {
    final runs = _FlakyRunRepository();
    await _pumpHistory(tester, _dependencies(runs: runs));
    expect(find.text('History could not be loaded'), findsOneWidget);
    expect(find.textContaining('storage unavailable'), findsOneWidget);

    await tester.tap(find.text('TRY AGAIN'));
    await tester.pumpAndSettle();
    expect(find.text('Your first story starts outside'), findsOneWidget);
  });

  testWidgets('cancel keeps a run and delete removes its story and photo', (
    tester,
  ) async {
    final run = _run(withEvidence: true);
    final runs = FakeRunRepository()..summaries[run.id] = run;
    final stories = FakeStoryRepository(
      seed: [
        storyTemplates.first.createDocument(
          documentId: 'story-1',
          sourceRunId: run.id,
        ),
      ],
    );
    final photos = FakePhotoStore()..paths.add('/app/photos/evidence.jpg');
    await _pumpHistory(
      tester,
      _dependencies(runs: runs, stories: stories, photos: photos),
    );

    await tester.tap(find.byTooltip('Delete run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(runs.summaries, contains(run.id));

    await tester.tap(find.byTooltip('Delete run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DELETE'));
    await tester.pumpAndSettle();

    expect(runs.summaries, isEmpty);
    expect(await stories.list(), isEmpty);
    expect(photos.paths, isEmpty);
    expect(find.text('Run and related stories deleted.'), findsOneWidget);
  });
}

Future<void> _pumpHistory(
  WidgetTester tester,
  AppDependencies dependencies,
) async {
  await tester.pumpWidget(
    MaterialApp(home: HistoryScreen(dependencies: dependencies)),
  );
  await tester.pumpAndSettle();
}

AppDependencies _dependencies({
  FakeRunRepository? runs,
  FakeStoryRepository? stories,
  FakeAchievementRepository? achievements,
  FakePhotoStore? photos,
}) =>
    AppDependencies(
      destinations: FakeDestinationRepository(),
      runs: runs ?? FakeRunRepository(),
      stories: stories ?? FakeStoryRepository(),
      achievements: achievements ?? FakeAchievementRepository(),
      locationTracker: FakeLocationTracker(),
      photoStore: photos ?? FakePhotoStore(),
      clock: FakeClock(DateTime.utc(2026)),
      shareService: FakeShareService(),
    );

RunSummary _run({bool withEvidence = false}) => RunSummary(
      id: 'run-1',
      startedAtUtc: DateTime.utc(2026, 9, 2),
      activeDuration: const Duration(minutes: 12),
      distanceMeters: 1250,
      locationName: 'Nha Trang, Vietnam',
      track: const [],
      landmarks: const ['Tran Phu Beach'],
      quests: const [
        RunQuestResult(
          questId: 'quest-1',
          title: 'Beach frame',
          completed: true,
        ),
      ],
      evidence: withEvidence
          ? [
              QuestEvidence(
                id: 'evidence',
                questId: 'quest-1',
                photoPath: '/app/photos/evidence.jpg',
                point: GeoPoint(
                  latitude: 12.23,
                  longitude: 109.19,
                  timestampUtc: DateTime.utc(2026, 9, 2),
                ),
                capturedAtUtc: DateTime.utc(2026, 9, 2),
                caption: 'Morning beach',
              ),
            ]
          : const [],
    );

class _FlakyRunRepository extends FakeRunRepository {
  var attempts = 0;

  @override
  Future<List<RunSummary>> listSummaries() async {
    attempts++;
    if (attempts == 1) throw StateError('storage unavailable');
    return super.listSummaries();
  }
}
