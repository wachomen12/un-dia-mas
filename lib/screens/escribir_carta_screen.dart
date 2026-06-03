import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

enum _CuandoEntrega {
  un_mes(30, 'En 1 mes'),
  tres_meses(90, '3 meses'),
  seis_meses(180, '6 meses'),
  un_anio(365, '1 año');

  final int dias;
  final String etiqueta;
  const _CuandoEntrega(this.dias, this.etiqueta);
}

class EscribirCartaScreen extends StatefulWidget {
  const EscribirCartaScreen({super.key});

  @override
  State<EscribirCartaScreen> createState() => _EscribirCartaScreenState();
}

class _EscribirCartaScreenState extends State<EscribirCartaScreen> {
  final _ctrl = TextEditingController();
  _CuandoEntrega _opcionSel = _CuandoEntrega.seis_meses;
  DateTime? _fechaPersonalizada;
  bool _guardando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  DateTime _fechaEntrega() {
    if (_fechaPersonalizada != null) return _fechaPersonalizada!;
    return DateTime.now().add(Duration(days: _opcionSel.dias));
  }

  Future<void> _elegirFechaPersonalizada() async {
    final hoy = DateTime.now();
    final res = await showDatePicker(
      context: context,
      initialDate: hoy.add(const Duration(days: 30)),
      firstDate: hoy.add(const Duration(days: 7)),
      lastDate: hoy.add(const Duration(days: 365 * 10)),
      locale: const Locale('es'),
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
    if (res != null) {
      setState(() => _fechaPersonalizada = res);
    }
  }

  Future<void> _guardar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty || _guardando) return;
    setState(() => _guardando = true);

    final fecha = _fechaEntrega();
    final carta = await StorageService.guardarCarta(
      contenido: texto,
      fechaEntrega: fecha,
    );

    final entregaA10am = DateTime(fecha.year, fecha.month, fecha.day, 10);
    await NotificationService.programarEntregaCarta(
      idCarta: carta.id,
      cuando: entregaA10am,
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    final fechaTexto = DateFormat.yMMMMd('es').format(_fechaEntrega());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carta a tu yo futuro'),
        actions: [
          TextButton(
            onPressed: _guardando ? null : _guardar,
            child: Text(
              _guardando ? '...' : 'Enviar',
              style: GoogleFonts.nunito(
                color: AppColors.terracota,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Te llegará el',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: tonos.textoSuave,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                fechaTexto,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.terracota,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._CuandoEntrega.values.map((c) => _chip(c, tonos)),
                  _chipPersonalizado(tonos),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    height: 1.5,
                    color: tonos.textoOscuro,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Querido yo del futuro,\n\n¿Qué quieres que recuerdes de hoy? ¿Qué consejos te quieres dar? ¿Qué soñabas al escribir esto?\n\n...',
                    hintStyle: GoogleFonts.nunito(
                      color: tonos.textoSuave.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    filled: true,
                    fillColor: tonos.cremaTarjeta,
                    contentPadding: const EdgeInsets.all(18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(_CuandoEntrega c, Tonos tonos) {
    final sel = _fechaPersonalizada == null && _opcionSel == c;
    return GestureDetector(
      onTap: () => setState(() {
        _opcionSel = c;
        _fechaPersonalizada = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.terracota : tonos.cremaTarjeta,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel
                ? AppColors.terracota
                : AppColors.naranjaSuave.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          c.etiqueta,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: sel ? Colors.white : tonos.textoOscuro,
          ),
        ),
      ),
    );
  }

  Widget _chipPersonalizado(Tonos tonos) {
    final sel = _fechaPersonalizada != null;
    return GestureDetector(
      onTap: _elegirFechaPersonalizada,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.terracota : tonos.cremaTarjeta,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel
                ? AppColors.terracota
                : AppColors.naranjaSuave.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event,
              size: 14,
              color: sel ? Colors.white : AppColors.terracota,
            ),
            const SizedBox(width: 6),
            Text(
              sel ? 'Fecha personalizada' : 'Otra fecha',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: sel ? Colors.white : AppColors.textoOscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
