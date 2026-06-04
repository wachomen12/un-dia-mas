import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/mood.dart';
import '../theme/app_theme.dart';

class CheckInScreen extends StatefulWidget {
  final String nombre;
  const CheckInScreen({super.key, required this.nombre});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with SingleTickerProviderStateMixin {
  Mood? _seleccionado;
  bool _confirmando = false;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _elegir(Mood m) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _seleccionado = m;
      _confirmando = true;
    });
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.of(context).pop(m);
  }

  void _saltar() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(null);
  }

  String _saludo() {
    final h = DateTime.now().hour;
    if (h < 6) return 'Buenas noches';
    if (h < 13) return 'Buenos días';
    if (h < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    AppColors.fondoDark,
                    AppColors.cremaTarjetaDark,
                    AppColors.fondoDark,
                  ]
                : [
                    const Color(0xFFFFDABE),
                    const Color(0xFFFFEFE0),
                    AppColors.fondo,
                  ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 2),
                    Text(
                      widget.nombre.isEmpty
                          ? _saludo()
                          : '${_saludo()}, ${widget.nombre}',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: tonos.textoSuave,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '¿Cómo amaneciste hoy?',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: tonos.textoOscuro,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Tu frase de hoy se va a adaptar a cómo te sientes.',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        height: 1.4,
                        color: tonos.textoSuave,
                      ),
                    ),
                    const Spacer(flex: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _confirmando
                          ? _confirmacion(tonos)
                          : Column(
                              key: const ValueKey('moods'),
                              children: Mood.values
                                  .map((m) => _opcion(m, tonos))
                                  .toList(),
                            ),
                    ),
                    const Spacer(flex: 3),
                    if (!_confirmando)
                      Center(
                        child: TextButton(
                          onPressed: _saltar,
                          child: Text(
                            'Mejor mañana →',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tonos.textoSuave,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _opcion(Mood m, Tonos tonos) {
    final sel = m == _seleccionado;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _elegir(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.terracota
                  : tonos.cremaTarjeta.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel
                    ? AppColors.terracota
                    : AppColors.naranjaSuave.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                AnimatedScale(
                  scale: sel ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(m.emoji, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    m.nombre,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: sel ? Colors.white : tonos.textoOscuro,
                    ),
                  ),
                ),
                if (sel)
                  const Icon(Icons.check_circle, color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _confirmacion(Tonos tonos) {
    final m = _seleccionado!;
    return Container(
      key: const ValueKey('confirm'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: tonos.cremaTarjeta,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(m.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            m.mensajeCarinoso(),
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: tonos.textoOscuro,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

Future<Mood?> mostrarCheckIn(BuildContext context, {required String nombre}) {
  return Navigator.of(context).push<Mood>(
    PageRouteBuilder<Mood>(
      opaque: true,
      pageBuilder: (_, __, ___) => CheckInScreen(nombre: nombre),
      transitionsBuilder: (_, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    ),
  );
}
