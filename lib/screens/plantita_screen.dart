import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/plantitas.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class PlantitaScreen extends StatefulWidget {
  const PlantitaScreen({super.key});

  @override
  State<PlantitaScreen> createState() => _PlantitaScreenState();
}

class _PlantitaScreenState extends State<PlantitaScreen>
    with SingleTickerProviderStateMixin {
  String _nombre = 'Mi plantita';
  int _dias = 0;
  int _racha = 0;
  bool _cargando = true;

  late final AnimationController _pulse;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    _cargar();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final nombre = await StorageService.obtenerNombrePlantita();
    final stats = await StorageService.obtenerEstadisticas();
    if (!mounted) return;
    setState(() {
      _nombre = nombre;
      _dias = stats.totalDias;
      _racha = stats.rachaActual;
      _cargando = false;
    });
  }

  Future<void> _renombrar() async {
    HapticFeedback.lightImpact();
    final ctrl = TextEditingController(text: _nombre);
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cómo se llama?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Mi plantita, Pepa, Maceta...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (res != null && res.isNotEmpty) {
      await StorageService.guardarNombrePlantita(res);
      setState(() => _nombre = res);
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
    final etapa = Plantitas.actual(_dias);
    final siguienteEtapa = Plantitas.siguiente(_dias);
    final progreso = Plantitas.progresoAlSiguiente(_dias);
    final viva = _racha > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _nombre,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Renombrar',
            onPressed: _renombrar,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _emojiGrande(etapa, viva),
              const SizedBox(height: 10),
              Text(
                etapa.nombre,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: tonos.textoOscuro,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  etapa.descripcion,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    height: 1.4,
                    color: tonos.textoSuave,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _bloqueProgreso(etapa, siguienteEtapa, progreso, tonos),
              const SizedBox(height: 20),
              _mensajeEstado(viva, tonos),
              const SizedBox(height: 28),
              Row(
                children: [
                  _statTarjeta('$_dias', _dias == 1 ? 'día contigo' : 'días contigo', tonos),
                  const SizedBox(width: 12),
                  _statTarjeta('${etapa.nivel + 1}/${Plantitas.etapas.length}', 'etapa', tonos),
                ],
              ),
              const SizedBox(height: 28),
              _mapaEtapas(etapa, tonos),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emojiGrande(EtapaPlantita etapa, bool viva) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: viva
              ? [
                  AppColors.naranjaSuave.withValues(alpha: 0.35),
                  AppColors.naranjaSuave.withValues(alpha: 0.0),
                ]
              : [
                  Colors.grey.withValues(alpha: 0.2),
                  Colors.grey.withValues(alpha: 0.0),
                ],
        ),
      ),
      alignment: Alignment.center,
      child: ScaleTransition(
        scale: _pulseScale,
        child: Opacity(
          opacity: viva ? 1.0 : 0.5,
          child: Text(
            etapa.emoji,
            style: const TextStyle(fontSize: 120),
          ),
        ),
      ),
    );
  }

  Widget _bloqueProgreso(
    EtapaPlantita etapa,
    EtapaPlantita? siguienteEtapa,
    double progreso,
    Tonos tonos,
  ) {
    if (siguienteEtapa == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: tonos.cremaTarjeta,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              'Llegaste al máximo. Tu plantita ya es un bosque entero.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                height: 1.4,
                color: tonos.textoOscuro,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    final diasFaltantes = siguienteEtapa.diasMinimos - _dias;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tonos.cremaTarjeta,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Próximo nivel: ',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tonos.textoSuave,
                  )),
              Text(siguienteEtapa.emoji,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(siguienteEtapa.nombre,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.terracota,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 10,
              backgroundColor: Colors.grey.withValues(alpha: 0.18),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.terracota),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            diasFaltantes == 1
                ? 'Te falta 1 día más'
                : 'Te faltan $diasFaltantes días más',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: tonos.textoSuave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mensajeEstado(bool viva, Tonos tonos) {
    final texto = viva
        ? 'Tu plantita está feliz. Sigue regándola con tu constancia.'
        : 'Tu plantita te está esperando. Volvé cuando quieras, sin culpa.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.naranjaSuave.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(viva ? '💚' : '💛', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.nunito(
                fontSize: 14,
                height: 1.4,
                color: tonos.textoOscuro,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTarjeta(String valor, String etiqueta, Tonos tonos) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: tonos.cremaTarjeta,
          borderRadius: BorderRadius.circular(18),
        ),
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
      ),
    );
  }

  Widget _mapaEtapas(EtapaPlantita actual, Tonos tonos) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tonos.cremaTarjeta,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu camino',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: tonos.textoSuave,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          ...Plantitas.etapas.map((e) {
            final desbloqueada = _dias >= e.diasMinimos;
            final esActual = e.nivel == actual.nivel;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Opacity(
                    opacity: desbloqueada ? 1.0 : 0.35,
                    child: Text(
                      e.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.nombre,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: esActual
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: desbloqueada
                            ? (esActual
                                ? AppColors.terracota
                                : tonos.textoOscuro)
                            : tonos.textoSuave.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Text(
                    'Día ${e.diasMinimos}',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: tonos.textoSuave,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
