import 'categoria.dart';

enum Mood {
  triste('triste', 1, '😢', 'Triste'),
  mal('mal', 2, '😟', 'Mal'),
  neutral('neutral', 3, '😐', 'Neutral'),
  bien('bien', 4, '🙂', 'Bien'),
  feliz('feliz', 5, '😊', 'Feliz');

  final String id;
  final int valor;
  final String emoji;
  final String nombre;

  const Mood(this.id, this.valor, this.emoji, this.nombre);

  static Mood? fromId(String? id) {
    if (id == null) return null;
    for (final m in Mood.values) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Devuelve la categoría que mejor acompaña este estado de ánimo.
  /// Para "neutral" usa la categoría que el usuario eligió.
  Categoria categoriaSugerida(Categoria fallback) {
    switch (this) {
      case Mood.triste:
        return Categoria.momentoDificil;
      case Mood.mal:
        return Categoria.necesitoCalma;
      case Mood.neutral:
        return fallback;
      case Mood.bien:
        return Categoria.amorPropio;
      case Mood.feliz:
        return Categoria.gratitud;
    }
  }

  /// Mensaje cariñoso según el mood, para mostrar después del check-in.
  String mensajeCarinoso() {
    switch (this) {
      case Mood.triste:
        return 'Hoy te acompaño en lo que sentís. Suave.';
      case Mood.mal:
        return 'Vamos despacio hoy. Una respirada a la vez.';
      case Mood.neutral:
        return 'Un día normal también es valioso. Aquí estamos.';
      case Mood.bien:
        return 'Qué chévere amanecer así. Aprovéchalo.';
      case Mood.feliz:
        return 'Tu alegría también merece celebración.';
    }
  }
}
