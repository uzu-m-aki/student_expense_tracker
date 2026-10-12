import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('student_expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        monthly_budget REAL NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE budgets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL UNIQUE,
          monthly_budget REAL NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');
    }
  }

  // -------------------------
  // USER OPERATIONS
  // -------------------------

  Future<int> registerUser(
    String name,
    String email,
    String password,
  ) async {
    final db = await database;

    return await db.insert(
      'users',
      {
        'name': name,
        'email': email,
        'password': password,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Map<String, dynamic>?> loginUser(
    String email,
    String password,
  ) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  Future<bool> emailExists(String email) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // -------------------------
  // EXPENSE OPERATIONS
  // -------------------------

  Future<int> addExpense(
    int userId,
    String title,
    double amount,
    String category,
    String date,
    String? notes,
  ) async {
    final db = await database;

    return await db.insert(
      'expenses',
      {
        'user_id': userId,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date,
        'notes': notes,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getExpenses(
    int userId,
  ) async {
    final db = await database;

    return await db.query(
      'expenses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, id DESC',
    );
  }

  Future<Map<String, dynamic>?> getExpense(
    int id,
  ) async {
    final db = await database;

    final result = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  Future<int> updateExpense(
    int id,
    String title,
    double amount,
    String category,
    String date,
    String? notes,
  ) async {
    final db = await database;

    return await db.update(
      'expenses',
      {
        'title': title,
        'amount': amount,
        'category': category,
        'date': date,
        'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;

    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalExpenses(
    int userId,
  ) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) AS total
      FROM expenses
      WHERE user_id = ?
      ''',
      [userId],
    );

    final total = result.first['total'];

    if (total == null) {
      return 0.0;
    }

    return (total as num).toDouble();
  }

  Future<Map<String, double>> getCategoryTotals(
    int userId,
  ) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT category, SUM(amount) AS total
      FROM expenses
      WHERE user_id = ?
      GROUP BY category
      ORDER BY total DESC
      ''',
      [userId],
    );

    final Map<String, double> totals = {};

    for (final row in result) {
      final category = row['category']?.toString() ?? 'Other';

      final totalValue = row['total'];

      final total = totalValue is num
          ? totalValue.toDouble()
          : double.tryParse(
                totalValue?.toString() ?? '0',
              ) ??
              0.0;

      totals[category] = total;
    }

    return totals;
  }

  // -------------------------
  // MONTHLY BUDGET OPERATIONS
  // -------------------------

  Future<void> setMonthlyBudget(
    int userId,
    double budget,
  ) async {
    final db = await database;

    await db.insert(
      'budgets',
      {
        'user_id': userId,
        'monthly_budget': budget,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double> getMonthlyBudget(
    int userId,
  ) async {
    final db = await database;

    final result = await db.query(
      'budgets',
      columns: ['monthly_budget'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) {
      return 0.0;
    }

    final budget = result.first['monthly_budget'];

    if (budget == null) {
      return 0.0;
    }

    return (budget as num).toDouble();
  }

  Future<double> getCurrentMonthExpenses(
    int userId,
  ) async {
    final db = await database;

    final now = DateTime.now();

    final startOfMonth = DateTime(
      now.year,
      now.month,
      1,
    );

    final startOfNextMonth = DateTime(
      now.year,
      now.month + 1,
      1,
    );

    final startDate =
        '${startOfMonth.year.toString().padLeft(4, '0')}-'
        '${startOfMonth.month.toString().padLeft(2, '0')}-'
        '${startOfMonth.day.toString().padLeft(2, '0')}';

    final nextMonthDate =
        '${startOfNextMonth.year.toString().padLeft(4, '0')}-'
        '${startOfNextMonth.month.toString().padLeft(2, '0')}-'
        '${startOfNextMonth.day.toString().padLeft(2, '0')}';

    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) AS total
      FROM expenses
      WHERE user_id = ?
      AND date >= ?
      AND date < ?
      ''',
      [
        userId,
        startDate,
        nextMonthDate,
      ],
    );

    final total = result.first['total'];

    if (total == null) {
      return 0.0;
    }

    return (total as num).toDouble();
  }

  // -------------------------
  // DATABASE CLOSE
  // -------------------------

  Future<void> close() async {
    if (_database == null) return;

    await _database!.close();
    _database = null;
  }
}