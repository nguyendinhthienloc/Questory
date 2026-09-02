import '../domain/achievement.dart';

abstract interface class AchievementRepository {
  Future<List<Achievement>> list();

  Future<void> saveAll(List<Achievement> achievements);
}
