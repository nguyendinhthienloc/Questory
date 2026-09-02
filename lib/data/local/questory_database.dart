import 'package:sqflite/sqflite.dart';

class QuestoryDatabase {
  QuestoryDatabase._(this.database);

  static const schemaVersion = 1;

  final Database database;

  static Future<QuestoryDatabase> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final selectedFactory = factory ?? databaseFactory;
    final databasePath = path ?? '${await getDatabasesPath()}/questory.db';
    final database = await selectedFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await _createSchema(database);
        },
        onUpgrade: _upgrade,
      ),
    );
    return QuestoryDatabase._(database);
  }

  static Future<void> _createSchema(Database database) async {
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
  }

  static Future<void> _upgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    throw StateError(
      'Missing Questory database migration from v$oldVersion to v$newVersion.',
    );
  }
}
