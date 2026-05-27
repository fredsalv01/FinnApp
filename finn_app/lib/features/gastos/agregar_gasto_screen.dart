import 'package:flutter/material.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';

class AgregarGastoScreen extends StatelessWidget {
  const AgregarGastoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Agregar Gasto'),
      body: Center(
        child: Text('Pantalla de Agregar Gasto'),
      ),
    );
  }
}
