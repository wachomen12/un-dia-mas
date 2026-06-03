import 'mood.dart';

class Reflexion {
  final int id;
  final DateTime fechaHora;
  final String frase;
  final String categoriaId;
  final String? moodId;
  final String texto;

  const Reflexion({
    required this.id,
    required this.fechaHora,
    required this.frase,
    required this.categoriaId,
    this.moodId,
    required this.texto,
  });

  Mood? get mood => Mood.fromId(moodId);

  Map<String, dynamic> toJson() => {
        'id': id,
        'ts': fechaHora.toIso8601String(),
        'f': frase,
        'c': categoriaId,
        if (moodId != null) 'm': moodId,
        't': texto,
      };

  factory Reflexion.fromJson(Map<String, dynamic> j) => Reflexion(
        id: j['id'] as int,
        fechaHora: DateTime.parse(j['ts'] as String),
        frase: j['f'] as String,
        categoriaId: j['c'] as String,
        moodId: j['m'] as String?,
        texto: j['t'] as String,
      );

  String get claveDia {
    final d = fechaHora;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class EstadisticasReflexiones {
  final int total;
  final int diasConsecutivos;
  final Mood? moodMasFrecuente;
  final int totalDiasUnicos;

  const EstadisticasReflexiones({
    required this.total,
    required this.diasConsecutivos,
    this.moodMasFrecuente,
    required this.totalDiasUnicos,
  });
}
