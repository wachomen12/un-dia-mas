import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class FraseCard extends StatelessWidget {
  final String frase;
  final bool conMarca;

  const FraseCard({
    super.key,
    required this.frase,
    this.conMarca = false,
  });

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tonos.cremaTarjeta,
            tonos.fondoClaro,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.terracota.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '“',
            style: GoogleFonts.playfairDisplay(
              fontSize: 64,
              height: 0.8,
              color: AppColors.naranjaSuave,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            frase,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 22,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: tonos.textoOscuro,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.naranjaSuave,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (conMarca) ...[
            const SizedBox(height: 20),
            Text(
              'Un Día Más',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: AppColors.terracota,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
