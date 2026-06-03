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
}
