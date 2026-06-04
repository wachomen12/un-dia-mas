import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/plantitas.dart';
import '../theme/app_theme.dart';
import 'confeti.dart';

Future<void> mostrarPopupNivelPlantita(
  BuildContext context,
  EtapaPlantita etapa,
) async {
  HapticFeedback.heavyImpact();
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _PopupNivel(etapa: etapa),
  );
}

class _PopupNivel extends StatefulWidget {
  final EtapaPlantita etapa;
  const _PopupNivel({required this.etapa});

  @override
  State<_PopupNivel> createState() => _PopupNivelState();
}

class _PopupNivelState extends State<_PopupNivel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
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
        const Positioned.fill(child: Confeti(duracionMs: 3500)),
        Center(
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
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
                    Text(
                      'Tu plantita evolucionó',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.terracota,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.naranjaSuave.withValues(alpha: 0.35),
                            AppColors.naranjaSuave.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(widget.etapa.emoji,
                          style: const TextStyle(fontSize: 72)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.etapa.nombre,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: tonos.textoOscuro,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.etapa.descripcion,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        color: tonos.textoSuave,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Chévere'),
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
