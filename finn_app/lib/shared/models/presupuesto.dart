class Presupuesto {
  final int? id;
  final String categoria;
  final double limite;

  Presupuesto({
    this.id,
    required this.categoria,
    required this.limite,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria': categoria,
      'limite': limite,
    };
  }

  factory Presupuesto.fromMap(Map<String, dynamic> map) {
    return Presupuesto(
      id: map['id'] as int?,
      categoria: map['categoria'] as String,
      limite: (map['limite'] as num).toDouble(),
    );
  }
}
