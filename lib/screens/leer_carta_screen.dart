import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/carta.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class LeerCartaScreen extends StatefulWidget {
  final Carta carta;
  const LeerCartaScreen({super.key, required this.carta});

  @override
  State<LeerCartaScreen> createState() => _LeerCartaScreenState();
}

class _LeerCartaScreenState extends State<LeerCartaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    if (!widget.carta.leida) {
      StorageService.marcarCartaLeida(widget.carta.id);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _contexto() {
    final dias = widget.carta.diasDesdeEscritura;
    if (dias < 1) return 'La escribiste hace un momento';
    if (dias < 7) return 'La escribiste hace $dias ${dias == 1 ? "día" : "días"}';
    if (dias < 30) {
      final semanas = (dias / 7).round();
      return 'La escribiste hace $semanas ${semanas == 1 ? "semana" : "semanas"}';
    }
    if (dias < 365) {
      final meses = (dias / 30).round();
      return 'La escribiste hace $meses ${meses == 1 ? "mes" : "meses"}';
    }
    final anios = (dias / 365).round();
    return 'La escribiste hace $anios ${anios == 1 ? "año" : "años"}';
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    final fecha = DateFormat.yMMMMd('es')
        .format(DateTime.parse(widget.carta.fechaEscritura));
    return Scaffold(
      appBar: AppBar(title: const Text('Tu carta')),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    _contexto(),
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.terracota,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fecha,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: tonos.textoSuave,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    decoration: BoxDecoration(
                      color: tonos.cremaTarjeta,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.naranjaSuave.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '“',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 56,
                            height: 0.6,
                            color: AppColors.naranjaSuave,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.carta.contenido,
                          style: GoogleFonts.nunito(
                            fontSize: 17,
                            height: 1.6,
                            color: tonos.textoOscuro,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 2,
                              color: AppColors.naranjaSuave,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Tu yo de antes',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                color: AppColors.terracota,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
