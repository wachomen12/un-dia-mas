import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/categoria.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_hora_screen.dart';

class OnboardingCategoriaScreen extends StatefulWidget {
  const OnboardingCategoriaScreen({super.key});

  @override
  State<OnboardingCategoriaScreen> createState() =>
      _OnboardingCategoriaScreenState();
}

class _OnboardingCategoriaScreenState extends State<OnboardingCategoriaScreen> {
  Categoria? _seleccionada;
  String _nombre = '';

  @override
  void initState() {
    super.initState();
    StorageService.obtenerNombre().then((n) {
      if (mounted) setState(() => _nombre = n);
    });
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
              const SizedBox(height: 32),
              Text(
                _nombre.isEmpty ? 'Bienvenido 🌅' : 'Hola, $_nombre 🌅',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: tonos.textoOscuro,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '¿Qué estás viviendo ahora?\nVoy a acompañarte un día a la vez.',
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  height: 1.4,
                  color: tonos.textoSuave,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: Categoria.values
                      .map((c) => _tarjeta(c, c == _seleccionada, tonos))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _seleccionada == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OnboardingHoraScreen(
                              categoria: _seleccionada!,
                            ),
                          ),
                        );
                      },
                child: const Text('Continuar'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjeta(Categoria c, bool sel, Tonos tonos) {
    return GestureDetector(
      onTap: () => setState(() => _seleccionada = c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: sel ? AppColors.terracota : tonos.cremaTarjeta,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel
                ? AppColors.terracota
                : AppColors.naranjaSuave.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(c.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                c.nombre,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : tonos.textoOscuro,
                ),
              ),
            ),
            Icon(
              sel ? Icons.check_circle : Icons.circle_outlined,
              color: sel ? Colors.white : AppColors.naranjaSuave,
            ),
          ],
        ),
      ),
    );
  }
}
