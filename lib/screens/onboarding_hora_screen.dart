import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/categoria.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class OnboardingHoraScreen extends StatefulWidget {
  final Categoria categoria;
  const OnboardingHoraScreen({super.key, required this.categoria});

  @override
  State<OnboardingHoraScreen> createState() => _OnboardingHoraScreenState();
}

class _OnboardingHoraScreenState extends State<OnboardingHoraScreen> {
  TimeOfDay _hora = const TimeOfDay(hour: 8, minute: 0);
  bool _trabajando = false;

  Future<void> _elegirHora() async {
    final res = await showTimePicker(
      context: context,
      initialTime: _hora,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.terracota,
            onPrimary: Colors.white,
            onSurface: AppColors.textoOscuro,
          ),
        ),
        child: child!,
      ),
    );
    if (res != null) setState(() => _hora = res);
  }

  Future<void> _terminar() async {
    setState(() => _trabajando = true);
    await StorageService.guardarCategoria(widget.categoria);
    await StorageService.guardarHora(_hora.hour, _hora.minute);
    await StorageService.marcarOnboardingCompleto();

    await NotificationService.pedirPermisos();
    await NotificationService.programarDiaria(
      hora: _hora.hour,
      minuto: _hora.minute,
      categoria: widget.categoria,
    );

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    final horaTexto = _hora.format(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                '¿A qué hora quieres tu mensaje?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: tonos.textoOscuro,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Te enviaré una frase cada día a esta hora.\nPuedes cambiarla cuando quieras.',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  height: 1.4,
                  color: tonos.textoSuave,
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _elegirHora,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  decoration: BoxDecoration(
                    color: tonos.cremaTarjeta,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.naranjaSuave.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.alarm,
                          size: 48, color: AppColors.terracota),
                      const SizedBox(height: 12),
                      Text(
                        horaTexto,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: tonos.textoOscuro,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Toca para cambiar',
                        style: GoogleFonts.nunito(
                          color: tonos.textoSuave,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _trabajando ? null : _terminar,
                child: _trabajando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Empezar'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
