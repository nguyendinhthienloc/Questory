import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/domain/run_models.dart';
import 'package:questory/features/history/application/achievement_checker.dart';

void main() {
  test('unlocks personal achievements from saved run progress', () {
    final run = RunSummary(
      id: 'run',
      startedAtUtc: DateTime.utc(2026, 9, 2),
      activeDuration: const Duration(minutes: 30),
      distanceMeters: 10000,
      locationName: 'Nha Trang, Vietnam',
      track: const [],
      landmarks: const [],
      quests: const [
        RunQuestResult(questId: '1', title: '1', completed: true),
        RunQuestResult(questId: '2', title: '2', completed: true),
        RunQuestResult(questId: '3', title: '3', completed: true),
      ],
      evidence: const [],
    );

    final achievements = const AchievementChecker().evaluate(
      runs: [run],
      nowUtc: DateTime.utc(2026, 9, 2, 1),
    );

    expect(achievements.map((item) => item.unlocked), everyElement(isTrue));
  });
}
