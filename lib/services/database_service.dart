import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'procassa.db');

    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE iva (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL UNIQUE,
          valore REAL NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE stampanti ADD COLUMN printerCategory TEXT');
      await db.execute('ALTER TABLE stampanti ADD COLUMN orderPrinterType TEXT');
      await db.execute('ALTER TABLE stampanti ADD COLUMN bluetoothAddress TEXT');
      await db.execute('ALTER TABLE stampanti ADD COLUMN isDefault INTEGER DEFAULT 0');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE stampanti ADD COLUMN printerModel TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          total REAL NOT NULL,
          paymentMethod TEXT NOT NULL,
          isReturn INTEGER DEFAULT 0,
          notes TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE transaction_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transactionId INTEGER NOT NULL,
          productName TEXT NOT NULL,
          price REAL NOT NULL,
          quantity INTEGER NOT NULL,
          total REAL NOT NULL,
          FOREIGN KEY (transactionId) REFERENCES transactions(id)
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE transactions ADD COLUMN fiscalReceiptNumber TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN receiptISODateTime TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN zRepNumber TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN serialNumber TEXT');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE transactions ADD COLUMN status INTEGER DEFAULT 0');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categorie (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descrizione TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE iva (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL UNIQUE,
        valore REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE articoli (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descrizione TEXT NOT NULL,
        prezzo REAL NOT NULL,
        iva REAL NOT NULL,
        codice TEXT NOT NULL UNIQUE,
        categoria_id INTEGER NOT NULL,
        FOREIGN KEY (categoria_id) REFERENCES categorie(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE stampanti (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    indirizzoIp TEXT NOT NULL,
    porta INTEGER NOT NULL,
    tipoProtocollo TEXT NOT NULL,
    printerType TEXT,
    printerCategory TEXT,
    orderPrinterType TEXT,
    bluetoothAddress TEXT,
    isDefault INTEGER DEFAULT 0,
    printerModel TEXT
  )
    ''');

    await db.execute('''
      CREATE TABLE tipi_pagamento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descrizione TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        isReturn INTEGER DEFAULT 0,
        notes TEXT,
        fiscalReceiptNumber TEXT,
        receiptISODateTime TEXT,
        zRepNumber TEXT,
        serialNumber TEXT,
        status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (transactionId) REFERENCES transactions(id)
      )
    ''');
  }

  Future<int> insertCategoria(Categoria categoria) async {
    final db = await database;
    return await db.insert('categorie', categoria.toMap());
  }

  Future<List<Categoria>> getCategorias() async {
    final db = await database;
    final maps = await db.query('categorie');
    return List.generate(maps.length, (i) => Categoria.fromMap(maps[i]));
  }

  Future<int> updateCategoria(Categoria categoria) async {
    final db = await database;
    return await db.update(
      'categorie',
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  Future<int> deleteCategoria(int id) async {
    final db = await database;
    return await db.delete(
      'categorie',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertArticolo(Articolo articolo) async {
    final db = await database;
    return await db.insert('articoli', articolo.toMap());
  }

  Future<List<Articolo>> getArticoli() async {
    final db = await database;
    final maps = await db.query('articoli');
    return List.generate(maps.length, (i) => Articolo.fromMap(maps[i]));
  }

  Future<List<Articolo>> getArticoliByCategoria(int categoriaId) async {
    final db = await database;
    final maps = await db.query(
      'articoli',
      where: 'categoria_id = ?',
      whereArgs: [categoriaId],
    );
    return List.generate(maps.length, (i) => Articolo.fromMap(maps[i]));
  }

  Future<int> updateArticolo(Articolo articolo) async {
    final db = await database;
    return await db.update(
      'articoli',
      articolo.toMap(),
      where: 'id = ?',
      whereArgs: [articolo.id],
    );
  }

  Future<int> deleteArticolo(int id) async {
    final db = await database;
    return await db.delete(
      'articoli',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertStampante(Stampante stampante) async {
    final db = await database;
    return await db.insert('stampanti', stampante.toMap());
  }

  Future<List<Stampante>> getStampanti() async {
    final db = await database;
    final maps = await db.query('stampanti');
    return List.generate(maps.length, (i) => Stampante.fromMap(maps[i]));
  }

  Future<int> updateStampante(Stampante stampante) async {
    final db = await database;
    return await db.update(
      'stampanti',
      stampante.toMap(),
      where: 'id = ?',
      whereArgs: [stampante.id],
    );
  }

  Future<int> deleteStampante(int id) async {
    final db = await database;
    return await db.delete(
      'stampanti',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertTipoPagamento(TipoPagamento tipo) async {
    final db = await database;
    return await db.insert('tipi_pagamento', tipo.toMap());
  }

  Future<List<TipoPagamento>> getTipiPagamento() async {
    final db = await database;
    final maps = await db.query('tipi_pagamento');
    return List.generate(maps.length, (i) => TipoPagamento.fromMap(maps[i]));
  }

  Future<int> updateTipoPagamento(TipoPagamento tipo) async {
    final db = await database;
    return await db.update(
      'tipi_pagamento',
      tipo.toMap(),
      where: 'id = ?',
      whereArgs: [tipo.id],
    );
  }

  Future<int> deleteTipoPagamento(int id) async {
    final db = await database;
    return await db.delete(
      'tipi_pagamento',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertIVA(IVA iva) async {
    final db = await database;
    return await db.insert('iva', iva.toMap());
  }

  Future<List<IVA>> getIVAs() async {
    final db = await database;
    final maps = await db.query('iva');
    return List.generate(maps.length, (i) => IVA.fromMap(maps[i]));
  }

  Future<int> updateIVA(IVA iva) async {
    final db = await database;
    return await db.update(
      'iva',
      iva.toMap(),
      where: 'id = ?',
      whereArgs: [iva.id],
    );
  }

  Future<int> deleteIVA(int id) async {
    final db = await database;
    return await db.delete(
      'iva',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Stampante?> getEpsonReceiptPrinter() async {
    final db = await database;
    final maps = await db.query(
      'stampanti',
      where: 'printerCategory = ?',
      whereArgs: ['Receipt'],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return Stampante.fromMap(maps[0]);
  }

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> insertTransactionItem(TransactionItem item) async {
    final db = await database;
    return await db.insert('transaction_items', item.toMap());
  }

  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
    bool? isReturn,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (paymentMethod != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'paymentMethod = ?';
      whereArgs.add(paymentMethod);
    }

    if (isReturn != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'status = ?';
      whereArgs.add(isReturn ? 1 : 0);
    }

    final maps = await db.query(
      'transactions',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );

    final transactions = <Transaction>[];
    for (final map in maps) {
      final transaction = Transaction.fromMap(map as Map<String, dynamic>);
      final itemMaps = await db.query(
        'transaction_items',
        where: 'transactionId = ?',
        whereArgs: [transaction.id],
      );
      transaction.items.addAll(
        (itemMaps as List<Map<String, dynamic>>).map((m) => TransactionItem.fromMap(m)).toList(),
      );
      transactions.add(transaction);
    }

    return transactions;
  }

  Future<Transaction?> getTransactionById(int id) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;

    final transaction = Transaction.fromMap(maps[0]);
    final itemMaps = await db.query(
      'transaction_items',
      where: 'transactionId = ?',
      whereArgs: [transaction.id],
    );
    transaction.items.addAll(
      itemMaps.map((m) => TransactionItem.fromMap(m)).toList(),
    );

    return transaction;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    await db.delete(
      'transaction_items',
      where: 'transactionId = ?',
      whereArgs: [id],
    );
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateTransactionWithFiscalData(
    int transactionId,
    String? fiscalReceiptNumber,
    String? receiptISODateTime,
    String? zRepNumber,
    String? serialNumber,
  ) async {
    final db = await database;
    return await db.update(
      'transactions',
      {
        'fiscalReceiptNumber': fiscalReceiptNumber,
        'receiptISODateTime': receiptISODateTime,
        'zRepNumber': zRepNumber,
        'serialNumber': serialNumber,
      },
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<int> updateTransactionStatus(
    int transactionId,
    int status,
  ) async {
    final db = await database;
    return await db.update(
      'transactions',
      {'status': status},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }
}
