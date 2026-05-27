// Pruebas básicas de la app Finn.
import 'package:flutter_test/flutter_test.dart';
import 'package:finn_app/shared/models/gasto.dart';

void main() {
  test('Gasto.toMap/fromMap roundtrip', () {
    final original = Gasto(
      id: 1,
      nombre: 'Alquiler',
      categoria: 'Vivienda',
      monto: 1500.50,
      fecha: DateTime(2026, 5, 27),
      esFijo: true,
    );
    final restored = Gasto.fromMap(original.toMap());
    expect(restored.id, 1);
    expect(restored.nombre, 'Alquiler');
    expect(restored.categoria, 'Vivienda');
    expect(restored.monto, 1500.50);
    expect(restored.fecha, DateTime(2026, 5, 27));
    expect(restored.esFijo, true);
  });
}
