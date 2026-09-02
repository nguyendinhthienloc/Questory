import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/domain/achievement.dart';
import 'package:questory/core/domain/run_models.dart';
import 'package:questory/features/history/application/achievement_checker.dart';

void main() {
  const checker = AchievementChecker();
  final now = DateTime.utc(2026, 9, 2, 1);

  test('keeps all achievements locked without saved runs', () {
    final achievements = checker.evaluate(runs: const [], nowUtc: now);
    expect(achievements, hasLength(3));
    expect(achievements.map((item) => item.progress), everyElement(0));
    expect(achievements.map((item) => item.unlocked), everyElement(isFalse));
  });

  test('unlocks First Footstep independently', () {
    final achievements = checker.evaluate(
      runs: [_run(distanceMeters: 500)],
      nowUtc: now,
    );
    expect(_byId(achievements, 'first-run').unlocked, isTrue);
    expect(_byId(achievements, 'quest-hunter').unlocked, isFalse);
    expect(_byId(achievements, 'ten-kilometers').unlocked, isFalse);
  });

  test('counts completed quests but excludes skipped quests', () {
    final achievements = checker.evaluate(
      runs: [
        _run(
          quests: const [
            RunQuestResult(questId: '1', title: '1', completed: true),
            RunQuestResult(questId: '2', title: '2', completed: true),
            RunQuestResult(
              questId: '3',
              title: '3',
              completed: false,
              skipped: true,
            ),
          ],
        ),
      ],
      nowUtc: now,
    );
    final questHunter = _byId(achievements, 'quest-hunter');
    expect(questHunter.progress, 2);
    expect(questHunter.unlocked, isFalse);
  });

  test('unlocks Quest Hunter at exactly three completed quests', () {
    final achievements = checker.evaluate(
      runs: [
        _run(
          quests: const [
            RunQuestResult(questId: '1', title: '1', completed: true),
            RunQuestResult(questId: '2', title: '2', completed: true),
            RunQuestResult(questId: '3', title: '3', completed: true),
          ],
        ),
      ],
      nowUtc: now,
    );
    expect(_byId(achievements, 'quest-hunter').unlocked, isTrue);
  });

  test('unlocks City Explorer only at ten accumulated kilometers', () {
    final below = checker.evaluate(
      runs: [_run(distanceMeters: 9999)],
      nowUtc: now,
    );
    final reached = checker.evaluate(
      runs: [
        _run(id: 'a', distanceMeters: 4500),
        _run(id: 'b', distanceMeters: 5500),
      ],
      nowUtc: now,
    );
    expect(_byId(below, 'ten-kilometers').progress, 9);
    expect(_byId(below, 'ten-kilometers').unlocked, isFalse);
    expect(_byId(reached, 'ten-kilometers').progress, 10);
    expect(_byId(reached, 'ten-kilometers').unlocked, isTrue);
  });

  test('caps progress at each achievement target', () {
    final achievements = checker.evaluate(
      runs: [
        for (var index = 0; index < 12; index++)
          _run(
            id: '$index',
            distanceMeters: 2000,
            quests: [
              RunQuestResult(
                questId: '$index',
                title: '$index',
                completed: true,
              ),
            ],
          ),
      ],
      nowUtc: now,
    );
    for (final achievement in achievements) {
      expect(achievement.progress, achievement.target);
    }
  });
}

RunSummary _run({
  String id = 'run',
  double distanceMeters = 0,
  List<RunQuestResult> quests = const [],
}) =>
    RunSummary(
      id: id,
      startedAtUtc: DateTime.utc(2026, 9, 2),
      activeDuration: const Duration(minutes: 30),
      distanceMeters: distanceMeters,
      locationName: 'Nha Trang, Vietnam',
      track: const [],
      landmarks: const [],
      quests: quests,
      evidence: const [],
    );

Achievement _byId(List<Achievement> achievements, String id) =>
    achievements.singleWhere((item) => item.id == id);
