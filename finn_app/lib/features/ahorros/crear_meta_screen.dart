import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';
import '../../shared/models/meta_ahorro.dart';
import '../../shared/services/database_helper.dart';
import '../../shared/services/data_refresh_notifier.dart';
import '../../core/services/sync_service.dart';

class CrearMetaScreen extends StatefulWidget {
  const CrearMetaScreen({super.key});

  @override
  State<CrearMetaScreen> createState() => _CrearMetaScreenState();
}

class _CrearMetaScreenState extends State<CrearMetaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  DateTime _fechaLimite =
      DateTime.now().add(const Duration(days: 180));
  bool _saving = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaLimite,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _fechaLimite = picked);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final meta = MetaAhorro(
      nombre: _nombreCtrl.text.trim(),
      montoObjetivo: double.parse(_montoCtrl.text.trim()),
      fechaLimite: _fechaLimite,
    );

    try {
      await DatabaseHelper().insertMeta(meta);
      DataRefreshNotifier().refresh();
      SyncService().syncMetasAsync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meta creada correctamente')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  int get _mesesRestantes {
    final now = DateTime.now();
    return ((_fechaLimite.year - now.year) * 12) +
        (_fechaLimite.month - now.month);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0;
    final meses = _mesesRestantes;
    final mensual = meses > 0 ? monto / meses : 0;

    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Crear meta de ahorro'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Icon(Icons.savings_outlined,
                  size: 56, color: cs.primary),
            ),
            const SizedBox(height: 8),
            Text('Nueva meta',
                style: tt.headlineLarge, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Define un objetivo de ahorro',
                style: tt.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre de la meta',
                hintText: 'Ej. Vacaciones, Auto nuevo...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingresa un nombre'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _montoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Monto objetivo',
                hintText: '0.00',
                prefixText: 'S/ ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Ingresa un monto válido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _pickFecha,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha límite',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                child: Text(DateFormat('dd MMM yyyy', 'es')
                    .format(_fechaLimite)),
              ),
            ),
            const SizedBox(height: 20),

            // Card resumen
            if (monto > 0 && meses > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: cs.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('Plan sugerido',
                            style: tt.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ahorra S/ ${mensual.toStringAsFixed(2)} cada mes durante '
                      '$meses ${meses == 1 ? "mes" : "meses"} para alcanzar tu meta.',
                      style: tt.bodySmall,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _guardar,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: Text(_saving ? 'Guardando...' : 'Crear meta'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _saving ? null : () => context.pop(),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
