import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/mood.dart';
import '../theme/app_theme.dart';

class MoodSelector extends StatelessWidget {
  final Mood? seleccionado;
  final ValueChanged<Mood?> onCambio;
  final bool conTitulo;

  const MoodSelector({
    super.key,
    required this.seleccionado,
    required this.onCambio,
    this.conTitulo = true,
  });

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (conTitulo)
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4),
            child: Text(
              '¿Cómo te sientes hoy?',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: tonos.textoSuave,
                letterSpacing: 0.3,
              ),
            ),
          ),
        Row(
          children: Mood.values
              .map((m) => Expanded(
                    child: _opcion(m, m == seleccionado, tonos),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _opcion(Mood m, bool sel, Tonos tonos) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onCambio(sel ? null : m);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel
              ? AppColors.terracota.withValues(alpha: 0.15)
              : tonos.cremaTarjeta,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sel
                ? AppColors.terracota
                : AppColors.naranjaSuave.withValues(alpha: 0.2),
            width: sel ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            AnimatedScale(
              scale: sel ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: Text(m.emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 2),
            Text(
              m.nombre,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: sel ? AppColors.terracota : tonos.textoSuave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
