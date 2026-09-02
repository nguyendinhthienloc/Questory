import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/contracts/achievement_repository.dart';
import '../../core/domain/achievement.dart';
import '../local/questory_database.dart';

class SqliteAchievementRepository implements AchievementRepository {
  SqliteAchievementRepository(this._database);

  final QuestoryDatabase _database;

  @override
  Future<List<Achievement>> list() async {
    final rows = await _database.database.query('achievement');
    return List.unmodifiable(
      rows.map(
        (row) => Achievement.fromJson(
          Map<String, Object?>.from(
            jsonDecode(row['json']! as String),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> saveAll(List<Achievement> achievements) async {
    await _database.database.transaction((transaction) async {
      final batch = transaction.batch();
      for (final achievement in achievements) {
        batch.insert(
          'achievement',
          {
            'id': achievement.id,
            'json': jsonEncode(achievement.toJson()),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }
}
