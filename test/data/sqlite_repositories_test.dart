import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/domain/achievement.dart';
import 'package:questory/core/domain/run_models.dart';
import 'package:questory/core/domain/run_session.dart';
import 'package:questory/data/local/questory_database.dart';
import 'package:questory/data/repositories/sqlite_achievement_repository.dart';
import 'package:questory/data/repositories/sqlite_run_repository.dart';
import 'package:questory/data/repositories/sqlite_story_repository.dart';
import 'package:questory/features/story_studio/data/story_templates.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Directory temporaryDirectory;
  late String databasePath;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'questory-sqlite-test-',
    );
    databasePath = '${temporaryDirectory.path}${Platform.pathSeparator}test.db';
  });

  tearDown(() async {
    await databaseFactoryFfi.deleteDatabase(databasePath);
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('active checkpoint and completed run survive database restart',
      () async {
    var database = await _open(databasePath);
    var repository = SqliteRunRepository(database);
    final session = _session();
    final summary = _summary(id: 'completed');

    await repository.saveActive(session);
    await repository.saveSummary(summary);
    await database.database.close();

    database = await _open(databasePath);
    repository = SqliteRunRepository(database);
    final restoredSession = await repository.loadActive();
    final restoredSummary = await repository.getSummary(summary.id);

    expect(restoredSession?.id, session.id);
    expect(restoredSession?.track.single.latitude, 12.2388);
    expect(restoredSession?.evidence.single.caption, 'First light');
    expect(restoredSummary?.distanceMeters, summary.distanceMeters);
    expect(restoredSummary?.track.single.longitude, 109.1967);
    expect(restoredSummary?.evidence.single.photoPath,
        summary.evidence.single.photoPath);
    await database.database.close();
  });

  test('stories and achievements survive database restart', () async {
    var database = await _open(databasePath);
    var stories = SqliteStoryRepository(database);
    var achievements = SqliteAchievementRepository(database);
    final story = storyTemplates.first.createDocument(
      documentId: 'story-1',
      sourceRunId: 'run-1',
    );
    final achievement = Achievement(
      id: 'first-run',
      title: 'First Footstep',
      description: 'Complete your first Questory run.',
      progress: 1,
      target: 1,
      unlockedAtUtc: DateTime.utc(2026, 9, 2, 1),
    );

    await stories.save(story);
    await achievements.saveAll([achievement]);
    await database.database.close();

    database = await _open(databasePath);
    stories = SqliteStoryRepository(database);
    achievements = SqliteAchievementRepository(database);

    expect((await stories.load(story.id))?.sourceRunId, 'run-1');
    final restoredAchievements = await achievements.list();
    expect(restoredAchievements.single.id, achievement.id);
    expect(
        restoredAchievements.single.unlockedAtUtc, achievement.unlockedAtUtc);
    await database.database.close();
  });

  test('deletion is isolated to the selected run and its stories', () async {
    final database = await _open(databasePath);
    final runs = SqliteRunRepository(database);
    final stories = SqliteStoryRepository(database);
    final first = _summary(id: 'run-a');
    final second = _summary(id: 'run-b');
    final firstStory = storyTemplates.first.createDocument(
      documentId: 'story-a',
      sourceRunId: first.id,
    );
    final secondStory = storyTemplates.last.createDocument(
      documentId: 'story-b',
      sourceRunId: second.id,
    );

    await runs.saveSummary(first);
    await runs.saveSummary(second);
    await stories.save(firstStory);
    await stories.save(secondStory);
    await stories.deleteForRun(first.id);
    await runs.deleteSummary(first.id);

    expect(await runs.getSummary(first.id), isNull);
    expect(await stories.load(firstStory.id), isNull);
    expect(await runs.getSummary(second.id), isNotNull);
    expect(await stories.load(secondStory.id), isNotNull);
    await database.database.close();
  });
}

Future<QuestoryDatabase> _open(String path) => QuestoryDatabase.open(
      factory: databaseFactoryFfi,
      path: path,
    );

RunSession _session() => RunSession(
      id: 'active',
      cityId: 'nha-trang',
      locationName: 'Nha Trang, Vietnam',
      routeId: 'waterfront',
      startedAtUtc: DateTime.utc(2026, 9, 2),
      updatedAtUtc: DateTime.utc(2026, 9, 2, 0, 10),
      lifecycle: RunLifecycle.paused,
      accumulatedActiveDuration: const Duration(minutes: 10),
      track: [_point()],
      evidence: [_evidence()],
      completedQuestIds: const {'quest-1'},
      skippedQuestIds: const {},
    );

RunSummary _summary({required String id}) => RunSummary(
      id: id,
      startedAtUtc: DateTime.utc(2026, 9, 2),
      activeDuration: const Duration(minutes: 30),
      distanceMeters: 3210,
      averagePaceSecondsPerKilometer: 360,
      locationName: 'Nha Trang, Vietnam',
      track: [_point()],
      landmarks: const ['Tran Phu Beach'],
      quests: const [
        RunQuestResult(
          questId: 'quest-1',
          title: 'First light',
          completed: true,
        ),
      ],
      evidence: [_evidence()],
      estimatedCalories: 193,
    );

GeoPoint _point() => GeoPoint(
      latitude: 12.2388,
      longitude: 109.1967,
      timestampUtc: DateTime.utc(2026, 9, 2, 0, 5),
      accuracyMeters: 5,
    );

QuestEvidence _evidence() => QuestEvidence(
      id: 'evidence-1',
      questId: 'quest-1',
      photoPath: '/app/questory_photos/evidence-1.jpg',
      point: _point(),
      capturedAtUtc: DateTime.utc(2026, 9, 2, 0, 6),
      caption: 'First light',
    );
