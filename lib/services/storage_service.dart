import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/carta.dart';
import '../models/categoria.dart';
import '../models/mood.dart';
import '../models/reflexion.dart';

class EstadisticasRacha {
  final int rachaActual;
  final int maxRacha;
  final int totalDias;
  final Set<String> diasVistos;

  const EstadisticasRacha({
    required this.rachaActual,
    required this.maxRacha,
    required this.totalDias,
    required this.diasVistos,
  });
}

class EntradaDiario {
  final String fecha;
  final String texto;
  final Mood? mood;

  const EntradaDiario({required this.fecha, required this.texto, this.mood});

  Map<String, dynamic> toJson() => {
        'f': fecha,
        't': texto,
        if (mood != null) 'm': mood!.id,
      };

  factory EntradaDiario.fromJson(Map<String, dynamic> j) => EntradaDiario(
        fecha: j['f'] as String,
        texto: j['t'] as String,
        mood: Mood.fromId(j['m'] as String?),
      );
}

class StorageService {
  static const _kCategoria = 'categoria';
  static const _kHora = 'hora_notificacion';
  static const _kMinuto = 'minuto_notificacion';
  static const _kRacha = 'racha_dias';
  static const _kMaxRacha = 'max_racha';
  static const _kUltimaApertura = 'ultima_apertura';
  static const _kDiasVistos = 'dias_vistos';
  static const _kOnboardingHecho = 'onboarding_hecho';
  static const _kFavoritas = 'favoritas';
  static const _kNombre = 'nombre_usuario';
  static const _kDiario = 'diario_entradas';
  static const _kLogros = 'logros_desbloqueados';
  static const _kModoOscuro = 'modo_oscuro';
  static const _kNotifNocheActiva = 'notif_noche_activa';
  static const _kNotifNocheHora = 'notif_noche_hora';
  static const _kNotifNocheMinuto = 'notif_noche_minuto';
  static const _kCartas = 'cartas';
  static const _kProximoIdCarta = 'proximo_id_carta';
  static const _kRandomsHistorial = 'randoms_historial_v2';
  static const _kEspecialesHistorial = 'especiales_historial_v2';
  static const _kReflexiones = 'reflexiones';
  static const _kProximoIdReflexion = 'proximo_id_reflexion';
  static const _kCheckinDia = 'checkin_ultimo_dia';
  static const _kCheckinMood = 'checkin_ultimo_mood';
  static const _kPlantitaNombre = 'plantita_nombre';
  static const _kPlantitaUltimoNivel = 'plantita_ultimo_nivel';

