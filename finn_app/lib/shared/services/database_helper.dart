import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/gasto.dart';
import '../models/meta_ahorro.dart';
import '../models/aporte_ahorro.dart';
import '../models/presupuesto.dart';
import '../models/recordatorio.dart';
import '../models/ingreso_extra.dart';

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
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    String path = join(await getDatabasesPath(), 'finanzas_app.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    await db.execute('''
      CREATE TABLE presupuestos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoria TEXT NOT NULL UNIQUE,
        limite REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE recordatorios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        completo INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ingresos_extras(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descripcion TEXT NOT NULL,
        categoria TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS presupuestos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          categoria TEXT NOT NULL UNIQUE,
          limite REAL NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recordatorios(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          titulo TEXT NOT NULL,
          monto REAL NOT NULL,
          fecha TEXT NOT NULL,
          completo INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ingresos_extras(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          descripcion TEXT NOT NULL,
          categoria TEXT NOT NULL,
          monto REAL NOT NULL,
          fecha TEXT NOT NULL
        )
      ''');
    }
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

  Future<int> updateGasto(Gasto gasto) async {
    final db = await database;
    return await db.update('gastos', gasto.toMap(),
        where: 'id = ?', whereArgs: [gasto.id]);
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

  Future<int> deleteMeta(int id) async {
    final db = await database;
    await db.delete('aportes_ahorro', where: 'metaId = ?', whereArgs: [id]);
    return await db.delete('metas', where: 'id = ?', whereArgs: [id]);
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

  Future<double> getTotalAportesByMeta(int metaId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) AS total FROM aportes_ahorro WHERE metaId = ?',
      [metaId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalAportes() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) AS total FROM aportes_ahorro',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> updateAporte(AporteAhorro aporte) async {
    final db = await database;
    return await db.update('aportes_ahorro', aporte.toMap(),
        where: 'id = ?', whereArgs: [aporte.id]);
  }

  Future<int> deleteAporte(int id) async {
    final db = await database;
    return await db.delete('aportes_ahorro', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD Presupuestos ---
  Future<int> insertPresupuesto(Presupuesto p) async {
    final db = await database;
    return await db.insert('presupuestos', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Presupuesto>> getPresupuestos() async {
    final db = await database;
    final maps = await db.query('presupuestos', orderBy: 'categoria ASC');
    return maps.map((m) => Presupuesto.fromMap(m)).toList();
  }

  Future<int> updatePresupuesto(Presupuesto p) async {
    final db = await database;
    return await db.update('presupuestos', p.toMap(),
        where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> deletePresupuesto(int id) async {
    final db = await database;
    return await db.delete('presupuestos', where: 'id = ?', whereArgs: [id]);
  }

  /// Get total spent per category for current month
  Future<Map<String, double>> getGastosPorCategoriaMesActual() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).toIso8601String();
    final end = DateTime(now.year, now.month + 1, 1).toIso8601String();
    final result = await db.rawQuery('''
      SELECT categoria, SUM(monto) as total
      FROM gastos
      WHERE fecha >= ? AND fecha < ?
      GROUP BY categoria
    ''', [start, end]);
    final map = <String, double>{};
    for (final row in result) {
      map[row['categoria'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }

  // --- CRUD Recordatorios ---
  Future<int> insertRecordatorio(Recordatorio r) async {
    final db = await database;
    return await db.insert('recordatorios', r.toMap());
  }

  Future<List<Recordatorio>> getRecordatorios() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('recordatorios', orderBy: 'fecha ASC');
    return List.generate(maps.length, (i) => Recordatorio.fromMap(maps[i]));
  }

  Future<int> deleteRecordatorio(int id) async {
    final db = await database;
    return await db.delete('recordatorios', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateRecordatorio(Recordatorio r) async {
    final db = await database;
    return await db.update('recordatorios', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  }

  // --- CRUD Ingresos Extras ---
  Future<int> insertIngresoExtra(IngresoExtra ingreso) async {
    final db = await database;
    return await db.insert('ingresos_extras', ingreso.toMap());
  }

  Future<List<IngresoExtra>> getIngresosExtras() async {
    final db = await database;
    final maps = await db.query('ingresos_extras', orderBy: 'fecha DESC');
    return maps.map((m) => IngresoExtra.fromMap(m)).toList();
  }

  Future<double> getTotalIngresosExtras() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) AS total FROM ingresos_extras',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> deleteIngresoExtra(int id) async {
    final db = await database;
    return await db.delete('ingresos_extras', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearIngresosExtras() async {
    final db = await database;
    await db.delete('ingresos_extras');
  }

  // --- Utilidad: borrar por tabla (para sync pull) ---
  Future<void> clearGastos() async {
    final db = await database;
    await db.delete('gastos');
  }

  Future<void> clearMetas() async {
    final db = await database;
    await db.delete('metas');
  }

  Future<void> clearAportes() async {
    final db = await database;
    await db.delete('aportes_ahorro');
  }

  Future<void> clearRecordatorios() async {
    final db = await database;
    await db.delete('recordatorios');
  }

  // --- Utilidad: borrar todo (para reset) ---
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('aportes_ahorro');
    await db.delete('metas');
    await db.delete('gastos');
    await db.delete('presupuestos');
    await db.delete('recordatorios');
    await db.delete('ingresos_extras');
  }
}
