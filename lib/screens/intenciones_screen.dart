import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/intencion.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class IntencionesScreen extends StatefulWidget {
  const IntencionesScreen({super.key});

  @override
  State<IntencionesScreen> createState() => _IntencionesScreenState();
}

class _IntencionesScreenState extends State<IntencionesScreen> {
  List<Intencion> _lista = [];
  EstadisticasIntenciones? _stats;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await StorageService.obtenerIntenciones();
    final stats = await StorageService.obtenerStatsIntenciones();
    if (!mounted) return;
    setState(() {
      _lista = lista;
      _stats = stats;
      _cargando = false;
    });
  }

  String _fecha(String iso) {
    try {
      final partes = iso.split('-');
      final d = DateTime(
        int.parse(partes[0]),
        int.parse(partes[1]),
        int.parse(partes[2]),
      );
      return DateFormat.yMMMMd('es').format(d);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.terracota)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Mis intenciones')),
      body: SafeArea(
        child: _lista.isEmpty
            ? _vacio(tonos)
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  _resumen(tonos),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'Tu historial',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: tonos.textoSuave,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  ..._lista.map((i) => _tarjeta(i, tonos)),
                ],
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
            const Text('🎯', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Aún no tenés intenciones',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: tonos.textoOscuro,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando definás tu primera intención\ndel día, va a aparecer acá.',
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

  Widget _resumen(Tonos tonos) {
    final s = _stats!;
    final exito = (s.porcentajeExito * 100).toInt();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.naranjaSuave.withValues(alpha: 0.22),
            AppColors.terracota.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _stat('${s.total}', 'totales', tonos),
              _separador(tonos),
              _stat('${s.cumplidas}', 'cumplidas', tonos),
              _separador(tonos),
              _stat('$exito%', 'de éxito', tonos),
            ],
          ),
          if (s.rachaIntencionesCumplidas > 1) ...[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '${s.rachaIntencionesCumplidas} cumplidas seguidas',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.terracota,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _separador(Tonos tonos) => Container(
        width: 1,
        height: 36,
        color: tonos.textoSuave.withValues(alpha: 0.2),
      );

  Widget _stat(String valor, String etiqueta, Tonos tonos) {
    return Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.terracota,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tonos.textoSuave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Intencion i, Tonos tonos) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tonos.cremaTarjeta,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i.resultado == ResultadoIntencion.cumplida
                    ? AppColors.terracota.withValues(alpha: 0.18)
                    : tonos.fondo.withValues(alpha: 0.5),
              ),
              alignment: Alignment.center,
              child: Text(
                i.resultado.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fecha(i.fecha),
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.terracota,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    i.texto,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      height: 1.4,
                      color: tonos.textoOscuro,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (i.resultado != ResultadoIntencion.pendiente) ...[
                    const SizedBox(height: 4),
                    Text(
                      i.resultado.etiqueta,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tonos.textoSuave,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
