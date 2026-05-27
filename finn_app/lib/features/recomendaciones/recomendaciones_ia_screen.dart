import 'package:flutter/material.dart';
import '../../core/widgets/finanzas_card.dart';
import '../../core/widgets/finanzas_top_app_bar.dart';

class RecomendacionesIAScreen extends StatefulWidget {
  const RecomendacionesIAScreen({super.key});
  @override State<RecomendacionesIAScreen> createState() =>
      _RecomendacionesIAScreenState();
}

class _RecomendacionesIAScreenState extends State<RecomendacionesIAScreen> {
  bool _cargando = false;
  String? _analisis;

  Future<void> _generarAnalisis() async {
    setState(() { _cargando = true; _analisis = null; });
    // Aquí irá la llamada a Claude API con los datos reales del usuario
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _cargando = false;
      _analisis = '''
📊 Resumen de Junio 2026

Gastaste S/ 1,700 en total este mes. Tu categoría más alta fue Vivienda con S/ 1,500 (88% de tus gastos).

✅ Puntos positivos:
• Mantuviste tus gastos variables bajo control
• Registraste tu aporte de ahorro a tiempo

⚠️ Áreas de mejora:
• Tu gasto en alimentación subió 12% vs mayo
• Considera revisar si todas tus suscripciones siguen siendo necesarias

💡 Recomendaciones:
1. Establece un presupuesto mensual para alimentación de máx. S/ 400
2. Revisa el gasto en transporte; considera opciones más económicas
3. Con tu ritmo actual llegarás a tu meta en Diciembre 2026 ✓

📈 Proyección: Si ahorras S/ 1,429/mes, alcanzarás S/ 10,000 en Diciembre 2026.
      ''';
    });
  }

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;
    return Scaffold(
      appBar: const FinanzasTopAppBar(subtitle: 'Recomendaciones IA'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FinanzasCard(
            color: cs.primary.withValues(alpha: 0.05),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primary, borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Análisis inteligente', style: tt.headlineMedium),
                  Text('Basado en tus datos reales de Junio 2026',
                      style: tt.bodySmall),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _cargando ? null : _generarAnalisis,
              icon: _cargando
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.psychology_outlined),
              label: Text(_cargando
                  ? 'Analizando...' : 'Generar análisis del mes'),
            ),
          ),
          if (_analisis != null) ...[
            const SizedBox(height: 16),
            FinanzasCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.auto_awesome, color: cs.primary, size: 16),
                    const SizedBox(width: 8),
                    Text('Análisis · Junio 2026', style: tt.headlineMedium),
                  ]),
                  const SizedBox(height: 12),
                  Text(_analisis!, style: tt.bodyLarge?.copyWith(
                      fontSize: 14, height: 1.6)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}
