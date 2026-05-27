class AporteAhorro {
  final int? id;
  final int metaId;
  final double monto;
  final DateTime fecha;

  AporteAhorro({
    this.id,
    required this.metaId,
    required this.monto,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'metaId': metaId,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory AporteAhorro.fromMap(Map<String, dynamic> map) {
    return AporteAhorro(
      id: map['id'],
      metaId: map['metaId'],
      monto: map['monto'],
      fecha: DateTime.parse(map['fecha']),
    );
  }
}
