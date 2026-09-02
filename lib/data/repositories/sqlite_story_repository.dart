import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/contracts/story_repository.dart';
import '../../core/domain/story_project.dart';
import '../local/questory_database.dart';

class SqliteStoryRepository implements StoryRepository {
  SqliteStoryRepository(this._database);

  final QuestoryDatabase _database;

  @override
  Future<void> save(StoryDocument document) async {
    await _database.database.insert(
      'story_project',
      {
        'id': document.id,
        'json': jsonEncode(document.toJson()),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<StoryDocument?> load(String documentId) async {
    final rows = await _database.database.query(
      'story_project',
      where: 'id = ?',
      whereArgs: [documentId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _decode(rows.first['json']! as String);
  }

  @override
  Future<List<StoryDocument>> list() async {
    final rows = await _database.database.query(
      'story_project',
      orderBy: 'updated_at DESC',
    );
    return List.unmodifiable(
        rows.map((row) => _decode(row['json']! as String)));
  }

  StoryDocument _decode(String source) => StoryDocument.fromJson(
        Map<String, Object?>.from(jsonDecode(source)),
      );
}
