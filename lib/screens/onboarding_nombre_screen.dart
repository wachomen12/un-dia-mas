import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_categoria_screen.dart';

class OnboardingNombreScreen extends StatefulWidget {
  const OnboardingNombreScreen({super.key});

  @override
  State<OnboardingNombreScreen> createState() => _OnboardingNombreScreenState();
}

class _OnboardingNombreScreenState extends State<OnboardingNombreScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final nombre = _ctrl.text.trim();
    if (nombre.isEmpty) return;
    await StorageService.guardarNombre(nombre);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const OnboardingCategoriaScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Text(
                'Hola 🌅',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: tonos.textoOscuro,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '¿Cómo te llamas?\nVoy a saludarte por tu nombre cada día.',
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  height: 1.4,
                  color: tonos.textoSuave,
                ),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _continuar(),
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: tonos.textoOscuro,
                ),
                decoration: InputDecoration(
                  hintText: 'Tu nombre',
                  hintStyle: GoogleFonts.nunito(
                    color: tonos.textoSuave.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: tonos.cremaTarjeta,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: AppColors.naranjaSuave.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: AppColors.terracota,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _ctrl,
                builder: (_, value, __) => ElevatedButton(
                  onPressed: value.text.trim().isEmpty ? null : _continuar,
                  child: const Text('Continuar'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
