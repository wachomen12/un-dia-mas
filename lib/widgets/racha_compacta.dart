import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class RachaCompacta extends StatefulWidget {
  final int racha;
  final VoidCallback? onTap;

  const RachaCompacta({super.key, required this.racha, this.onTap});

  @override
  State<RachaCompacta> createState() => _RachaCompactaState();
}

class _RachaCompactaState extends State<RachaCompacta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    final activa = widget.racha > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: activa
                  ? [
                      AppColors.naranjaSuave.withValues(alpha: 0.25),
                      AppColors.terracota.withValues(alpha: 0.15),
                    ]
                  : [
                      Colors.grey.withValues(alpha: 0.15),
                      Colors.grey.withValues(alpha: 0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: activa
                  ? AppColors.naranjaSuave.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              activa
                  ? ScaleTransition(
                      scale: _scale,
                      child: const Text('🔥',
                          style: TextStyle(fontSize: 22)),
                    )
                  : const Text('🌱', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.racha == 0
                        ? 'Empieza'
                        : widget.racha == 1
                            ? '1 día'
                            : '${widget.racha} días',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.terracota,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    widget.racha == 0 ? 'tu racha' : 'sin rendirte',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: tonos.textoSuave,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
