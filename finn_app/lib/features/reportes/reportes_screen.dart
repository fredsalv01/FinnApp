import 'package:flutter/material.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Reportes'),
      body: Center(
        child: Text('Pantalla de Reportes'),
      ),
    );
  }
}
