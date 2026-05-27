import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';
import '../../shared/models/gasto.dart';
import '../../shared/services/database_helper.dart';
import '../../shared/services/data_refresh_notifier.dart';

class AgregarGastoScreen extends StatefulWidget {
  const AgregarGastoScreen({super.key});

  @override
  State<AgregarGastoScreen> createState() => _AgregarGastoScreenState();
}

class _AgregarGastoScreenState extends State<AgregarGastoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();

  String _categoria = 'Alimentación';
  DateTime _fecha = DateTime.now();
  bool _esFijo = false;
  bool _saving = false;

  static const _categorias = [
    'Alimentación',
    'Vivienda',
    'Servicios',
    'Transporte',
    'Entretenimiento',
    'Suscripciones',
    'Salud',
    'Educación',
    'Ropa',
    'Otros',
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _fecha = picked);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final gasto = Gasto(
      nombre: _nombreCtrl.text.trim(),
      categoria: _categoria,
      monto: double.parse(_montoCtrl.text.trim()),
      fecha: _fecha,
      esFijo: _esFijo,
    );

    try {
      await DatabaseHelper().insertGasto(gasto);
      DataRefreshNotifier().refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto agregado correctamente')),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Agregar Gasto'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Icon(Icons.payments_outlined,
                  size: 56, color: cs.primary),
            ),
            const SizedBox(height: 8),
            Text('Nuevo gasto',
                style: tt.headlineLarge, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Registra un movimiento de tu economía',
                style: tt.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej. Mercado, Taxi, Cine...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingresa una descripción'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _montoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto',
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

            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _pickFecha,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_fecha)),
              ),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Gasto fijo mensual'),
              subtitle: const Text('Se repite todos los meses'),
              value: _esFijo,
              onChanged: (v) => setState(() => _esFijo = v),
              activeThumbColor: cs.primary,
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
                label: Text(_saving ? 'Guardando...' : 'Guardar gasto'),
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
