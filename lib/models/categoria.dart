enum Categoria {
  momentoDificil('momento_dificil', 'Momento difícil', '🌧️'),
  lograrMeta('lograr_meta', 'Lograr una meta', '🎯'),
  necesitoCalma('necesito_calma', 'Necesito calma', '🌿'),
  gratitud('gratitud', 'Gratitud', '💛'),
  amorPropio('amor_propio', 'Amor propio', '🪞');

  final String id;
  final String nombre;
  final String emoji;

  const Categoria(this.id, this.nombre, this.emoji);

  static Categoria fromId(String id) {
    return Categoria.values.firstWhere(
      (c) => c.id == id,
      orElse: () => Categoria.momentoDificil,
    );
  }
}