  static const int randomsMax = 10;
  static const int especialesMax = 3;
  static const Duration randomsVentana = Duration(hours: 8);

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static String claveDia(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Onboarding
  static Future<bool> onboardingCompleto() async {
    final p = await _prefs;
    return p.getBool(_kOnboardingHecho) ?? false;
  }

  static Future<void> marcarOnboardingCompleto() async {
    final p = await _prefs;
    await p.setBool(_kOnboardingHecho, true);
  }

  // Nombre
  static Future<void> guardarNombre(String nombre) async {
    final p = await _prefs;
    await p.setString(_kNombre, nombre.trim());
  }

  static Future<String> obtenerNombre() async {
    final p = await _prefs;
    return p.getString(_kNombre) ?? '';
  }

  // Categoría
  static Future<void> guardarCategoria(Categoria categoria) async {
    final p = await _prefs;
    await p.setString(_kCategoria, categoria.id);
  }

  static Future<Categoria> obtenerCategoria() async {
    final p = await _prefs;
    final id = p.getString(_kCategoria) ?? Categoria.momentoDificil.id;
    return Categoria.fromId(id);
  }

  // Hora
  static Future<void> guardarHora(int hora, int minuto) async {
    final p = await _prefs;
    await p.setInt(_kHora, hora);
    await p.setInt(_kMinuto, minuto);
  }

  static Future<({int hora, int minuto})> obtenerHora() async {
    final p = await _prefs;
    return (hora: p.getInt(_kHora) ?? 8, minuto: p.getInt(_kMinuto) ?? 0);
  }

  // Notificación noche
  static Future<bool> notifNocheActiva() async {
    final p = await _prefs;
    return p.getBool(_kNotifNocheActiva) ?? false;
  }

  static Future<void> guardarNotifNocheActiva(bool activa) async {
    final p = await _prefs;
    await p.setBool(_kNotifNocheActiva, activa);
  }

  static Future<({int hora, int minuto})> obtenerHoraNoche() async {
    final p = await _prefs;
    return (
      hora: p.getInt(_kNotifNocheHora) ?? 21,
      minuto: p.getInt(_kNotifNocheMinuto) ?? 0,
    );
  }

  static Future<void> guardarHoraNoche(int hora, int minuto) async {
    final p = await _prefs;
    await p.setInt(_kNotifNocheHora, hora);
    await p.setInt(_kNotifNocheMinuto, minuto);
  }

  // Modo oscuro
  static Future<String> obtenerModoOscuro() async {
    final p = await _prefs;
    return p.getString(_kModoOscuro) ?? 'system';
  }

  static Future<void> guardarModoOscuro(String modo) async {
    final p = await _prefs;
    await p.setString(_kModoOscuro, modo);
  }

  // Racha
  static Future<EstadisticasRacha> registrarAperturaHoy() async {
    final p = await _prefs;
    final hoy = DateTime.now();
    final hoyClave = claveDia(hoy);
    final ultima = p.getString(_kUltimaApertura);

    Set<String> dias = (p.getStringList(_kDiasVistos) ?? []).toSet();
    int rachaActual = p.getInt(_kRacha) ?? 0;

    if (ultima != hoyClave) {
      if (ultima == null) {
        rachaActual = 1;
      } else {
        final ayer = hoy.subtract(const Duration(days: 1));
        if (ultima == claveDia(ayer)) {
          rachaActual += 1;
        } else {
          rachaActual = 1;
        }
      }
      dias.add(hoyClave);
      await p.setInt(_kRacha, rachaActual);
      await p.setString(_kUltimaApertura, hoyClave);
      await p.setStringList(_kDiasVistos, dias.toList());
    }

    int maxRacha = p.getInt(_kMaxRacha) ?? 0;
    if (rachaActual > maxRacha) {
      maxRacha = rachaActual;
      await p.setInt(_kMaxRacha, maxRacha);
    }

    return EstadisticasRacha(
      rachaActual: rachaActual,
      maxRacha: maxRacha,
      totalDias: dias.length,
      diasVistos: dias,
    );
  }

  static Future<EstadisticasRacha> obtenerEstadisticas() async {
    final p = await _prefs;
    final dias = (p.getStringList(_kDiasVistos) ?? []).toSet();
    return EstadisticasRacha(
      rachaActual: p.getInt(_kRacha) ?? 0,
      maxRacha: p.getInt(_kMaxRacha) ?? 0,
      totalDias: dias.length,
      diasVistos: dias,
    );
  }

  static Future<int> obtenerRachaActual() async {
    final p = await _prefs;
    return p.getInt(_kRacha) ?? 0;
  }

  // Favoritas
  static Future<List<String>> obtenerFavoritas() async {
    final p = await _prefs;
    return p.getStringList(_kFavoritas) ?? [];
  }

  static Future<bool> esFavorita(String frase) async {
    final lista = await obtenerFavoritas();
    return lista.contains(frase);
  }

  static Future<bool> alternarFavorita(String frase) async {
    final p = await _prefs;
    final lista = (p.getStringList(_kFavoritas) ?? []).toList();
    final nuevo = !lista.contains(frase);
    if (nuevo) {
      lista.insert(0, frase);
    } else {
      lista.remove(frase);
    }
    await p.setStringList(_kFavoritas, lista);
    return nuevo;
  }

  // Diario
  static Future<List<EntradaDiario>> obtenerDiario() async {
    final p = await _prefs;
    final raw = p.getStringList(_kDiario) ?? [];
    return raw
        .map((s) => EntradaDiario.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<EntradaDiario?> entradaDiarioHoy() async {
    final hoy = claveDia(DateTime.now());
    final lista = await obtenerDiario();
    for (final e in lista) {
      if (e.fecha == hoy) return e;
    }
    return null;
  }

  static Future<void> guardarEntradaDiario(String texto, {Mood? mood}) async {
    final p = await _prefs;
    final hoy = claveDia(DateTime.now());
    final lista = await obtenerDiario();
    final filtrada = lista.where((e) => e.fecha != hoy).toList();
    filtrada.insert(
      0,
      EntradaDiario(fecha: hoy, texto: texto.trim(), mood: mood),
    );
    await p.setStringList(
      _kDiario,
      filtrada.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<void> borrarEntradaDiario(String fecha) async {
    final p = await _prefs;
    final lista = await obtenerDiario();
    final filtrada = lista.where((e) => e.fecha != fecha).toList();
    await p.setStringList(
      _kDiario,
      filtrada.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  // Logros
  static Future<Set<String>> obtenerLogros() async {
    final p = await _prefs;
    return (p.getStringList(_kLogros) ?? []).toSet();
  }

  static Future<void> guardarLogro(String id) async {
    final p = await _prefs;
    final actuales = (p.getStringList(_kLogros) ?? []).toSet();
    actuales.add(id);
    await p.setStringList(_kLogros, actuales.toList());
  }

  static Future<bool> logroDesbloqueado(String id) async {
    final logros = await obtenerLogros();
    return logros.contains(id);
  }

  // Cartas al yo futuro
  static Future<int> _siguienteIdCarta() async {
    final p = await _prefs;
    final actual = p.getInt(_kProximoIdCarta) ?? 1;
    await p.setInt(_kProximoIdCarta, actual + 1);
    return actual;
  }

  static Future<List<Carta>> obtenerCartas() async {
    final p = await _prefs;
    final raw = p.getStringList(_kCartas) ?? [];
    return raw
        .map((s) => Carta.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<Carta> guardarCarta({
    required String contenido,
    required DateTime fechaEntrega,
  }) async {
    final id = await _siguienteIdCarta();
    final ahora = DateTime.now();
    final carta = Carta(
      id: id,
      fechaEscritura: claveDia(ahora),
      fechaEntrega: claveDia(fechaEntrega),
      contenido: contenido.trim(),
      leida: false,
    );
    final lista = await obtenerCartas();
    lista.add(carta);
    await _persistirCartas(lista);
    return carta;
  }

  static Future<void> marcarCartaLeida(int id) async {
    final lista = await obtenerCartas();
    final nueva = lista.map((c) => c.id == id ? c.copyWith(leida: true) : c).toList();
    await _persistirCartas(nueva);
  }

  static Future<void> borrarCarta(int id) async {
    final lista = await obtenerCartas();
    final filtrada = lista.where((c) => c.id != id).toList();
    await _persistirCartas(filtrada);
  }

  static Future<List<Carta>> cartasNoLeidasYDisponibles() async {
    final lista = await obtenerCartas();
    return lista.where((c) => !c.leida && c.yaDisponible).toList();
  }

  static Future<void> _persistirCartas(List<Carta> lista) async {
    final p = await _prefs;
    await p.setStringList(
      _kCartas,
      lista.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  // Rate limit del botón random
  static Future<List<DateTime>> _randomsRecientes() async {
    final p = await _prefs;
    final raw = p.getStringList(_kRandomsHistorial) ?? [];
    final ahora = DateTime.now();
    final limite = ahora.subtract(randomsVentana);
    final lista = <DateTime>[];
    for (final s in raw) {
      final t = DateTime.tryParse(s);
      if (t != null && t.isAfter(limite)) lista.add(t);
    }
    if (lista.length != raw.length) {
      await p.setStringList(
        _kRandomsHistorial,
        lista.map((t) => t.toIso8601String()).toList(),
      );
    }
    return lista;
  }

  static Future<int> randomsRestantes() async {
    final usados = await _randomsRecientes();
    return (randomsMax - usados.length).clamp(0, randomsMax);
  }

  static Future<DateTime?> proximoRandomDisponible() async {
    final usados = await _randomsRecientes();
    if (usados.length < randomsMax) return null;
    usados.sort();
    return usados.first.add(randomsVentana);
  }

  static Future<bool> registrarRandom() async {
    final p = await _prefs;
    final usados = await _randomsRecientes();
    if (usados.length >= randomsMax) return false;
    usados.add(DateTime.now());
    await p.setStringList(
      _kRandomsHistorial,
      usados.map((t) => t.toIso8601String()).toList(),
    );
    return true;
  }

  // Contador del botón "Sorpresa" (más limitado)
  static Future<List<DateTime>> _especialesRecientes() async {
    final p = await _prefs;
    final raw = p.getStringList(_kEspecialesHistorial) ?? [];
    final ahora = DateTime.now();
    final limite = ahora.subtract(randomsVentana);
    final lista = <DateTime>[];
    for (final s in raw) {
      final t = DateTime.tryParse(s);
      if (t != null && t.isAfter(limite)) lista.add(t);
    }
    if (lista.length != raw.length) {
      await p.setStringList(
        _kEspecialesHistorial,
        lista.map((t) => t.toIso8601String()).toList(),
      );
    }
    return lista;
  }

  static Future<int> especialesRestantes() async {
    final usados = await _especialesRecientes();
    return (especialesMax - usados.length).clamp(0, especialesMax);
  }

  static Future<DateTime?> proximoEspecialDisponible() async {
    final usados = await _especialesRecientes();
    if (usados.length < especialesMax) return null;
    usados.sort();
    return usados.first.add(randomsVentana);
  }

  static Future<bool> registrarEspecial() async {
    final p = await _prefs;
    final usados = await _especialesRecientes();
    if (usados.length >= especialesMax) return false;
    usados.add(DateTime.now());
    await p.setStringList(
      _kEspecialesHistorial,
      usados.map((t) => t.toIso8601String()).toList(),
    );
    return true;
  }

  // Reflexiones de 30 segundos
  static Future<int> _siguienteIdReflexion() async {
    final p = await _prefs;
    final actual = p.getInt(_kProximoIdReflexion) ?? 1;
    await p.setInt(_kProximoIdReflexion, actual + 1);
    return actual;
  }

  static Future<List<Reflexion>> obtenerReflexiones() async {
    final p = await _prefs;
    final raw = p.getStringList(_kReflexiones) ?? [];
    final lista = raw
        .map((s) => Reflexion.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    lista.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
    return lista;
  }

  static Future<Reflexion> guardarReflexion({
    required String frase,
    required String categoriaId,
    String? moodId,
    required String texto,
  }) async {
    final id = await _siguienteIdReflexion();
    final r = Reflexion(
      id: id,
      fechaHora: DateTime.now(),
      frase: frase,
      categoriaId: categoriaId,
      moodId: moodId,
      texto: texto.trim(),
    );
    final p = await _prefs;
    final lista = await obtenerReflexiones();
    lista.insert(0, r);
    await p.setStringList(
      _kReflexiones,
      lista.map((e) => jsonEncode(e.toJson())).toList(),
    );
    return r;
  }

  static Future<void> borrarReflexion(int id) async {
    final p = await _prefs;
    final lista = await obtenerReflexiones();
    final filtrada = lista.where((r) => r.id != id).toList();
    await p.setStringList(
      _kReflexiones,
      filtrada.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<EstadisticasReflexiones> obtenerEstadisticasReflexiones() async {
    final lista = await obtenerReflexiones();
    if (lista.isEmpty) {
      return const EstadisticasReflexiones(
        total: 0,
        diasConsecutivos: 0,
        moodMasFrecuente: null,
        totalDiasUnicos: 0,
      );
    }
    final diasSet = <String>{for (final r in lista) r.claveDia};

    int diasConsecutivos = 0;
    var cursor = DateTime.now();
    while (true) {
      final clave = claveDia(cursor);
      if (diasSet.contains(clave)) {
        diasConsecutivos++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        if (diasConsecutivos == 0 &&
            clave == claveDia(DateTime.now())) {
          cursor = cursor.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }

    final conteoMood = <Mood, int>{};
    for (final r in lista) {
      final m = r.mood;
      if (m != null) conteoMood[m] = (conteoMood[m] ?? 0) + 1;
    }
    Mood? moodMasFrecuente;
    int max = 0;
    conteoMood.forEach((mood, count) {
      if (count > max) {
        max = count;
        moodMasFrecuente = mood;
      }
    });

    return EstadisticasReflexiones(
      total: lista.length,
      diasConsecutivos: diasConsecutivos,
      moodMasFrecuente: moodMasFrecuente,
      totalDiasUnicos: diasSet.length,
    );
  }

  // Check-in matutino
  static Future<bool> checkinHechoHoy() async {
    final p = await _prefs;
    final ultimo = p.getString(_kCheckinDia);
    return ultimo == claveDia(DateTime.now());
  }

  static Future<Mood?> obtenerCheckinHoy() async {
    final p = await _prefs;
    final ultimo = p.getString(_kCheckinDia);
    if (ultimo != claveDia(DateTime.now())) return null;
    return Mood.fromId(p.getString(_kCheckinMood));
  }

  static Future<void> guardarCheckin(Mood mood) async {
    final p = await _prefs;
    await p.setString(_kCheckinDia, claveDia(DateTime.now()));
    await p.setString(_kCheckinMood, mood.id);
  }

  // Plantita
  static Future<String> obtenerNombrePlantita() async {
    final p = await _prefs;
    return p.getString(_kPlantitaNombre) ?? 'Mi plantita';
  }

  static Future<void> guardarNombrePlantita(String nombre) async {
    final p = await _prefs;
    await p.setString(_kPlantitaNombre, nombre.trim());
  }

  static Future<int> obtenerNivelPlantitaVisto() async {
    final p = await _prefs;
    return p.getInt(_kPlantitaUltimoNivel) ?? -1;
  }

  static Future<void> guardarNivelPlantitaVisto(int nivel) async {
    final p = await _prefs;
    await p.setInt(_kPlantitaUltimoNivel, nivel);
  }

  static Future<Reflexion?> reflexionNostalgica() async {
    final lista = await obtenerReflexiones();
    if (lista.isEmpty) return null;
    final ahora = DateTime.now();
    Reflexion? candidata;
    int mejorScore = -1;

    int score(int dias) {
      if (dias >= 365) return 1000 + (dias % 365);
      if (dias >= 180) return 900;
      if (dias >= 90) return 800;
      if (dias >= 60) return 700;
      if (dias >= 30) return 600;
      if (dias >= 14) return 500;
      if (dias >= 7) return 400;
      return -1;
    }

    for (final r in lista) {
      final dias = ahora.difference(r.fechaHora).inDays;
      final s = score(dias);
      if (s > mejorScore) {
        mejorScore = s;
        candidata = r;
      }
    }
    return candidata;
  }
}
