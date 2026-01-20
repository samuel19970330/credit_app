import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('credit_sales.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Customers
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        document_id TEXT UNIQUE,
        phone TEXT,
        email TEXT,
        address TEXT,
        general_debt REAL DEFAULT 0.0,
        created_at INTEGER NOT NULL
      )
    ''');

    // 2. Products (Inventory)
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sku TEXT UNIQUE,
        current_stock INTEGER DEFAULT 0,
        price REAL NOT NULL,
        cost REAL NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // 3. Inventory Transactions (Kardex)
    await db.execute('''
      CREATE TABLE inventory_transactions (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        previous_stock INTEGER NOT NULL,
        new_stock INTEGER NOT NULL,
        date INTEGER NOT NULL,
        reference_doc TEXT,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    // 4. Credits
    await db.execute('''
      CREATE TABLE credits (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        total_amount REAL NOT NULL,
        interest_rate REAL NOT NULL,
        total_with_interest REAL NOT NULL,
        start_date INTEGER NOT NULL,
        installments_count INTEGER NOT NULL,
        status TEXT NOT NULL,
        remaining_balance REAL NOT NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');

    // 5. Installments
    await db.execute('''
      CREATE TABLE installments (
        id TEXT PRIMARY KEY,
        credit_id TEXT NOT NULL,
        number INTEGER NOT NULL,
        due_date INTEGER NOT NULL,
        amount_due REAL NOT NULL,
        amount_paid REAL DEFAULT 0.0,
        status TEXT NOT NULL,
        FOREIGN KEY(credit_id) REFERENCES credits(id) ON DELETE CASCADE
      )
    ''');

    // 6. Payments
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        credit_id TEXT,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        receipt_path TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
