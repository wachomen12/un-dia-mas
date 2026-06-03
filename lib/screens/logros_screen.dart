import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/logros.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class LogrosScreen extends StatefulWidget {
  const LogrosScreen({super.key});

  @override
  State<LogrosScreen> createState() => _LogrosScreenState();
}

class _LogrosScreenState extends State<LogrosScreen> {
  Set<String> _desbloqueados = {};
  int _racha = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final d = await StorageService.obtenerLogros();
    final r = await StorageService.obtenerRachaActual();
    if (!mounted) return;
    setState(() {
      _desbloqueados = d;
      _racha = r;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final total = Logros.todos.length;
    final ganados = _desbloqueados.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis logros')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.naranjaSuave.withValues(alpha: 0.25),
                      AppColors.terracota.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🏆', style: TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$ganados de $total medallas',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: tonos.textoOscuro,
                            ),
                          ),
                          Text(
                            'Llevas $_racha ${_racha == 1 ? "día" : "días"} sin rendirte',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: tonos.textoSuave,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: Logros.todos
                    .map((l) => _tarjetaLogro(
                          l,
                          _desbloqueados.contains(l.id),
                          tonos,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaLogro(Logro l, bool ganado, Tonos tonos) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ganado
            ? tonos.cremaTarjeta
            : tonos.cremaTarjeta.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ganado
              ? AppColors.terracota.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.2),
          width: ganado ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ganado
                  ? RadialGradient(
                      colors: [
                        AppColors.naranjaSuave.withValues(alpha: 0.3),
                        AppColors.naranjaSuave.withValues(alpha: 0.0),
                      ],
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: ganado ? 1.0 : 0.25,
              child: Text(
                ganado ? l.emoji : '🔒',
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.titulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: ganado ? tonos.textoOscuro : tonos.textoSuave,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ganado
                ? l.descripcion
                : '${l.diasNecesarios} ${l.diasNecesarios == 1 ? "día" : "días"}',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: tonos.textoSuave,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
