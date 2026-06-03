import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/frases.dart';
import '../data/logros.dart';
import '../models/carta.dart';
import '../models/categoria.dart';
import '../services/storage_service.dart' show EntradaDiario, EstadisticasRacha;
import '../services/notification_service.dart';
import '../services/share_service.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/frase_card.dart';
import '../widgets/popup_logro.dart';
import '../widgets/racha_compacta.dart';
import '../widgets/story_card.dart';
import 'ajustes_screen.dart';
import 'diario_screen.dart';
import 'leer_carta_screen.dart';
import 'racha_screen.dart';

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
    Set<String> logrosAntes = {};
    EstadisticasRacha? stats;
    String frase = '';
    bool fav = false;
    EntradaDiario? diarioHoy;
    List<Carta> cartas = [];
    List<Logro> nuevos = [];

    try {
      nombre = await StorageService.obtenerNombre();
      cat = await StorageService.obtenerCategoria();
      logrosAntes = await StorageService.obtenerLogros();
      stats = await StorageService.registrarAperturaHoy();
      frase = Frases.delDia(cat, DateTime.now());
      fav = await StorageService.esFavorita(frase);
      diarioHoy = await StorageService.entradaDiarioHoy();
      cartas = await StorageService.cartasNoLeidasYDisponibles();
      _randomsRestantes = await StorageService.randomsRestantes();

      nuevos = Logros.nuevosDesbloqueados(stats.rachaActual, logrosAntes);
      for (final l in nuevos) {
        await StorageService.guardarLogro(l.id);
      }
    } catch (e) {
      debugPrint('Error cargando datos: $e');
      frase = Frases.delDia(cat, DateTime.now());
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
      _categoria = cat;
      _frase = frase;
      _racha = stats?.rachaActual ?? 0;
      _esFavorita = fav;
      _diarioHechoHoy = diarioHoy != null;
      _cartasPendientes = cartas;
      _cargando = false;
    });
    _animCtrl.forward();

    for (final l in nuevos) {
      if (!mounted) return;
      await mostrarPopupLogro(context, l);
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
    if (_nombre.isNotEmpty) return '$base, $_nombre';
    return base;
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

  Future<void> _otraEcuatoriana() async {
    final ok = await StorageService.registrarRandom();
    if (!ok) {
      if (!mounted) return;
      _mostrarLimiteRandom();
      return;
    }
    HapticFeedback.lightImpact();
    final nueva = Frases.aleatoriaEcuatoriana(excluir: _frase);
    final fav = await StorageService.esFavorita(nueva);
    final restantes = await StorageService.randomsRestantes();
    if (!mounted) return;
    setState(() {
      _frase = nueva;
      _esFavorita = fav;
      _randomsRestantes = restantes;
    });
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
                            child: Text(
                              _saludo(),
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: tonos.textoSuave,
                              ),
                              overflow: TextOverflow.ellipsis,
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
    final agotado = _randomsRestantes <= 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: agotado ? _mostrarLimiteRandom : _otraEcuatoriana,
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
              const Text('🇪🇨', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'Ecuatoriana',
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
