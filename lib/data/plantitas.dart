class EtapaPlantita {
  final int nivel;
  final String emoji;
  final String nombre;
  final String descripcion;
  final int diasMinimos;

  const EtapaPlantita({
    required this.nivel,
    required this.emoji,
    required this.nombre,
    required this.descripcion,
    required this.diasMinimos,
  });
}

class Plantitas {
  static const List<EtapaPlantita> etapas = [
    EtapaPlantita(
      nivel: 0,
      emoji: '🌱',
      nombre: 'Semilla',
      descripcion: 'Apenas brotando, llena de promesa.',
      diasMinimos: 0,
    ),
    EtapaPlantita(
      nivel: 1,
      emoji: '🌿',
      nombre: 'Brote',
      descripcion: 'Asomando con valentía. Vas bien.',
      diasMinimos: 3,
    ),
    EtapaPlantita(
      nivel: 2,
      emoji: '🪴',
      nombre: 'Hojitas',
      descripcion: 'Creciendo con tu cariño.',
      diasMinimos: 7,
    ),
    EtapaPlantita(
      nivel: 3,
      emoji: '🪴',
      nombre: 'Plantita firme',
      descripcion: 'Ya tiene raíz, no la mueve cualquier viento.',
      diasMinimos: 14,
    ),
    EtapaPlantita(
      nivel: 4,
      emoji: '🌳',
      nombre: 'Arbolito',
      descripcion: 'Te tomó cariño. Te espera.',
      diasMinimos: 30,
    ),
    EtapaPlantita(
      nivel: 5,
      emoji: '🌳',
      nombre: 'Árbol joven',
      descripcion: 'Da sombra a tu día.',
      diasMinimos: 60,
    ),
    EtapaPlantita(
      nivel: 6,
      emoji: '🌸',
      nombre: 'Floreciendo',
      descripcion: 'Mira lo que cuidaste, mijín.',
      diasMinimos: 100,
    ),
    EtapaPlantita(
      nivel: 7,
      emoji: '🌺',
      nombre: 'En flor',
      descripcion: 'Tu jardín privado, hermoso.',
      diasMinimos: 200,
    ),
    EtapaPlantita(
      nivel: 8,
      emoji: '🌳',
      nombre: 'Bosque',
      descripcion: 'Sos un ecosistema entero. Inspirás.',
      diasMinimos: 365,
    ),
  ];

  static EtapaPlantita actual(int dias) {
    var res = etapas.first;
    for (final e in etapas) {
      if (dias >= e.diasMinimos) res = e;
    }
    return res;
  }

  static EtapaPlantita? siguiente(int dias) {
    for (final e in etapas) {
      if (e.diasMinimos > dias) return e;
    }
    return null;
  }

  static double progresoAlSiguiente(int dias) {
    final ahora = actual(dias);
    final siguienteEtapa = siguiente(dias);
    if (siguienteEtapa == null) return 1.0;
    final rangoTotal = siguienteEtapa.diasMinimos - ahora.diasMinimos;
    final avance = dias - ahora.diasMinimos;
    if (rangoTotal <= 0) return 1.0;
    return (avance / rangoTotal).clamp(0.0, 1.0);
  }
}
