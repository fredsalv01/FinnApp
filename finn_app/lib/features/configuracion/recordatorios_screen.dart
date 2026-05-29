import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/services/sync_service.dart';
import '../../core/widgets/finanzas_card.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';
import '../../shared/models/recordatorio.dart';
import '../../shared/services/database_helper.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/widgets/confirm_dialog.dart';

class RecordatoriosScreen extends StatefulWidget {
  const RecordatoriosScreen({super.key});

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  List<Recordatorio> _recordatorios = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    NotificationService().requestPermissions();
  }

  Future<void> _load() async {
    final list = await DatabaseHelper().getRecordatorios();
    if (!mounted) return;
    setState(() {
      _recordatorios = list;
      _loading = false;
    });
  }

  Future<void> _eliminarRecordatorio(Recordatorio r) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Eliminar recordatorio',
      message: '¿Estás seguro de eliminar el recordatorio de "${r.titulo}"?',
    );
    if (!ok || r.id == null) return;

    await NotificationService().cancelNotification(r.id!);
    await DatabaseHelper().deleteRecordatorio(r.id!);
    SyncService().syncRecordatoriosAsync();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recordatorio eliminado')),
    );
    _load();
  }

  Future<void> _agregarRecordatorio() async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(minutes: 5));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    final nuevoRecordatorio = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final tt = Theme.of(ctx).textTheme;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setModalState(() {
                  selectedDate = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                });
              }
            }

            Future<void> pickTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: selectedTime,
              );
              if (picked != null) {
                setModalState(() {
                  selectedTime = picked;
                  selectedDate = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    picked.hour,
                    picked.minute,
                  );
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Nuevo Recordatorio', style: tt.headlineMedium),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Título o Servicio',
                          hintText: 'Ej. Alquiler, Luz, Internet',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payment),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ingresa un título'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: montoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Monto estimado',
                          hintText: '0.00',
                          prefixText: 'S/ ',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (v) {
                          final n = double.tryParse(v?.trim() ?? '');
                          if (n == null || n <= 0) {
                            return 'Ingresa un monto válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickDate,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(DateFormat('dd/MM/yyyy')
                                  .format(selectedDate)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickTime,
                              icon: const Icon(Icons.access_time),
                              label: Text(selectedTime.format(context)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final recordatorio = Recordatorio(
                              titulo: titleCtrl.text.trim(),
                              monto: double.parse(montoCtrl.text.trim()),
                              fecha: selectedDate,
                            );

                            final id = await DatabaseHelper()
                                .insertRecordatorio(recordatorio);

                            // Programar notificación
                            await NotificationService().scheduleNotification(
                              id: id,
                              title: '🔔 Recordatorio de Pago',
                              body:
                                  'Hoy vence el pago de "${recordatorio.titulo}" por S/ ${recordatorio.monto.toStringAsFixed(2)}.',
                              scheduledDate: recordatorio.fecha,
                            );

                            SyncService().syncRecordatoriosAsync();
                            if (!context.mounted) return;
                            Navigator.of(context).pop(true);
                          },
                          child: const Text('Programar Recordatorio'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (nuevoRecordatorio == true) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Recordatorios de Pago'),
      body: _loading
          ? Shimmer.fromColors(
              baseColor: Colors.white.withValues(alpha: 0.05),
              highlightColor: Colors.white.withValues(alpha: 0.12),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: 4,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            )
          : _recordatorios.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.notifications_active_rounded,
                              size: 68, color: cs.primary),
                        ),
                        const SizedBox(height: 24),
                        Text('Sin recordatorios', style: tt.headlineMedium,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        Text(
                          'Programa avisos de pago para no olvidar tus servicios.',
                          style: tt.bodySmall?.copyWith(
                              color: Colors.grey.shade500, height: 1.6),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 34),
                        SizedBox(
                          width: 240,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _agregarRecordatorio,
                            icon: const Icon(Icons.add_alert_rounded),
                            label: const Text('Programar recordatorio',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _recordatorios.length,
                  itemBuilder: (ctx, i) {
                    final r = _recordatorios[i];
                    final formateada =
                        DateFormat('dd/MM/yyyy - hh:mm a').format(r.fecha);
                    final esPasado = r.fecha.isBefore(DateTime.now());

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey('rec_${r.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: cs.error.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          await _eliminarRecordatorio(r);
                          return false;
                        },
                        child: FinanzasCard(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: esPasado
                                      ? Colors.grey.withValues(alpha: 0.15)
                                      : cs.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  esPasado
                                      ? Icons.notifications_none
                                      : Icons.notifications_active,
                                  color: esPasado ? Colors.grey : cs.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.titulo,
                                      style: tt.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        decoration: esPasado
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Vence: $formateada',
                                      style: tt.bodySmall?.copyWith(
                                        color: esPasado
                                            ? Colors.grey
                                            : cs.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'S/ ${r.monto.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: esPasado ? Colors.grey : cs.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarRecordatorio,
        child: const Icon(Icons.add_alert_rounded),
      ),
    );
  }
}
