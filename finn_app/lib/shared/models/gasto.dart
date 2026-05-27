class Gasto {
  final int? id;
  final String nombre;
  final String categoria;
  final double monto;
  final DateTime fecha;
  final bool esFijo;

  Gasto({
    this.id,
    required this.nombre,
    required this.categoria,
    required this.monto,
    required this.fecha,
    required this.esFijo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'esFijo': esFijo ? 1 : 0,
    };
  }

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'],
      nombre: map['nombre'],
      categoria: map['categoria'],
      monto: map['monto'],
      fecha: DateTime.parse(map['fecha']),
      esFijo: map['esFijo'] == 1,
    );
  }
}
