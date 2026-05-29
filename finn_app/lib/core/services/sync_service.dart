import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../../shared/models/gasto.dart';
import '../../shared/models/meta_ahorro.dart';
import '../../shared/models/aporte_ahorro.dart';
import '../../shared/models/recordatorio.dart';
import '../../shared/services/database_helper.dart';
import '../../shared/services/user_preferences.dart';
import '../../shared/services/data_refresh_notifier.dart';

class SyncService {
  static final _instance = SyncService._();
  factory SyncService() => _instance;
  SyncService._();

  final _db = DatabaseHelper();
  SupabaseClient get _client => SupabaseService.client;
  String? get _uid => SupabaseService.userId;
  bool get _isSignedIn => SupabaseService.isSignedIn;

  // ── Fire-and-forget helpers ───────────────────────────────────────────────

  void syncGastosAsync() {
    if (!_isSignedIn) return;
    _syncGastos().catchError((_) {});
  }

  void syncMetasAsync() {
    if (!_isSignedIn) return;
    _syncMetas().catchError((_) {});
    _syncAportes().catchError((_) {});
  }

  void syncAportesAsync() {
    if (!_isSignedIn) return;
    _syncAportes().catchError((_) {});
  }

  void syncRecordatoriosAsync() {
    if (!_isSignedIn) return;
    _syncRecordatorios().catchError((_) {});
  }

  // ── Push (local → cloud) ─────────────────────────────────────────────────

  Future<void> _syncGastos() async {
    final gastos = await _db.getGastos();
    await _client.from('gastos').delete().eq('user_id', _uid!);
    if (gastos.isEmpty) return;
    await _client.from('gastos').insert(gastos.map((g) => {
          'user_id': _uid,
          'local_id': g.id,
          'nombre': g.nombre,
          'categoria': g.categoria,
          'monto': g.monto,
          'fecha': g.fecha.toIso8601String(),
          'es_fijo': g.esFijo,
        }).toList());
  }

  Future<void> _syncMetas() async {
    final metas = await _db.getMetas();
    await _client.from('metas_ahorro').delete().eq('user_id', _uid!);
    if (metas.isEmpty) return;
    await _client.from('metas_ahorro').insert(metas.map((m) => {
          'user_id': _uid,
          'local_id': m.id,
          'nombre': m.nombre,
          'monto_objetivo': m.montoObjetivo,
          'fecha_limite': m.fechaLimite.toIso8601String().split('T').first,
        }).toList());
  }

  Future<void> _syncAportes() async {
    final metas = await _db.getMetas();
    final allAportes = <Map<String, dynamic>>[];
    for (final m in metas) {
      if (m.id == null) continue;
      final aportes = await _db.getAportesByMeta(m.id!);
      for (final a in aportes) {
        allAportes.add({
          'user_id': _uid,
          'local_id': a.id,
          'meta_local_id': a.metaId,
          'monto': a.monto,
          'fecha': a.fecha.toIso8601String(),
        });
      }
    }
    await _client.from('aportes_ahorro').delete().eq('user_id', _uid!);
    if (allAportes.isNotEmpty) {
      await _client.from('aportes_ahorro').insert(allAportes);
    }
  }

  Future<void> _syncRecordatorios() async {
    final list = await _db.getRecordatorios();
    await _client.from('recordatorios').delete().eq('user_id', _uid!);
    if (list.isEmpty) return;
    await _client.from('recordatorios').insert(list.map((r) => {
          'user_id': _uid,
          'local_id': r.id,
          'titulo': r.titulo,
          'monto': r.monto,
          'fecha': r.fecha.toIso8601String(),
          'completo': r.completo,
        }).toList());
  }

  Future<void> _syncProfile() async {
    final prefs = UserPreferences();
    final nombre = await prefs.getUserName() ?? '';
    final ingreso = await prefs.getUserIncome() ?? 0;
    await _client.from('user_profiles').upsert({
      'id': _uid,
      'nombre': nombre,
      'ingreso_mensual': ingreso,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ── Full upload (called on first sign-in) ────────────────────────────────

  Future<void> uploadAll() async {
    if (!_isSignedIn) return;
    try {
      await _syncGastos();
      await _syncMetas();
      await _syncAportes();
      await _syncRecordatorios();
      await _syncProfile();
    } catch (_) {}
  }

  // ── Pull (cloud → local) ─────────────────────────────────────────────────

  Future<void> pullAll() async {
    if (!_isSignedIn) return;
    final uid = _uid!;
    try {
      // Gastos
      final gastosData =
          await _client.from('gastos').select().eq('user_id', uid);
      await _db.clearGastos();
      for (final g in gastosData) {
        await _db.insertGasto(Gasto(
          nombre: g['nombre'] as String,
          categoria: g['categoria'] as String,
          monto: (g['monto'] as num).toDouble(),
          fecha: DateTime.parse(g['fecha'] as String),
          esFijo: g['es_fijo'] as bool? ?? false,
        ));
      }

      // Metas — build map old_local_id → new_sqlite_id for aporte linking
      final metasData =
          await _client.from('metas_ahorro').select().eq('user_id', uid);
      await _db.clearAportes();
      await _db.clearMetas();
      final Map<int, int> metaIdMap = {};
      for (final m in metasData) {
        final newId = await _db.insertMeta(MetaAhorro(
          nombre: m['nombre'] as String,
          montoObjetivo: (m['monto_objetivo'] as num).toDouble(),
          fechaLimite: DateTime.parse(m['fecha_limite'] as String),
        ));
        final oldId = m['local_id'] as int?;
        if (oldId != null) metaIdMap[oldId] = newId;
      }

      // Aportes — re-link to new local meta IDs
      final aportesData =
          await _client.from('aportes_ahorro').select().eq('user_id', uid);
      for (final a in aportesData) {
        final metaLocalId = a['meta_local_id'] as int?;
        if (metaLocalId == null) continue;
        final newMetaId = metaIdMap[metaLocalId];
        if (newMetaId == null) continue;
        await _db.insertAporte(AporteAhorro(
          metaId: newMetaId,
          monto: (a['monto'] as num).toDouble(),
          fecha: DateTime.parse(a['fecha'] as String),
        ));
      }

      // Recordatorios
      final recData =
          await _client.from('recordatorios').select().eq('user_id', uid);
      await _db.clearRecordatorios();
      for (final r in recData) {
        await _db.insertRecordatorio(Recordatorio(
          titulo: r['titulo'] as String,
          monto: (r['monto'] as num).toDouble(),
          fecha: DateTime.parse(r['fecha'] as String),
          completo: r['completo'] as bool? ?? false,
        ));
      }

      // Profile
      final profileData = await _client
          .from('user_profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (profileData != null) {
        final prefs = UserPreferences();
        if (profileData['nombre'] != null) {
          await prefs.setUserName(profileData['nombre'] as String);
        }
        if (profileData['ingreso_mensual'] != null) {
          await prefs.setUserIncome(
              (profileData['ingreso_mensual'] as num).toDouble());
        }
      }

      DataRefreshNotifier().refresh();
    } catch (_) {
      // Fail silently — local data remains available offline
    }
  }
}
