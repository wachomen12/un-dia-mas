import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/categoria.dart';
import '../models/reflexion.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class MiCaminoScreen extends StatefulWidget {
  const MiCaminoScreen({super.key});

  @override
  State<MiCaminoScreen> createState() => _MiCaminoScreenState();
}

class _MiCaminoScreenState extends State<MiCaminoScreen>
    with SingleTickerProviderStateMixin {
  List<Reflexion> _reflexiones = [];
  EstadisticasReflexiones? _stats;
  Reflexion? _nostalgia;
  bool _cargando = true;
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cargar();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final lista = await StorageService.obtenerReflexiones();
    final stats = await StorageService.obtenerEstadisticasReflexiones();
    final nostalgia = await StorageService.reflexionNostalgica();
    if (!mounted) return;
    setState(() {
      _reflexiones = lista;
      _stats = stats;
      _nostalgia = nostalgia;
      _cargando = false;
    });
    _fadeCtrl.forward();
  }

  Future<void> _borrar(Reflexion r) async {
    HapticFeedback.mediumImpact();
    final confirma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar esta reflexión?'),
        content: const Text(
            'Esta es parte de tu camino. Si la borras no podrás recuperarla.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Borrar',
              style: GoogleFonts.nunito(
                color: AppColors.terracota,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirma == true) {
      await StorageService.borrarReflexion(r.id);
      _cargar();
    }
  }

  String _diasRelativo(DateTime t) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final cuando = DateTime(t.year, t.month, t.day);
    final dias = hoy.difference(cuando).inDays;
    if (dias == 0) return 'Hoy';
    if (dias == 1) return 'Ayer';
    if (dias < 7) return 'Hace $dias días';
    if (dias < 30) {
      final semanas = (dias / 7).round();
      return semanas == 1
          ? 'Hace 1 semana'
          : 'Hace $semanas semanas';
    }
    if (dias < 365) {
      final meses = (dias / 30).round();
      return meses == 1 ? 'Hace 1 mes' : 'Hace $meses meses';
    }
    final anios = (dias / 365).round();
    return anios == 1 ? 'Hace 1 año' : 'Hace $anios años';
  }

  String _frase(DateTime t) {
    final dias = DateTime.now().difference(t).inDays;
    if (dias >= 365) return 'Mira cuánto has avanzado.';
    if (dias >= 180) return 'Esto eras hace medio año.';
    if (dias >= 90) return 'Tres meses atrás te escribías esto.';
    if (dias >= 60) return 'Dos meses, y aquí seguís.';
    if (dias >= 30) return 'Hace 30 días escribiste esto. Mira cuánto has crecido.';
    if (dias >= 14) return 'Hace dos semanas pensabas esto. Mira hoy.';
    return 'Esto te dijiste hace poco. Vale releerlo.';
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.terracota)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mi Camino',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
          child: _reflexiones.isEmpty
              ? _vacio(tonos)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    _estadisticas(tonos),
                    const SizedBox(height: 20),
                    if (_nostalgia != null) ...[
                      _bannerNostalgia(_nostalgia!, tonos),
                      const SizedBox(height: 20),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Tu línea del tiempo',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: tonos.textoSuave,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    ..._reflexiones.asMap().entries.map(
                          (e) => _timelineItem(
                            e.value,
                            esUltimo: e.key == _reflexiones.length - 1,
                            tonos: tonos,
                          ),
                        ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _vacio(Tonos tonos) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Tu camino empieza aquí',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: tonos.textoOscuro,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Cada vez que una frase te toque,\nescribe lo que te dice en este momento.\n\nUn día vas a volver a leer esto y\nvas a ver cuánto has crecido.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                height: 1.5,
                color: tonos.textoSuave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadisticas(Tonos tonos) {
    final s = _stats!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.naranjaSuave.withValues(alpha: 0.22),
            AppColors.terracota.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _stat('${s.total}', 'reflexiones', tonos),
          _separador(tonos),
          _stat('${s.diasConsecutivos}', 'días seguidos', tonos),
          _separador(tonos),
          _statMood(s.moodMasFrecuente, tonos),
        ],
      ),
    );
  }

  Widget _separador(Tonos tonos) {
    return Container(
      width: 1,
      height: 36,
      color: tonos.textoSuave.withValues(alpha: 0.2),
    );
  }

  Widget _stat(String valor, String etiqueta, Tonos tonos) {
    return Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.terracota,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tonos.textoSuave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statMood(dynamic mood, Tonos tonos) {
    return Expanded(
      child: Column(
        children: [
          if (mood != null)
            Text(mood.emoji, style: const TextStyle(fontSize: 30))
          else
            Text(
              '—',
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: tonos.textoSuave,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            mood != null ? 'más frecuente' : 'sin mood aún',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tonos.textoSuave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerNostalgia(Reflexion r, Tonos tonos) {
    final fecha = DateFormat.yMMMMd('es').format(r.fechaHora);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tonos.cremaTarjeta,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.naranjaSuave.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌅', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _frase(r.fechaHora),
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.terracota,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            fecha,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: tonos.textoSuave,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '“${r.frase}”',
            style: GoogleFonts.playfairDisplay(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: tonos.textoOscuro,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            r.texto,
            style: GoogleFonts.nunito(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: tonos.textoOscuro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(Reflexion r, {required bool esUltimo, required Tonos tonos}) {
    final cat = Categoria.fromId(r.categoriaId);
    final relativo = _diasRelativo(r.fechaHora);
    final hora = DateFormat.Hm().format(r.fechaHora);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.terracota,
                    border: Border.all(color: tonos.fondo, width: 3),
                  ),
                ),
                if (!esUltimo)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.naranjaSuave.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 14),
              child: GestureDetector(
                onLongPress: () => _borrar(r),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tonos.cremaTarjeta,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            relativo,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.terracota,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· $hora',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: tonos.textoSuave,
                            ),
                          ),
                          const Spacer(),
                          if (r.mood != null)
                            Text(r.mood!.emoji,
                                style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '“${r.frase}”',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: tonos.textoSuave,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        r.texto,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: tonos.textoOscuro,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${cat.emoji}  ${cat.nombre}',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: tonos.textoSuave,
                        ),
                      ),
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
}
