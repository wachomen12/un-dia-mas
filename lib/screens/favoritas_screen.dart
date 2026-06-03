import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class FavoritasScreen extends StatefulWidget {
  const FavoritasScreen({super.key});

  @override
  State<FavoritasScreen> createState() => _FavoritasScreenState();
}

class _FavoritasScreenState extends State<FavoritasScreen> {
  List<String> _favoritas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final f = await StorageService.obtenerFavoritas();
    if (!mounted) return;
    setState(() {
      _favoritas = f;
      _cargando = false;
    });
  }

  Future<void> _quitar(String frase) async {
    await StorageService.alternarFavorita(frase);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis favoritas')),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _favoritas.isEmpty
                ? _vacio(tonos)
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _favoritas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _tarjeta(_favoritas[i], tonos),
                  ),
      ),
    );
  }

  Widget _vacio(Tonos tonos) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🤍', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Aún no guardas favoritas',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tonos.textoOscuro,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando una frase te llegue, toca el corazón\npara guardarla y volver a leerla aquí.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                height: 1.4,
                color: tonos.textoSuave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjeta(String frase, Tonos tonos) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tonos.cremaTarjeta,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            frase,
            style: GoogleFonts.nunito(
              fontSize: 16,
              height: 1.5,
              color: tonos.textoOscuro,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.favorite, color: AppColors.terracota),
              onPressed: () => _quitar(frase),
              tooltip: 'Quitar de favoritas',
            ),
          ),
        ],
      ),
    );
  }
}
