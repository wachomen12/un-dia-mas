class Logro {
  final String id;
  final String titulo;
  final String descripcion;
  final String emoji;
  final int diasNecesarios;

  const Logro({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.emoji,
    required this.diasNecesarios,
  });
}

class Logros {
  static const List<Logro> todos = [
    Logro(
      id: 'primer_dia',
      titulo: 'Primer paso',
      descripcion: 'Empezaste. Eso ya es valiente.',
      emoji: '🌱',
      diasNecesarios: 1,
    ),
    Logro(
      id: 'tres_dias',
      titulo: 'Tres días',
      descripcion: 'Estás tomando ritmo.',
      emoji: '🔥',
      diasNecesarios: 3,
    ),
    Logro(
      id: 'una_semana',
      titulo: 'Una semana',
      descripcion: 'Siete días sin rendirte. Magia.',
      emoji: '⭐',
      diasNecesarios: 7,
    ),
    Logro(
      id: 'dos_semanas',
      titulo: 'Dos semanas',
      descripcion: 'Ya es hábito, no es esfuerzo.',
      emoji: '🌟',
      diasNecesarios: 14,
    ),
    Logro(
      id: 'un_mes',
      titulo: 'Un mes entero',
      descripcion: 'Disciplina con cariño. Eres ejemplo.',
      emoji: '🏅',
      diasNecesarios: 30,
    ),
    Logro(
      id: 'dos_meses',
      titulo: 'Dos meses',
      descripcion: 'Estás construyendo algo grande.',
      emoji: '🎖️',
      diasNecesarios: 60,
    ),
    Logro(
      id: 'cien_dias',
      titulo: 'Cien días',
      descripcion: 'Esto ya es parte de quien eres.',
      emoji: '💯',
      diasNecesarios: 100,
    ),
    Logro(
      id: 'doscientos_dias',
      titulo: 'Doscientos días',
      descripcion: 'Inspiras a otros sin saberlo.',
      emoji: '👑',
      diasNecesarios: 200,
    ),
    Logro(
      id: 'un_anio',
      titulo: 'Un año entero',
      descripcion: 'Un año sin rendirte. Mira lo que eres capaz.',
      emoji: '🏆',
      diasNecesarios: 365,
    ),
  ];

  static List<Logro> nuevosDesbloqueados(int racha, Set<String> yaTenidos) {
    return todos
        .where((l) =>
            racha >= l.diasNecesarios && !yaTenidos.contains(l.id))
        .toList();
  }
}
