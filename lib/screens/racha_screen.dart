import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/share_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/calendario_semana.dart';
import '../widgets/racha_share_card.dart';
import 'logros_screen.dart';

class RachaScreen extends StatefulWidget {
  const RachaScreen({super.key});

  @override
  State<RachaScreen> createState() => _RachaScreenState();
}

class _RachaScreenState extends State<RachaScreen>
    with SingleTickerProviderStateMixin {
  EstadisticasRacha? _stats;
  String _nombre = '';
  final GlobalKey _shareRachaKey = GlobalKey();
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    StorageService.obtenerEstadisticas().then((s) {
      if (mounted) setState(() => _stats = s);
    });
    StorageService.obtenerNombre().then((n) {
      if (mounted) setState(() => _nombre = n);
    });
  }

  Future<void> _compartirRacha() async {
    HapticFeedback.lightImpact();
    try {
      await ShareService.compartirDesdeKey(_shareRachaKey, pixelRatio: 3.0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo compartir: $e')),
      );
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _mensajePorRacha(int r) {
    if (r == 0) return 'Hoy es un buen día para empezar.';
    if (r == 1) return 'Empezaste. Lo demás es seguir.';
    if (r < 4) return 'Vas tomando ritmo. Sigue así.';
    if (r < 7) return 'Una semana se acerca. No la sueltes.';
    if (r < 14) return 'Más de una semana. Eres consistente.';
    if (r < 30) return 'Lo que haces es disciplina. Te admiro.';
    if (r < 100) return 'Esto ya es parte de ti.';
    return 'Eres inspiración. En serio.';
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    final s = _stats;
    if (s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi racha'),
        actions: [
          IconButton(
            tooltip: 'Compartir mi racha',
            icon: const Icon(Icons.ios_share),
            onPressed: s.rachaActual == 0 ? null : _compartirRacha,
          ),
          IconButton(
            tooltip: 'Mis logros',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LogrosScreen()),
            ),
          ),
        ],
      ),
      body: Stack(children: [
        Positioned(
          left: -10000,
          top: 0,
          child: RepaintBoundary(
            key: _shareRachaKey,
            child: RachaShareCard(dias: s.rachaActual, nombre: _nombre),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _llamaGrande(s.rachaActual),
              const SizedBox(height: 8),
              Text(
                s.rachaActual == 1
                    ? 'día seguido contigo'
                    : 'días seguidos contigo',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: tonos.textoSuave,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: tonos.cremaTarjeta,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      'Esta semana',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tonos.textoSuave,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CalendarioSemana(diasVistos: s.diasVistos),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _statTarjeta('Récord', '${s.maxRacha}', 'días', tonos),
                  const SizedBox(width: 12),
                  _statTarjeta('Total', '${s.totalDias}', 'días', tonos),
                ],
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LogrosScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: tonos.cremaTarjeta,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.naranjaSuave.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mis logros',
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: tonos.textoOscuro,
                                  )),
                              Text('Medallas que has ganado',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: tonos.textoSuave,
                                  )),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: tonos.textoSuave),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.naranjaSuave.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('💌', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _mensajePorRacha(s.rachaActual),
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          height: 1.4,
                          color: tonos.textoOscuro,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        ),
      ]),
    );
  }

  Widget _llamaGrande(int n) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.naranjaSuave.withValues(alpha: 0.3),
                AppColors.naranjaSuave.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulse,
              child: const Text('🔥', style: TextStyle(fontSize: 80)),
            ),
            Text(
              '$n',
              style: GoogleFonts.playfairDisplay(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: AppColors.terracota,
                height: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statTarjeta(String titulo, String valor, String unidad, Tonos tonos) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: tonos.cremaTarjeta,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              titulo,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tonos.textoSuave,
              ),
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.terracota,
                ),
                children: [
                  TextSpan(text: valor),
                  TextSpan(
                    text: ' $unidad',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tonos.textoSuave,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
