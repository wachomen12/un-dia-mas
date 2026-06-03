import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/mood.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class MoodGraficaScreen extends StatefulWidget {
  const MoodGraficaScreen({super.key});

  @override
  State<MoodGraficaScreen> createState() => _MoodGraficaScreenState();
}

class _MoodGraficaScreenState extends State<MoodGraficaScreen> {
  List<EntradaDiario> _entradas = [];
  bool _cargando = true;
  int _diasMostrar = 30;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await StorageService.obtenerDiario();
    if (!mounted) return;
    setState(() {
      _entradas = lista.where((e) => e.mood != null).toList();
      _cargando = false;
    });
  }

  List<EntradaDiario> _filtradas() {
    final hoy = DateTime.now();
    final desde = hoy.subtract(Duration(days: _diasMostrar - 1));
    return _entradas.where((e) {
      final d = DateTime.parse(e.fecha);
      return !d.isBefore(DateTime(desde.year, desde.month, desde.day));
    }).toList();
  }

  Mood? _moodPromedio(List<EntradaDiario> lista) {
    if (lista.isEmpty) return null;
    final suma = lista.fold<int>(0, (a, b) => a + b.mood!.valor);
    final prom = (suma / lista.length).round().clamp(1, 5);
    return Mood.values.firstWhere((m) => m.valor == prom);
  }

  Map<Mood, int> _conteoMoods(List<EntradaDiario> lista) {
    final mapa = {for (final m in Mood.values) m: 0};
    for (final e in lista) {
      mapa[e.mood!] = (mapa[e.mood!] ?? 0) + 1;
    }
    return mapa;
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final filtradas = _filtradas();
    final promedio = _moodPromedio(filtradas);
    final conteo = _conteoMoods(filtradas);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi estado de ánimo')),
      body: SafeArea(
        child: filtradas.isEmpty && _entradas.isEmpty
            ? _vacio(tonos)
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _selectorDias(tonos),
                  const SizedBox(height: 20),
                  _resumen(promedio, filtradas.length, tonos),
                  const SizedBox(height: 24),
                  if (filtradas.isNotEmpty) ...[
                    _seccion('Tu mood en el tiempo', tonos),
                    const SizedBox(height: 8),
                    SizedBox(height: 240, child: _grafica(filtradas)),
                    const SizedBox(height: 32),
                    _seccion('Cómo estuviste', tonos),
                    const SizedBox(height: 12),
                    ...Mood.values.reversed.map(
                      (m) => _barraMood(m, conteo[m] ?? 0, filtradas.length, tonos),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'No hay datos en estos últimos $_diasMostrar días.\nPrueba con un rango más amplio.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(color: tonos.textoSuave),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _selectorDias(Tonos tonos) {
    final opciones = [7, 14, 30, 90];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tonos.cremaTarjeta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: opciones.map((d) {
          final sel = d == _diasMostrar;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _diasMostrar = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.terracota : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${d}d',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: sel ? Colors.white : tonos.textoSuave,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _resumen(Mood? promedio, int total, Tonos tonos) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            promedio?.emoji ?? '📊',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promedio == null
                      ? 'Sin registros aún'
                      : 'En promedio: ${promedio.nombre.toLowerCase()}',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: tonos.textoOscuro,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$total ${total == 1 ? "día registrado" : "días registrados"}',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: tonos.textoSuave,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccion(String titulo, Tonos tonos) => Text(
        titulo,
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: tonos.textoSuave,
          letterSpacing: 0.4,
        ),
      );

  Widget _grafica(List<EntradaDiario> entradas) {
    entradas.sort((a, b) => a.fecha.compareTo(b.fecha));
    final spots = <FlSpot>[];
    for (var i = 0; i < entradas.length; i++) {
      spots.add(FlSpot(i.toDouble(), entradas[i].mood!.valor.toDouble()));
    }

    return LineChart(
      LineChartData(
        minY: 0.5,
        maxY: 5.5,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 1,
              getTitlesWidget: (value, _) {
                final v = value.toInt();
                if (v < 1 || v > 5) return const SizedBox.shrink();
                final m = Mood.values.firstWhere((mm) => mm.valor == v);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(m.emoji, style: const TextStyle(fontSize: 18)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.32,
            color: AppColors.terracota,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                radius: 5,
                color: AppColors.terracota,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.terracota.withValues(alpha: 0.25),
                  AppColors.terracota.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barraMood(Mood m, int cuantos, int total, Tonos tonos) {
    final fraccion = total == 0 ? 0.0 : cuantos / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(m.emoji, style: const TextStyle(fontSize: 22)),
          ),
          SizedBox(
            width: 70,
            child: Text(
              m.nombre,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tonos.textoOscuro,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fraccion,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.naranjaSuave, AppColors.terracota],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              '$cuantos',
              textAlign: TextAlign.right,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: tonos.textoSuave,
              ),
            ),
          ),
        ],
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
            const Text('📊', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Aún no hay datos',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tonos.textoOscuro,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando escribas en tu diario y elijas\ncómo te sentiste, vas a ver tu mood aquí.',
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
}
