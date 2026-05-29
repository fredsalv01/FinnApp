class IngresoExtra {
  final int? id;
  final String descripcion;
  final String categoria;
  final double monto;
  final DateTime fecha;

  IngresoExtra({
    this.id,
    required this.descripcion,
    required this.categoria,
    required this.monto,
    required this.fecha,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'descripcion': descripcion,
        'categoria': categoria,
        'monto': monto,
        'fecha': fecha.toIso8601String(),
      };

  factory IngresoExtra.fromMap(Map<String, dynamic> m) => IngresoExtra(
        id: m['id'] as int?,
        descripcion: m['descripcion'] as String,
        categoria: m['categoria'] as String,
        monto: (m['monto'] as num).toDouble(),
        fecha: DateTime.parse(m['fecha'] as String),
      );
}
