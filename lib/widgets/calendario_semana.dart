import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class CalendarioSemana extends StatelessWidget {
  final Set<String> diasVistos;

  const CalendarioSemana({super.key, required this.diasVistos});

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
    const etiquetas = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final tonos = Tonos.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final dia = lunes.add(Duration(days: i));
        final clave = StorageService.claveDia(dia);
        final esFuturo = dia.isAfter(DateTime(hoy.year, hoy.month, hoy.day));
        final visto = diasVistos.contains(clave);
        final esHoy = clave == StorageService.claveDia(hoy);
        return _DiaCirculo(
          etiqueta: etiquetas[i],
          numero: dia.day,
          visto: visto,
          esHoy: esHoy,
          esFuturo: esFuturo,
          tonos: tonos,
        );
      }),
    );
  }
}

class _DiaCirculo extends StatelessWidget {
  final String etiqueta;
  final int numero;
  final bool visto;
  final bool esHoy;
  final bool esFuturo;
  final Tonos tonos;

  const _DiaCirculo({
    required this.etiqueta,
    required this.numero,
    required this.visto,
    required this.esHoy,
    required this.esFuturo,
    required this.tonos,
  });

  @override
  Widget build(BuildContext context) {
    final Color fondo;
    final Color borde;
    final Widget contenido;

    if (visto) {
      fondo = AppColors.terracota;
      borde = AppColors.terracota;
      contenido = const Text('🔥', style: TextStyle(fontSize: 18));
    } else if (esFuturo) {
      fondo = Colors.transparent;
      borde = Colors.grey.withValues(alpha: 0.3);
      contenido = Text(
        '$numero',
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.withValues(alpha: 0.6),
        ),
      );
    } else {
      fondo = Colors.grey.withValues(alpha: 0.12);
      borde = Colors.grey.withValues(alpha: 0.3);
      contenido = Text(
        '$numero',
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: tonos.textoSuave,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          etiqueta,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: esHoy ? AppColors.terracota : tonos.textoSuave,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: fondo,
            shape: BoxShape.circle,
            border: Border.all(
              color: esHoy ? AppColors.terracota : borde,
              width: esHoy ? 2.5 : 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: contenido,
        ),
      ],
    );
  }
}
