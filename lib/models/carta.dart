class Carta {
  final int id;
  final String fechaEscritura;
  final String fechaEntrega;
  final String contenido;
  final bool leida;

  const Carta({
    required this.id,
    required this.fechaEscritura,
    required this.fechaEntrega,
    required this.contenido,
    required this.leida,
  });

  Carta copyWith({
    int? id,
    String? fechaEscritura,
    String? fechaEntrega,
    String? contenido,
    bool? leida,
  }) {
    return Carta(
      id: id ?? this.id,
      fechaEscritura: fechaEscritura ?? this.fechaEscritura,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      contenido: contenido ?? this.contenido,
      leida: leida ?? this.leida,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fe': fechaEscritura,
        'fd': fechaEntrega,
        'c': contenido,
        'l': leida,
      };

  factory Carta.fromJson(Map<String, dynamic> j) => Carta(
        id: j['id'] as int,
        fechaEscritura: j['fe'] as String,
        fechaEntrega: j['fd'] as String,
        contenido: j['c'] as String,
        leida: j['l'] as bool? ?? false,
      );

  bool get yaDisponible {
    final hoy = DateTime.now();
    final entrega = DateTime.parse(fechaEntrega);
    return !entrega.isAfter(DateTime(hoy.year, hoy.month, hoy.day));
  }

  int get diasParaEntrega {
    final hoy = DateTime.now();
    final entrega = DateTime.parse(fechaEntrega);
    return entrega.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
  }

  int get diasDesdeEscritura {
    final hoy = DateTime.now();
    final escritura = DateTime.parse(fechaEscritura);
    return hoy.difference(escritura).inDays;
  }
}
