import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/frases.dart';
import '../data/logros.dart';
import '../data/plantitas.dart';
import '../models/carta.dart';
import '../models/categoria.dart';
import '../models/intencion.dart';
import '../models/mood.dart';
import '../services/storage_service.dart' show EntradaDiario, EstadisticasRacha;
import '../services/notification_service.dart';
import '../services/share_service.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/frase_card.dart';
import '../widgets/popup_logro.dart';
import '../widgets/popup_nivel_plantita.dart';
import '../widgets/racha_compacta.dart';
import '../widgets/story_card.dart';
import 'ajustes_screen.dart';
import 'check_in_screen.dart';
import 'diario_screen.dart';
import 'intencion_modal.dart';
import 'leer_carta_screen.dart';
import 'mi_camino_screen.dart';
import 'plantita_screen.dart';
import 'racha_screen.dart';
import 'reflexion_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _shareKey = GlobalKey();
  final GlobalKey _storyKey = GlobalKey();

  Categoria? _categoria;
  String _nombre = '';
  String _frase = '';
  int _racha = 0;
  bool _esFavorita = false;
  bool _diarioHechoHoy = false;
  List<Carta> _cartasPendientes = [];
  bool _cargando = true;
  int _randomsRestantes = StorageService.randomsMax;
  int _especialesRestantes = StorageService.especialesMax;
  Mood? _moodHoy;
  EtapaPlantita _etapaPlantita = Plantitas.etapas.first;
  EtapaPlantita? _nuevoNivelPlantita;
  Intencion? _intencionHoy;
  Intencion? _intencionPendiente;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _cargar();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    String nombre = '';
    Categoria cat = Categoria.momentoDificil;
    Categoria catFrase = Categoria.momentoDificil;
    Set<String> logrosAntes = {};
    EstadisticasRacha? stats;
    String frase = '';
    bool fav = false;
    EntradaDiario? diarioHoy;
    List<Carta> cartas = [];
    List<Logro> nuevos = [];
    Mood? moodHoy;

    try {
      nombre = await StorageService.obtenerNombre();
      cat = await StorageService.obtenerCategoria();
      moodHoy = await StorageService.obtenerCheckinHoy();
    } catch (e) {
      debugPrint('Error pre-checkin: $e');
    }

    if (moodHoy == null && mounted) {
      try {
        final picked = await mostrarCheckIn(context, nombre: nombre);
        if (picked != null) {
          await StorageService.guardarCheckin(picked);
          moodHoy = picked;
        }
      } catch (e) {
        debugPrint('Error en check-in: $e');
      }
    }

    catFrase = moodHoy?.categoriaSugerida(cat) ?? cat;

    try {
      logrosAntes = await StorageService.obtenerLogros();
      stats = await StorageService.registrarAperturaHoy();
      frase = Frases.delDia(catFrase, DateTime.now());
      fav = await StorageService.esFavorita(frase);
      diarioHoy = await StorageService.entradaDiarioHoy();
      cartas = await StorageService.cartasNoLeidasYDisponibles();
      _randomsRestantes = await StorageService.randomsRestantes();
      _especialesRestantes = await StorageService.especialesRestantes();

      nuevos = Logros.nuevosDesbloqueados(stats.rachaActual, logrosAntes);
      for (final l in nuevos) {
        await StorageService.guardarLogro(l.id);
      }

      _etapaPlantita = Plantitas.actual(stats.totalDias);
      final nivelVisto = await StorageService.obtenerNivelPlantitaVisto();
      if (_etapaPlantita.nivel > nivelVisto) {
        _nuevoNivelPlantita = _etapaPlantita;
        await StorageService.guardarNivelPlantitaVisto(_etapaPlantita.nivel);
      }

      _intencionHoy = await StorageService.intencionHoy();
      _intencionPendiente = await StorageService.intencionPendienteDeRevisar();
    } catch (e) {
      debugPrint('Error cargando datos: $e');
      frase = Frases.delDia(catFrase, DateTime.now());
    }

    try {
      await NotificationService.programarRecordatorioCarinoso()
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Error programando recordatorio: $e');
    }

    try {
      await WidgetService.actualizarConDatos()
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Error actualizando widget: $e');
    }

    if (!mounted) return;
    setState(() {
      _nombre = nombre;
      _categoria = catFrase;
      _frase = frase;
      _racha = stats?.rachaActual ?? 0;
      _esFavorita = fav;
      _diarioHechoHoy = diarioHoy != null;
      _cartasPendientes = cartas;
      _moodHoy = moodHoy;
      _cargando = false;
    });
    _animCtrl.forward();

    for (final l in nuevos) {
      if (!mounted) return;
      await mostrarPopupLogro(context, l);
    }

    if (_nuevoNivelPlantita != null && mounted) {
      await mostrarPopupNivelPlantita(context, _nuevoNivelPlantita!);
      _nuevoNivelPlantita = null;
    }
  }

  String? _mensajeDiaSemana() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 'Nueva semana ✨';
      case DateTime.wednesday:
        return 'Mitad de semana 🌿';
      case DateTime.friday:
        return 'Llegaste a viernes 🌅';
      case DateTime.saturday:
        return 'Sábado, despacito';
      case DateTime.sunday:
        return 'Domingo de pausa 💛';
      default:
        return null;
    }
  }

  Future<void> _abrirPlantita() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlantitaScreen()),
    );
  }

  Future<void> _definirIntencion() async {
    final ok = await abrirIntencionModal(
      context,
      textoInicial: _intencionHoy?.texto,
    );
    if (ok && mounted) {
      final nueva = await StorageService.intencionHoy();
      if (mounted) setState(() => _intencionHoy = nueva);
    }
  }

  Future<void> _responderIntencionPendiente(ResultadoIntencion r) async {
    if (_intencionPendiente == null) return;
    HapticFeedback.mediumImpact();
    await StorageService.registrarResultadoIntencion(
      _intencionPendiente!.fecha,
      r,
    );
    if (!mounted) return;
    setState(() => _intencionPendiente = null);
    if (r == ResultadoIntencion.cumplida) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Bien hecho! Tu plantita sonríe 🌱'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _saludo() {
    final h = DateTime.now().hour;
    String base;
    if (h < 6) {
      base = 'Buenas noches';
    } else if (h < 13) {
      base = 'Buenos días';
    } else if (h < 20) {
      base = 'Buenas tardes';
    } else {
      base = 'Buenas noches';
    }
    final emoji = _moodHoy != null ? ' ${_moodHoy!.emoji}' : '';
    if (_nombre.isNotEmpty) return '$base, $_nombre$emoji';
    return '$base$emoji';
  }

  Future<void> _compartirStory() async {
    HapticFeedback.lightImpact();
    try {
      await ShareService.compartirDesdeKey(_storyKey, pixelRatio: 3.0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo compartir: $e')),
      );
    }
  }

  Future<void> _copiar() async {
    HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: _frase));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Frase copiada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _otraFraseRandom() async {
    if (_categoria == null) return;
    final ok = await StorageService.registrarRandom();
    if (!ok) {
      if (!mounted) return;
      _mostrarLimiteRandom();
      return;
    }
    HapticFeedback.lightImpact();
    final nueva = Frases.aleatoria(_categoria!, excluir: _frase);
    final fav = await StorageService.esFavorita(nueva);
    final restantes = await StorageService.randomsRestantes();
    if (!mounted) return;
    setState(() {
      _frase = nueva;
      _esFavorita = fav;
      _randomsRestantes = restantes;
    });
  }

  Future<void> _otraEspecial() async {
    final ok = await StorageService.registrarEspecial();
    if (!ok) {
      if (!mounted) return;
      _mostrarLimiteEspecial();
      return;
    }
    HapticFeedback.mediumImpact();
    final nueva = Frases.aleatoriaEcuatoriana(excluir: _frase);
    final fav = await StorageService.esFavorita(nueva);
    final restantes = await StorageService.especialesRestantes();
    if (!mounted) return;
    setState(() {
      _frase = nueva;
      _esFavorita = fav;
      _especialesRestantes = restantes;
    });
  }

  Future<void> _mostrarLimiteEspecial() async {
    HapticFeedback.mediumImpact();
    final proximo = await StorageService.proximoEspecialDisponible();
    String texto;
    if (proximo == null) {
      texto = 'Vuelve en un rato.';
    } else {
      final diferencia = proximo.difference(DateTime.now());
      if (diferencia.inMinutes < 60) {
        texto = 'En ${diferencia.inMinutes} minutos tienes otra.';
      } else {
        final horas = diferencia.inMinutes ~/ 60;
        final mins = diferencia.inMinutes % 60;
        texto = 'En ${horas}h ${mins}min tienes otra.';
      }
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sorpresas agotadas ✨'),
        content: Text(
          'Ya viste 3 sorpresas en las últimas 8 horas. Son frases especiales por algo.\n\n$texto',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarLimiteRandom() async {
    HapticFeedback.mediumImpact();
    final proximo = await StorageService.proximoRandomDisponible();
    String texto;
    if (proximo == null) {
      texto = 'Vuelve en un rato.';
    } else {
      final diferencia = proximo.difference(DateTime.now());
      if (diferencia.inMinutes < 60) {
        texto = 'En ${diferencia.inMinutes} minutos tienes una nueva.';
      } else {
        final horas = diferencia.inMinutes ~/ 60;
        final mins = diferencia.inMinutes % 60;
        texto = 'En ${horas}h ${mins}min tienes una nueva.';
      }
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Llegaste al límite 🌿'),
        content: Text(
          'Ya viste 10 frases en las últimas 8 horas.\n\n$texto\n\nLa frase del día sigue aquí, contigo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _alternarFavorita() async {
    HapticFeedback.mediumImpact();
    final nuevo = await StorageService.alternarFavorita(_frase);
    if (!mounted) return;
    setState(() => _esFavorita = nuevo);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nuevo ? 'Guardada en favoritas 🤍' : 'Quitada de favoritas'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _abrirRacha() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RachaScreen()),
    );
  }

  Future<void> _abrirReflexion() async {
    if (_categoria == null) return;
    final guardada = await abrirReflexionModal(
      context,
      frase: _frase,
      categoria: _categoria!,
    );
    if (guardada && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tu reflexión vive en Mi Camino 💭'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.white,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MiCaminoScreen()),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _abrirDiario() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DiarioScreen()),
    );
    final hoy = await StorageService.entradaDiarioHoy();
    if (mounted) setState(() => _diarioHechoHoy = hoy != null);
  }

  Future<void> _abrirCarta(Carta c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LeerCartaScreen(carta: c)),
    );
    final cartas = await StorageService.cartasNoLeidasYDisponibles();
    if (mounted) setState(() => _cartasPendientes = cartas);
  }

  Future<void> _abrirAjustes() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AjustesScreen()),
    );
    final cat = await StorageService.obtenerCategoria();
    final hora = await StorageService.obtenerHora();
    final nombre = await StorageService.obtenerNombre();
    await NotificationService.programarDiaria(
      hora: hora.hora,
      minuto: hora.minuto,
      categoria: cat,
    );
    await WidgetService.actualizarConDatos();
    if (!mounted) return;
    final nuevaFrase = Frases.delDia(cat, DateTime.now());
    final fav = await StorageService.esFavorita(nuevaFrase);
    if (!mounted) return;
    setState(() {
      _categoria = cat;
      _nombre = nombre;
      _frase = nuevaFrase;
      _esFavorita = fav;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    if (_cargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.terracota),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Un Día Más',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Mi plantita',
            onPressed: _abrirPlantita,
            icon: Text(
              _etapaPlantita.emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _abrirAjustes,
            tooltip: 'Ajustes',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            left: -10000,
            top: 0,
            child: RepaintBoundary(
              key: _storyKey,
              child: StoryCard(frase: _frase),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _saludo(),
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: tonos.textoSuave,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_mensajeDiaSemana() != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      _mensajeDiaSemana()!,
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.terracota,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          RachaCompacta(racha: _racha, onTap: _abrirRacha),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_cartasPendientes.isNotEmpty) ...[
                        _bannerCarta(_cartasPendientes.first, tonos),
                        const SizedBox(height: 12),
                      ],
                      if (_intencionPendiente != null) ...[
                        _bannerRevisarIntencion(_intencionPendiente!, tonos),
                        const SizedBox(height: 12),
                      ],
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.terracota,
                          onRefresh: () async {
                            if (_randomsRestantes > 0) {
                              await _otraFraseRandom();
                            } else {
                              await _mostrarLimiteRandom();
                            }
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Center(
                              child: RepaintBoundary(
                                key: _shareKey,
                                child: Container(
                                  color: tonos.fondo,
                                  padding: const EdgeInsets.all(8),
                                  child: AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 350),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    transitionBuilder: (child, anim) =>
                                        FadeTransition(
                                      opacity: anim,
                                      child: child,
                                    ),
                                    child: FraseCard(
                                      key: ValueKey(_frase),
                                      frase: _frase,
                                      conMarca: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_categoria != null)
                        Text(
                          '${_categoria!.emoji}  ${_categoria!.nombre}',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: tonos.textoSuave,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _botonOtraFrase(tonos),
                          const SizedBox(width: 8),
                          _botonEcuatoriana(tonos),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _cardIntencion(tonos),
                      const SizedBox(height: 10),
                      _promptReflexion(tonos),
                      const SizedBox(height: 10),
                      if (!_diarioHechoHoy) _promptDiario(tonos),
                      if (!_diarioHechoHoy) const SizedBox(height: 10),
                      Row(
                        children: [
                          _accionRedonda(
                            icono: _esFavorita
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _esFavorita
                                ? AppColors.terracota
                                : tonos.textoSuave,
                            onTap: _alternarFavorita,
                            tooltip: 'Favorita',
                            tonos: tonos,
                          ),
                          const SizedBox(width: 10),
                          _accionRedonda(
                            icono: Icons.copy_outlined,
                            color: tonos.textoSuave,
                            onTap: _copiar,
                            tooltip: 'Copiar',
                            tonos: tonos,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _compartirStory,
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Compartir'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonEcuatoriana(Tonos tonos) {
    final agotado = _especialesRestantes <= 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: agotado ? _mostrarLimiteEspecial : _otraEspecial,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: agotado
                ? Colors.grey.withValues(alpha: 0.15)
                : AppColors.verdeSuave.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: agotado
                  ? Colors.grey.withValues(alpha: 0.3)
                  : AppColors.verdeSuave.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(agotado ? '🌿' : '✨', style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                agotado ? 'Espera' : 'Sorpresa · $_especialesRestantes',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: agotado
                      ? tonos.textoSuave
                      : AppColors.verdeSuave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonOtraFrase(Tonos tonos) {
    final agotado = _randomsRestantes <= 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: agotado ? _mostrarLimiteRandom : _otraFraseRandom,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: agotado
                ? Colors.grey.withValues(alpha: 0.15)
                : AppColors.terracota.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: agotado
                  ? Colors.grey.withValues(alpha: 0.3)
                  : AppColors.terracota.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(agotado ? '🌿' : '🎲', style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                agotado ? 'Espera' : 'Otra · $_randomsRestantes',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: agotado ? tonos.textoSuave : AppColors.terracota,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardIntencion(Tonos tonos) {
    if (_intencionHoy == null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _definirIntencion,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: tonos.cremaTarjeta,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.terracota.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Definí tu intención del día',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: tonos.textoOscuro,
                        ),
                      ),
                      Text(
                        'Una sola cosa, foco real',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: tonos.textoSuave,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: tonos.textoSuave),
              ],
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _definirIntencion,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.terracota.withValues(alpha: 0.15),
                AppColors.naranjaSuave.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.terracota.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TU MISIÓN DE HOY',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.terracota,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _intencionHoy!.texto,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: tonos.textoOscuro,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit_outlined, size: 18, color: tonos.textoSuave),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerRevisarIntencion(Intencion i, Tonos tonos) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: tonos.cremaTarjeta,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.naranjaSuave.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💭', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Cumpliste tu intención?',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: tonos.textoOscuro,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '"${i.texto}"',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: tonos.textoSuave,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _botonRespuesta(
                  '✅', 'Sí', AppColors.terracota,
                  () => _responderIntencionPendiente(
                      ResultadoIntencion.cumplida),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _botonRespuesta(
                  '🤝', 'Casi', AppColors.naranjaSuave,
                  () => _responderIntencionPendiente(
                      ResultadoIntencion.intentada),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _botonRespuesta(
                  '🌿', 'No', tonos.textoSuave,
                  () => _responderIntencionPendiente(
                      ResultadoIntencion.noCumplida),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botonRespuesta(
      String emoji, String texto, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                texto,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerCarta(Carta c, Tonos tonos) {
    final restantes = _cartasPendientes.length - 1;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _abrirCarta(c),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.naranjaSuave, AppColors.terracota],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.terracota.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('📬', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restantes > 0
                          ? 'Tienes ${restantes + 1} cartas esperándote'
                          : 'Te llegó una carta',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Toca para leerla',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promptReflexion(Tonos tonos) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _abrirReflexion,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.terracota.withValues(alpha: 0.12),
                AppColors.naranjaSuave.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.terracota.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              const Text('💭', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Qué significa esta frase para ti hoy?',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: tonos.textoOscuro,
                      ),
                    ),
                    Text(
                      'Reflexión de 30 segundos · 150 caracteres',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: tonos.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: tonos.textoSuave),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promptDiario(Tonos tonos) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _abrirDiario,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: tonos.cremaTarjeta,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.naranjaSuave.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Text('📝', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Cómo te sientes hoy?',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: tonos.textoOscuro,
                      ),
                    ),
                    Text(
                      'Una línea + mood',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: tonos.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: tonos.textoSuave),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accionRedonda({
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
    required Tonos tonos,
  }) {
    return Material(
      color: tonos.cremaTarjeta,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            child: Icon(icono, color: color, size: 24),
          ),
        ),
      ),
    );
  }
}
