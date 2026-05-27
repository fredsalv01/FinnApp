import 'package:flutter/material.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';

class CrearMetaScreen extends StatelessWidget {
  const CrearMetaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Crear Meta de Ahorro'),
      body: Center(
        child: Text('Pantalla de Crear Meta'),
      ),
    );
  }
}
