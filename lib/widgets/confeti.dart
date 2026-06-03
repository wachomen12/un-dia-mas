import 'dart:math';

import 'package:flutter/material.dart';

class Confeti extends StatefulWidget {
  final int duracionMs;
  final int particulas;
  final List<Color> colores;

  const Confeti({
    super.key,
    this.duracionMs = 2400,
    this.particulas = 60,
    this.colores = const [
      Color(0xFFE89B6A),
      Color(0xFFD27D55),
      Color(0xFFFFDABE),
      Color(0xFF8FAA80),
      Color(0xFFFFC9A4),
    ],
  });

  @override
  State<Confeti> createState() => _ConfetiState();
}

class _ConfetiState extends State<Confeti> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particula> _ps;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _ps = List.generate(widget.particulas, (_) => _Particula.random(rng, widget.colores));
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duracionMs),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _ConfetiPainter(_ps, _ctrl.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particula {
  final double xInicio;
  final double yInicio;
  final double xFinal;
  final double yFinal;
  final double rotacionInicio;
  final double rotacionFinal;
  final double tamano;
  final Color color;

  _Particula({
    required this.xInicio,
    required this.yInicio,
    required this.xFinal,
    required this.yFinal,
    required this.rotacionInicio,
    required this.rotacionFinal,
    required this.tamano,
    required this.color,
  });

  factory _Particula.random(Random rng, List<Color> colores) {
    final xI = 0.3 + rng.nextDouble() * 0.4;
    final yI = -0.05 + rng.nextDouble() * 0.1;
    final xF = rng.nextDouble();
    final yF = 0.85 + rng.nextDouble() * 0.2;
    return _Particula(
      xInicio: xI,
      yInicio: yI,
      xFinal: xF,
      yFinal: yF,
      rotacionInicio: rng.nextDouble() * 2 * pi,
      rotacionFinal: rng.nextDouble() * 6 * pi - 3 * pi,
      tamano: 6 + rng.nextDouble() * 8,
      color: colores[rng.nextInt(colores.length)],
    );
  }
}

class _ConfetiPainter extends CustomPainter {
  final List<_Particula> ps;
  final double t;

  _ConfetiPainter(this.ps, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final fade = (1 - (t - 0.7).clamp(0.0, 0.3) / 0.3).clamp(0.0, 1.0);
    for (final p in ps) {
      final easeT = Curves.easeOut.transform(t);
      final x = p.xInicio + (p.xFinal - p.xInicio) * easeT;
      final y = p.yInicio + (p.yFinal - p.yInicio) * easeT;
      final r = p.rotacionInicio + (p.rotacionFinal - p.rotacionInicio) * easeT;

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(r);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.tamano,
          height: p.tamano * 0.5,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfetiPainter old) => old.t != t;
}
