import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/contracts/run_repository.dart';
import '../../core/domain/run_session.dart';
import '../../core/domain/run_models.dart';
import '../local/questory_database.dart';

class SqliteRunRepository implements RunRepository {
  SqliteRunRepository(this._database);

  final QuestoryDatabase _database;

  @override
  Future<void> saveActive(RunSession session) async {
    await _database.database.transaction((transaction) async {
      await transaction.delete('active_run');
      await transaction.insert('active_run', {
        'id': session.id,
        'json': jsonEncode(session.toJson()),
        'updated_at': session.updatedAtUtc.toIso8601String(),
      });
    });
  }

  @override
  Future<RunSession?> loadActive() async {
    final rows = await _database.database.query('active_run', limit: 1);
    if (rows.isEmpty) return null;
    return RunSession.fromJson(
      Map<String, Object?>.from(jsonDecode(rows.first['json']! as String)),
    );
  }

  @override
  Future<void> clearActive() => _database.database.delete('active_run');

  @override
  Future<void> saveSummary(RunSummary summary) async {
    await _database.database.insert(
      'run_summary',
      {
        'id': summary.id,
        'json': jsonEncode(summary.toJson()),
        'started_at': summary.startedAtUtc.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<RunSummary?> getSummary(String id) async {
    final rows = await _database.database.query(
      'run_summary',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _decodeSummary(rows.first['json']! as String);
  }

  @override
  Future<List<RunSummary>> listSummaries() async {
    final rows = await _database.database.query(
      'run_summary',
      orderBy: 'started_at DESC',
    );
    return List.unmodifiable(
      rows.map((row) => _decodeSummary(row['json']! as String)),
    );
  }

  @override
  Future<void> deleteSummary(String id) => _database.database.delete(
        'run_summary',
        where: 'id = ?',
        whereArgs: [id],
      );

  RunSummary _decodeSummary(String source) => RunSummary.fromJson(
        Map<String, Object?>.from(jsonDecode(source)),
      );
}
