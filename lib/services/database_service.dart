import 'package:sqflite/sqflite.dart';
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
      version: 4,
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
}
