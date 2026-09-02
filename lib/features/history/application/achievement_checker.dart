import '../../../core/domain/achievement.dart';
import '../../../core/domain/run_models.dart';

class AchievementChecker {
  const AchievementChecker();

  List<Achievement> evaluate({
    required List<RunSummary> runs,
    required DateTime nowUtc,
  }) {
    final completedQuests = runs
        .expand((run) => run.quests)
        .where((quest) => quest.completed)
        .length;
    final totalDistance = runs.fold<double>(
      0,
      (value, run) => value + run.distanceMeters,
    );
    return [
      _achievement(
        id: 'first-run',
        title: 'First Footstep',
        description: 'Complete your first Questory run.',
        progress: runs.length,
        target: 1,
        nowUtc: nowUtc,
      ),
      _achievement(
        id: 'quest-hunter',
        title: 'Quest Hunter',
        description: 'Complete three photo quests.',
        progress: completedQuests,
        target: 3,
        nowUtc: nowUtc,
      ),
      _achievement(
        id: 'ten-kilometers',
        title: 'City Explorer',
        description: 'Record ten total kilometers.',
        progress: (totalDistance / 1000).floor(),
        target: 10,
        nowUtc: nowUtc,
      ),
    ];
  }

  Achievement _achievement({
    required String id,
    required String title,
    required String description,
    required int progress,
    required int target,
    required DateTime nowUtc,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      progress: progress.clamp(0, target),
      target: target,
      unlockedAtUtc: progress >= target ? nowUtc.toUtc() : null,
    );
  }
}
