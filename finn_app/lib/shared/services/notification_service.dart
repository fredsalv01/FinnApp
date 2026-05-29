import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../core/services/auth_service.dart';
import 'database_helper.dart';
import 'user_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      // Configurar zona horaria local por defecto
      const String timeZoneName = 'America/Lima'; // Por defecto o Lima
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Error inicializando timezone: $e');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    try {
      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notificación presionada: ${details.payload}');
        },
      );
      _initialized = true;
      debugPrint('NotificationService inicializado correctamente.');
    } catch (e) {
      debugPrint('Error al inicializar las notificaciones locales: $e');
    }
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    } else if (Platform.isIOS || Platform.isMacOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // --- Mostrar Notificación Inmediata ---
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'finn_alerts_channel',
      'Alertas Finn',
      channelDescription: 'Alertas y notificaciones inmediatas de Finn',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    try {
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error al mostrar notificación: $e');
    }
  }

  // --- Programar Notificación (Para Recordatorios de Pago) ---
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_initialized) await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'finn_reminders_channel',
      'Recordatorios Finn',
      channelDescription: 'Recordatorios programados de pago de Finn',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    try {
      // Si la fecha programada ya pasó, la programamos para dentro de 5 segundos para fines de prueba
      DateTime targetDate = scheduledDate;
      if (targetDate.isBefore(DateTime.now())) {
        targetDate = DateTime.now().add(const Duration(seconds: 5));
      }

      await _localNotifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(targetDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('Recordatorio programado ID $id para la fecha: $targetDate');
    } catch (e) {
      debugPrint('Error al programar notificación: $e');
      // Intento alternativo sin programar si falla zonedSchedule
      await showNotification(id: id, title: title, body: '$body (Programado para hoy)');
    }
  }

  // --- Cancelar Notificación ---
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id: id);
      debugPrint('Notificación ID $id cancelada.');
    } catch (e) {
      debugPrint('Error al cancelar notificación: $e');
    }
  }

  // --- Canal para notificaciones inteligentes ---
  static const _smartDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'finn_smart_channel',
      'Recordatorios inteligentes',
      channelDescription: 'Notificaciones automáticas de Finn',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  // --- Programar Notificaciones Inteligentes (llamar al inicio de la app) ---
  Future<void> scheduleSmartNotifications() async {
    if (!_initialized) await init();
    await _scheduleDailyGastoReminder();
    await _scheduleMonthlyEndSummary();
  }

  Future<void> _scheduleDailyGastoReminder() async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 18, 0);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _localNotifications.zonedSchedule(
        id: 900,
        title: '¿Tuviste algún gasto hoy?',
        body: 'Anota tus movimientos del día para mantener el control de tus finanzas.',
        scheduledDate: scheduled,
        notificationDetails: _smartDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error programando recordatorio diario: $e');
    }
  }

  Future<void> _scheduleMonthlyEndSummary() async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, 28, 20, 0);
      if (scheduled.isBefore(now)) {
        final nextMonth = now.month == 12 ? 1 : now.month + 1;
        final nextYear = now.month == 12 ? now.year + 1 : now.year;
        scheduled = tz.TZDateTime(tz.local, nextYear, nextMonth, 28, 20, 0);
      }
      await _localNotifications.zonedSchedule(
        id: 901,
        title: '¿Cómo estuvo tu mes?',
        body: 'Abre Finn y revisa tu resumen financiero del mes.',
        scheduledDate: scheduled,
        notificationDetails: _smartDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } catch (e) {
      debugPrint('Error programando resumen mensual: $e');
    }
  }

  // Llamar desde Dashboard para chequeos puntuales (máx 1 vez por semana cada uno)
  Future<void> checkAndNotifyGoogleAccount() async {
    if (AuthService().isSignedIn) return;
    final prefs = UserPreferences();
    final last = await prefs.getLastNotifDate('google_account');
    if (last != null && DateTime.now().difference(last).inDays < 7) return;
    await prefs.setLastNotifDate('google_account');
    await showNotification(
      id: 902,
      title: '☁️ Protege tus datos',
      body: 'Conecta tu cuenta Google para hacer backup automático en la nube.',
    );
  }

  Future<void> checkAndNotifyNoGastosThisMonth() async {
    final now = DateTime.now();
    if (now.day < 5) return;
    final prefs = UserPreferences();
    final last = await prefs.getLastNotifDate('no_gastos_mes');
    if (last != null && DateTime.now().difference(last).inDays < 7) return;

    final db = DatabaseHelper();
    final gastos = await db.getGastos();
    final hayGastosMes = gastos.any(
      (g) => g.fecha.year == now.year && g.fecha.month == now.month,
    );
    if (!hayGastosMes) {
      await prefs.setLastNotifDate('no_gastos_mes');
      final mes = DateFormat('MMMM', 'es').format(now);
      await showNotification(
        id: 903,
        title: '¡No has anotado gastos este mes!',
        body: 'No encontramos movimientos en $mes. ¿Olvidaste registrarlos?',
      );
    }
  }

  // --- LÓGICA DE VERIFICACIONES FINANCIERAS ---

  /// 1. Gasto Excesivo / Alerta de Presupuestos
  Future<void> checkPresupuestoExcedido(String categoria, double nuevoMonto) async {
    final db = DatabaseHelper();
    
    // Obtener los presupuestos configurados
    final presupuestos = await db.getPresupuestos();
    final presupuesto = presupuestos.where((p) => p.categoria == categoria).firstOrNull;
    if (presupuesto == null) return;

    // Obtener total gastado en el mes actual en esta categoría
    final gastosMes = await db.getGastosPorCategoriaMesActual();
    final actual = gastosMes[categoria] ?? 0.0;

    final totalConNuevo = actual + nuevoMonto;

    if (totalConNuevo > presupuesto.limite) {
      // Excedido
      await showNotification(
        id: 100 + categoria.hashCode % 1000,
        title: '⚠️ Gasto Excesivo en $categoria',
        body: 'Has superado tu presupuesto mensual de S/ ${presupuesto.limite.toStringAsFixed(0)} (Llevas S/ ${totalConNuevo.toStringAsFixed(0)}).',
      );
    } else if (totalConNuevo >= presupuesto.limite * 0.8) {
      // Advertencia 80%
      await showNotification(
        id: 200 + categoria.hashCode % 1000,
        title: '⚠️ Presupuesto Cercano al Límite: $categoria',
        body: 'Has consumido el ${(totalConNuevo / presupuesto.limite * 100).toStringAsFixed(0)}% de tu presupuesto en $categoria (S/ ${totalConNuevo.toStringAsFixed(0)} de S/ ${presupuesto.limite.toStringAsFixed(0)}).',
      );
    }
  }

  /// 2. Metas Próximas
  Future<void> checkMetasProximas() async {
    final db = DatabaseHelper();
    final metas = await db.getMetas();
    final now = DateTime.now();

    for (final meta in metas) {
      final daysLeft = meta.fechaLimite.difference(now).inDays;
      if (daysLeft >= 0 && daysLeft <= 3) {
        final totalAhorrado = await db.getTotalAportesByMeta(meta.id!);
        if (totalAhorrado < meta.montoObjetivo) {
          final faltante = meta.montoObjetivo - totalAhorrado;
          await showNotification(
            id: 300 + meta.id!,
            title: '🎯 Meta Próxima a Vencer: ${meta.nombre}',
            body: 'Quedan solo $daysLeft días para la fecha límite de tu meta. Falta ahorrar S/ ${faltante.toStringAsFixed(0)}.',
          );
        }
      }
    }
  }

  /// 3. Comparación Gasto Semanal (Gastaste 30% más esta semana)
  Future<void> checkGastoSemanal() async {
    final db = DatabaseHelper();
    final gastos = await db.getGastos();
    final now = DateTime.now();

    final hace7dias = now.subtract(const Duration(days: 7));
    final hace14dias = now.subtract(const Duration(days: 14));

    double gastosEstaSemana = 0;
    double gastosSemanaPasada = 0;

    for (final g in gastos) {
      if (g.fecha.isAfter(hace7dias) && g.fecha.isBefore(now)) {
        gastosEstaSemana += g.monto;
      } else if (g.fecha.isAfter(hace14dias) && g.fecha.isBefore(hace7dias)) {
        gastosSemanaPasada += g.monto;
      }
    }

    if (gastosSemanaPasada > 0) {
      final incremento = (gastosEstaSemana - gastosSemanaPasada) / gastosSemanaPasada;
      if (incremento >= 0.30) {
        await showNotification(
          id: 400,
          title: '📈 Incremento de Gastos',
          body: '¡Alerta! Gastaste un ${(incremento * 100).toStringAsFixed(0)}% más esta semana comparado con la anterior (S/ ${gastosEstaSemana.toStringAsFixed(0)} vs S/ ${gastosSemanaPasada.toStringAsFixed(0)}).',
        );
      }
    }
  }
}
