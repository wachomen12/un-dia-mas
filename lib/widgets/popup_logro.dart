import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/logros.dart';
import '../theme/app_theme.dart';
import 'confeti.dart';

class PopupLogro extends StatefulWidget {
  final Logro logro;
  const PopupLogro({super.key, required this.logro});

  @override
  State<PopupLogro> createState() => _PopupLogroState();
}

class _PopupLogroState extends State<PopupLogro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    return Stack(
      children: [
        const Positioned.fill(child: Confeti(duracionMs: 3000)),
        Center(
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
                decoration: BoxDecoration(
                  color: tonos.fondoClaro,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.terracota.withValues(alpha: 0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('¡Nuevo logro!',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.terracota,
                          letterSpacing: 1.2,
                        )),
                    const SizedBox(height: 12),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.naranjaSuave.withValues(alpha: 0.3),
                            AppColors.naranjaSuave.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(widget.logro.emoji,
                          style: const TextStyle(fontSize: 56)),
                    ),
                    const SizedBox(height: 12),
                    Text(widget.logro.titulo,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: tonos.textoOscuro,
                        )),
                    const SizedBox(height: 6),
                    Text(widget.logro.descripcion,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          color: tonos.textoSuave,
                          height: 1.4,
                        )),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Genial'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> mostrarPopupLogro(BuildContext context, Logro logro) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => PopupLogro(logro: logro),
  );
}
