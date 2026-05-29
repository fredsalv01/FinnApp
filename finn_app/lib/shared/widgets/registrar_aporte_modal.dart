import 'package:flutter/material.dart';
import '../models/aporte_ahorro.dart';

class RegistrarAporteModal extends StatefulWidget {
  final int metaId;
  final String metaNombre;
  final AporteAhorro? aporte;

  const RegistrarAporteModal({
    super.key,
    required this.metaId,
    required this.metaNombre,
    this.aporte,
  });

  @override
  State<RegistrarAporteModal> createState() => _RegistrarAporteModalState();
}

class _RegistrarAporteModalState extends State<RegistrarAporteModal> {
  final _montoCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();

  bool get _isEditing => widget.aporte != null;

  @override
  void initState() {
    super.initState();
    final a = widget.aporte;
    if (a != null) {
      _montoCtrl.text = a.monto.toStringAsFixed(2);
      _fecha = a.fecha;
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  void _guardar() {
    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido')),
      );
      return;
    }
    final aporte = AporteAhorro(
      id: widget.aporte?.id,
      metaId: widget.metaId,
      monto: monto,
      fecha: _fecha,
    );
    Navigator.pop(context, aporte);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
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
          Text(_isEditing ? 'Editar aporte' : 'Registrar aporte', style: tt.headlineMedium),
          const SizedBox(height: 4),
          Text('Meta: ${widget.metaNombre}', style: tt.bodySmall),
          const SizedBox(height: 20),
          TextField(
            controller: _montoCtrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto del aporte',
              hintText: '0.00',
              prefixText: 'S/ ',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickFecha,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha del aporte',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                  '${_fecha.day.toString().padLeft(2, '0')}/${_fecha.month.toString().padLeft(2, '0')}/${_fecha.year}'),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.check),
              label: Text(_isEditing ? 'Actualizar' : 'Registrar'),
            ),
          ),
        ],
      ),
    );
  }
}
