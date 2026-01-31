import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future initDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'my_app.db');

  return openDatabase(
    path,
    version: 1,
    onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          done INTEGER
        )
      ''');
    },
  );
}