import 'package:flutter/material.dart';
import '../../../shared/models/gasto.dart';

class AddGastoFijoModal extends StatefulWidget {
  const AddGastoFijoModal({super.key});

  @override
  State<AddGastoFijoModal> createState() => _AddGastoFijoModalState();
}

class _AddGastoFijoModalState extends State<AddGastoFijoModal> {
  final _nameCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  String _categoria = 'Vivienda';

  static const _categorias = [
    'Vivienda',
    'Servicios',
    'Transporte',
    'Suscripciones',
    'Seguros',
    'Educación',
    'Otros',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    final nombre = _nameCtrl.text.trim();
    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0;
    if (nombre.isEmpty || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa nombre y monto')),
      );
      return;
    }
    final gasto = Gasto(
      nombre: nombre,
      categoria: _categoria,
      monto: monto,
      fecha: DateTime.now(),
      esFijo: true,
    );
    Navigator.pop(context, gasto);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Agregar gasto fijo',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre del gasto',
              hintText: 'Ej. Alquiler, Netflix...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _montoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto mensual',
              hintText: 'Ej. 500.00',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ),
        ],
      ),
    );
  }
}
