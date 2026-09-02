import 'package:sqflite/sqflite.dart';

class QuestoryDatabase {
  QuestoryDatabase._(this.database);

  final Database database;

  static Future<QuestoryDatabase> open() async {
    final base = await getDatabasesPath();
    final database = await openDatabase(
      '$base/questory.db',
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE active_run (
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE run_summary (
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            started_at TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE story_project (
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE achievement (
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL
          )
        ''');
      },
    );
    return QuestoryDatabase._(database);
  }
}
