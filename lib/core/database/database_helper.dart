import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('credit_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    // Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id $idType,
        name $textType,
        documentId $textType,
        phone $textNullable,
        email $textNullable,
        address $textNullable,
        generalDebt $realType,
        createdAt $textType
      )
    ''');

    // Credits Table
    await db.execute('''
      CREATE TABLE credits (
        id $idType,
        customerId $textType,
        totalAmount $realType,
        interestRate $realType,
        totalWithInterest $realType,
        startDate $textType,
        installmentsCount $integerType,
        status $textType,
        remainingBalance $realType,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Credit Items Table
    await db.execute('''
      CREATE TABLE credit_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        creditId $textType,
        productId $textType,
        productName $textType,
        unitPrice $realType,
        quantity $integerType,
        subtotal $realType,
        FOREIGN KEY (creditId) REFERENCES credits (id) ON DELETE CASCADE
      )
    ''');

    // Installments Table
    await db.execute('''
      CREATE TABLE installments (
        id $idType,
        creditId $textType,
        number $integerType,
        amount $realType,
        dueDate $textType,
        paymentDate $textNullable,
        isPaid $integerType,
        capitalAmount $realType,
        interestAmount $realType,
        FOREIGN KEY (creditId) REFERENCES credits (id) ON DELETE CASCADE
      )
    ''');

    // Products Table
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        name $textType,
        sku $textType,
        currentStock $integerType,
        price $realType,
        cost $realType,
        isActive $integerType
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE products (
          id $idType,
          name $textType,
          sku $textType,
          currentStock $integerType,
          price $realType,
          cost $realType,
          isActive $integerType
        )
      ''');
    }

    if (oldVersion < 3) {
      // Add credit_items table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS credit_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          creditId $textType,
          productId $textType,
          productName $textType,
          unitPrice $realType,
          quantity $integerType,
          subtotal $realType,
          FOREIGN KEY (creditId) REFERENCES credits (id) ON DELETE CASCADE
        )
      ''');

      // Add installments table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS installments (
          id $idType,
          creditId $textType,
          number $integerType,
          amount $realType,
          dueDate $textType,
          paymentDate $textNullable,
          isPaid $integerType,
          capitalAmount $realType,
          interestAmount $realType,
          FOREIGN KEY (creditId) REFERENCES credits (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
