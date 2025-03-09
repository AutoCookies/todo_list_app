import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../Models/Task.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._constructor();
  static Database? _db;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._constructor();

  final String _tasksTableName = "tasks";
  final String _tasksIdColumnName = "id";
  final String _tasksDescriptionColumnName = "description";
  final String _taskStartDateColumnName = "startDate";
  final String _tasksEndDateColumnName = "endDate";
  final String _tasksIsCompletedColumnName = "isCompleted";
  final String _tasksIsFavoriteColumnName = "isFavorite";
  final String _tasksType = "type";

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "master_db.db");

    return await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE $_tasksTableName (
          $_tasksIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT,  
          $_tasksDescriptionColumnName TEXT,
          $_taskStartDateColumnName TEXT,
          $_tasksEndDateColumnName TEXT,
          $_tasksIsCompletedColumnName INTEGER,
          $_tasksIsFavoriteColumnName INTEGER,
          $_tasksType STRING
        );
      ''');

        await db.execute('''
        CREATE TABLE completed_tasks (
          date TEXT PRIMARY KEY,
          count INTEGER DEFAULT 0
        );
      ''');
      },
    );
  }

  Future<void> updateDate(DateTime date) async {
    final db = await database;
    String formattedDate =
        date.toIso8601String().split('T')[0]; // Lấy YYYY-MM-DD

    List<Map<String, dynamic>> existing = await db.query(
      'completed_tasks',
      where: 'date = ?',
      whereArgs: [formattedDate],
    );

    if (existing.isNotEmpty) {
      int currentCount = existing.first['count'];
      await db.update(
        'completed_tasks',
        {'count': currentCount + 1},
        where: 'date = ?',
        whereArgs: [formattedDate],
      );
      print('Updated count for date $formattedDate to ${currentCount + 1}');
    } else {
      await db.insert('completed_tasks', {'date': formattedDate, 'count': 1});
    }
  }

  Future<void> decreaseDate(DateTime date) async {
    final db = await database;
    String formattedDate = date.toIso8601String().split('T')[0];

    List<Map<String, dynamic>> existing = await db.query(
      'completed_tasks',
      where: 'date = ?',
      whereArgs: [formattedDate],
    );

    if (existing.isNotEmpty) {
      int currentCount = existing.first['count'];
      if (currentCount > 0) {
        // Đảm bảo count không xuống dưới 0
        await db.update(
          'completed_tasks',
          {'count': currentCount - 1},
          where: 'date = ?',
          whereArgs: [formattedDate],
        );
        print('Updated count for date $formattedDate to ${currentCount - 1}');
      }
    }
  }

  Future<Map<DateTime, int>> getCompletedTasksByDate() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query("completed_tasks");

    Map<DateTime, int> completedTasksByDate = {};
    for (var map in maps) {
      DateTime date = DateTime.parse(map['date']);
      int count = map['count'];
      completedTasksByDate[date] = count;
    }
    return completedTasksByDate;
  }

  Future<void> addTask(Task task) async {
    final db = await database;
    await db.insert(_tasksTableName, {
      'description': task.description,
      'startDate': task.startDate.toIso8601String(),
      'endDate': task.endDate.toIso8601String(),
      'isCompleted': task.isCompleted ? 1 : 0,
      'isFavorite': task.isFavorite ? 1 : 0,
      'type': task.type, // Thêm type vào DB
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tasksTableName);

    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    int result = await db.delete(
      _tasksTableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Debugging
    print("Deleted $result row(s) from database with ID: $id");
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      _tasksTableName,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );

    print(
      "Updated task ${task.id}: type=${task.type}, isCompleted=${task.isCompleted}, isFavorite=${task.isFavorite}",
    );
  }

  Future<void> clearCompletedTasks() async {
    final db = await database;
    await db.delete('completed_tasks'); // Xóa toàn bộ bảng completed_tasks
  }
}
