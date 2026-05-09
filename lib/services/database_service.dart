import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/dealer_model.dart';
import '../models/ledger_model.dart';

class DatabaseService {
  static Database? _db;
  static const String _dbName = 'dealer_ledger.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dealers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dealer_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        bill_no TEXT,
        debit REAL DEFAULT 0,
        credit REAL DEFAULT 0,
        running_total REAL DEFAULT 0,
        payment_type TEXT,
        remarks TEXT,
        FOREIGN KEY (dealer_id) REFERENCES dealers(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── Dealer CRUD ──────────────────────────────────────────────────────────────

  Future<int> insertDealer(DealerModel dealer) async {
    final db = await database;
    return db.insert('dealers', dealer.toMap()..remove('id'));
  }

  Future<List<DealerModel>> getAllDealers() async {
    final db = await database;
    final rows = await db.query('dealers', orderBy: 'name ASC');
    return rows.map(DealerModel.fromMap).toList();
  }

  Future<DealerModel?> getDealerById(int id) async {
    final db = await database;
    final rows = await db.query('dealers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return DealerModel.fromMap(rows.first);
  }

  Future<int> updateDealer(DealerModel dealer) async {
    final db = await database;
    return db.update('dealers', dealer.toMap(),
        where: 'id = ?', whereArgs: [dealer.id]);
  }

  Future<int> deleteDealer(int id) async {
    final db = await database;
    await db.delete('ledger', where: 'dealer_id = ?', whereArgs: [id]);
    return db.delete('dealers', where: 'id = ?', whereArgs: [id]);
  }

  // ── Ledger CRUD ──────────────────────────────────────────────────────────────

  Future<int> insertLedgerEntry(LedgerModel entry) async {
    final db = await database;
    return db.insert('ledger', entry.toMap()..remove('id'));
  }

  Future<List<LedgerModel>> getLedgerByDealer(int dealerId) async {
    final db = await database;
    final rows = await db.query('ledger',
        where: 'dealer_id = ?',
        whereArgs: [dealerId],
        orderBy: 'date ASC, id ASC');
    return rows.map(LedgerModel.fromMap).toList();
  }

  Future<int> updateLedgerEntry(LedgerModel entry) async {
    final db = await database;
    return db.update('ledger', entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<int> deleteLedgerEntry(int id) async {
    final db = await database;
    return db.delete('ledger', where: 'id = ?', whereArgs: [id]);
  }

  /// Returns the last running total for a dealer, or 0 if none.
  Future<double> getLastRunningTotal(int dealerId) async {
    final db = await database;
    final rows = await db.query('ledger',
        where: 'dealer_id = ?',
        whereArgs: [dealerId],
        orderBy: 'id DESC',
        limit: 1);
    if (rows.isEmpty) return 0;
    return (rows.first['running_total'] as num).toDouble();
  }

  // ── Dashboard aggregates ─────────────────────────────────────────────────────

  Future<Map<String, double>> getDashboardTotals() async {
    final db = await database;
    final debitRow = await db
        .rawQuery('SELECT COALESCE(SUM(debit), 0) as total FROM ledger');
    final creditRow = await db
        .rawQuery('SELECT COALESCE(SUM(credit), 0) as total FROM ledger');
    return {
      'totalDebit': (debitRow.first['total'] as num).toDouble(),
      'totalCredit': (creditRow.first['total'] as num).toDouble(),
    };
  }

  Future<double> getDealerBalance(int dealerId) async {
    final db = await database;
    final row = await db.rawQuery(
        'SELECT COALESCE(SUM(debit) - SUM(credit), 0) as balance FROM ledger WHERE dealer_id = ?',
        [dealerId]);
    return (row.first['balance'] as num).toDouble();
  }
}
