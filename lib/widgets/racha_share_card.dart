import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RachaShareCard extends StatelessWidget {
  final int dias;
  final String nombre;
  static const double widthLogical = 360;
  static const double heightLogical = 640;

  const RachaShareCard({
    super.key,
    required this.dias,
    this.nombre = '',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widthLogical,
      height: heightLogical,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.55, 1.0],
                colors: [
                  Color(0xFFFFDABE),
                  Color(0xFFE89B6A),
                  Color(0xFFB35E3A),
                ],
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.28),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFDABE).withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 80, 36, 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (nombre.isNotEmpty)
                  Text(
                    nombre,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Llevo',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Center(
                  child: Column(
                    children: [
                      const Text(
                        '🔥',
                        style: TextStyle(fontSize: 110),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dias',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 130,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dias == 1
                            ? 'día sin rendirme'
                            : 'días sin rendirme',
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🌅', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Un Día Más',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'un día a la vez',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
