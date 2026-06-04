enum ResultadoIntencion {
  pendiente('pendiente', '⏳', 'Pendiente'),
  cumplida('cumplida', '✅', 'Cumplida'),
  intentada('intentada', '🤝', 'Lo intenté'),
  noCumplida('no', '🌿', 'No esta vez');

  final String id;
  final String emoji;
  final String etiqueta;

  const ResultadoIntencion(this.id, this.emoji, this.etiqueta);

  static ResultadoIntencion fromId(String? id) {
    if (id == null) return ResultadoIntencion.pendiente;
    for (final r in ResultadoIntencion.values) {
      if (r.id == id) return r;
    }
    return ResultadoIntencion.pendiente;
  }
}

class Intencion {
  final String fecha;
  final String texto;
  final ResultadoIntencion resultado;
  final DateTime? fechaRespuesta;

  const Intencion({
    required this.fecha,
    required this.texto,
    this.resultado = ResultadoIntencion.pendiente,
    this.fechaRespuesta,
  });

  Intencion copyWith({
    String? texto,
    ResultadoIntencion? resultado,
    DateTime? fechaRespuesta,
  }) {
    return Intencion(
      fecha: fecha,
      texto: texto ?? this.texto,
      resultado: resultado ?? this.resultado,
      fechaRespuesta: fechaRespuesta ?? this.fechaRespuesta,
    );
  }

  Map<String, dynamic> toJson() => {
        'f': fecha,
        't': texto,
        'r': resultado.id,
        if (fechaRespuesta != null) 'fr': fechaRespuesta!.toIso8601String(),
      };

  factory Intencion.fromJson(Map<String, dynamic> j) => Intencion(
        fecha: j['f'] as String,
        texto: j['t'] as String,
        resultado: ResultadoIntencion.fromId(j['r'] as String?),
        fechaRespuesta: j['fr'] != null
            ? DateTime.parse(j['fr'] as String)
            : null,
      );
}

class EstadisticasIntenciones {
  final int total;
  final int cumplidas;
  final int intentadas;
  final int noCumplidas;
  final int rachaIntencionesCumplidas;

  const EstadisticasIntenciones({
    required this.total,
    required this.cumplidas,
    required this.intentadas,
    required this.noCumplidas,
    required this.rachaIntencionesCumplidas,
  });

  double get porcentajeExito {
    final respondidas = cumplidas + intentadas + noCumplidas;
    if (respondidas == 0) return 0;
    return (cumplidas + intentadas * 0.5) / respondidas;
  }
}
