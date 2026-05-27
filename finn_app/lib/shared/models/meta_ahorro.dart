class MetaAhorro {
  final int? id;
  final String nombre;
  final double montoObjetivo;
  final DateTime fechaLimite;

  MetaAhorro({
    this.id,
    required this.nombre,
    required this.montoObjetivo,
    required this.fechaLimite,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'montoObjetivo': montoObjetivo,
      'fechaLimite': fechaLimite.toIso8601String(),
    };
  }

  factory MetaAhorro.fromMap(Map<String, dynamic> map) {
    return MetaAhorro(
      id: map['id'],
      nombre: map['nombre'],
      montoObjetivo: map['montoObjetivo'],
      fechaLimite: DateTime.parse(map['fechaLimite']),
    );
  }
}
