import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'CounterRepository.dart';

const TAG = "dsTAG";

class DsByPreference implements IRepository {
  @override
  Future<String> get(String key) async {
    var instance = await SharedPreferences.getInstance();
    var string = instance.getString(key);
    print("$TAG get DsByPreference: ${string}");
    return string;
  }

  @override
  Future<bool> save(String key, String value) async {
    var instance = await SharedPreferences.getInstance();
    return instance.setString(key, value);
  }
}

class DsByFile implements IRepository {
  get basePath async {
    var applicationDocumentsDirectory =
        await getApplicationDocumentsDirectory();
    return applicationDocumentsDirectory.path;
  }

  Future<File> getGoalFile(String cacheFileSuffix) async {
    var file = new File('${await basePath}/temp_$cacheFileSuffix.txt');
    if (!file.existsSync()) {
      print("$TAG create getGoalFile: ${file.path}");
      await file.create(recursive: true);
    }
    return file;
  }

  @override
  Future<String> get(String key) async {
    var file = await getGoalFile(key);
    return await file.readAsString();
  }

  @override
  Future<bool> save(String key, String value) async {
    var file = await getGoalFile(key);
    await file.writeAsString(value);
    return true;
  }
}

class DsByDataBase implements IRepository {
  Future<Database> database;
  String tableName;

  DsByDataBase(this.tableName);

  Future<Database> getDb() async {
    if (database != null) {
      return database;
    }
    return openDatabase(
        // Set the path to the database. Note: Using the `join` function from the
        // `path` package is best practice to ensure the path is correctly
        // constructed for each platform.
        join(await getDatabasesPath(), 'temp_db.db'),
        version: 1, onCreate: (db, version) {
      return db
          .execute('CREATE TABLE $tableName(key TEXT PRIMARY KEY, value TEXT)');
    });
  }

  @override
  Future<String> get(String key) async {
    var database = await getDb();
    var list = await database.query(tableName,
        columns: ['value'], where: 'key = ?', whereArgs: [key]);
    print("$TAG DsByDataBase get  ${list} ");
    if (list.length > 0) {
      return list[0].cast()['value'];
    }
    return null;
  }

  @override
  Future<bool> save(String key, String value) async {
    var database = await getDb();
    var values = {'key': key, 'value': value};
    var insertRow = await database.insert(tableName, values,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return insertRow > 0;
  }
}
