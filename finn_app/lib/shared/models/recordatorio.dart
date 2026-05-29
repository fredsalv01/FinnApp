class Recordatorio {
  final int? id;
  final String titulo;
  final double monto;
  final DateTime fecha;
  final bool completo;

  Recordatorio({
    this.id,
    required this.titulo,
    required this.monto,
    required this.fecha,
    this.completo = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'completo': completo ? 1 : 0,
    };
  }

  factory Recordatorio.fromMap(Map<String, dynamic> map) {
    return Recordatorio(
      id: map['id'],
      titulo: map['titulo'],
      monto: (map['monto'] as num).toDouble(),
      fecha: DateTime.parse(map['fecha']),
      completo: map['completo'] == 1,
    );
  }
}
