import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/gasto.dart';
import '../models/meta_ahorro.dart';
import '../models/aporte_ahorro.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'finanzas_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE gastos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        categoria TEXT,
        monto REAL,
        fecha TEXT,
        esFijo INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE metas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        montoObjetivo REAL,
        fechaLimite TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE aportes_ahorro(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        metaId INTEGER,
        monto REAL,
        fecha TEXT,
        FOREIGN KEY (metaId) REFERENCES metas (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- CRUD Gastos ---
  Future<int> insertGasto(Gasto gasto) async {
    final db = await database;
    return await db.insert('gastos', gasto.toMap());
  }

  Future<List<Gasto>> getGastos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('gastos', orderBy: 'fecha DESC');
    return List.generate(maps.length, (i) => Gasto.fromMap(maps[i]));
  }

  Future<int> deleteGasto(int id) async {
    final db = await database;
    return await db.delete('gastos', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD Metas ---
  Future<int> insertMeta(MetaAhorro meta) async {
    final db = await database;
    return await db.insert('metas', meta.toMap());
  }

  Future<List<MetaAhorro>> getMetas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('metas');
    return List.generate(maps.length, (i) => MetaAhorro.fromMap(maps[i]));
  }

  // --- CRUD Aportes ---
  Future<int> insertAporte(AporteAhorro aporte) async {
    final db = await database;
    return await db.insert('aportes_ahorro', aporte.toMap());
  }

  Future<List<AporteAhorro>> getAportesByMeta(int metaId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'aportes_ahorro',
      where: 'metaId = ?',
      whereArgs: [metaId],
      orderBy: 'fecha DESC',
    );
    return List.generate(maps.length, (i) => AporteAhorro.fromMap(maps[i]));
  }
}
