import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';

Future<bool> abrirIntencionModal(
  BuildContext context, {
  String? textoInicial,
}) async {
  HapticFeedback.lightImpact();
  final res = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _IntencionSheet(textoInicial: textoInicial),
  );
  return res == true;
}

class _IntencionSheet extends StatefulWidget {
  final String? textoInicial;
  const _IntencionSheet({this.textoInicial});

  @override
  State<_IntencionSheet> createState() => _IntencionSheetState();
}

class _IntencionSheetState extends State<_IntencionSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _ctrl;
  bool _guardando = false;
  bool _guardado = false;
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkScale;

  static const int maxCaracteres = 80;

  static const List<String> sugerencias = [
    'Llamar a alguien que extraño',
    'Caminar 15 minutos',
    'Avanzar mi proyecto 30 min',
    'Leer 10 páginas',
    'Tomar 2L de agua',
    'Decirle algo lindo a alguien',
    'Salir un rato del celular',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.textoInicial ?? '');
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkScale = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty || _guardando) return;
    setState(() => _guardando = true);
    HapticFeedback.mediumImpact();

    await StorageService.guardarIntencionHoy(texto);

    if (!mounted) return;
    setState(() {
      _guardando = false;
      _guardado = true;
    });
    _checkCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    final esDark = Theme.of(context).brightness == Brightness.dark;
    final mq = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.85),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: esDark
                ? [AppColors.fondoClaroDark, AppColors.fondoDark]
                : [AppColors.cremaTarjeta, AppColors.fondoClaro],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: _guardado ? _confirmacion(tonos) : _formulario(tonos),
          ),
        ),
      ),
    );
  }

  Widget _formulario(Tonos tonos) {
    final usados = _ctrl.text.length;
    final puedeGuardar = usados > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: tonos.textoSuave.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tu intención del día',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: tonos.textoOscuro,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '¿Cuál es UNA cosa que querés lograr hoy? Solo una.',
          style: GoogleFonts.nunito(
            fontSize: 14,
            height: 1.4,
            color: tonos.textoSuave,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _ctrl,
          autofocus: true,
          maxLength: maxCaracteres,
          maxLines: 2,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.nunito(
            fontSize: 17,
            height: 1.4,
            color: tonos.textoOscuro,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Hoy quiero...',
            hintStyle: GoogleFonts.nunito(
              color: tonos.textoSuave.withValues(alpha: 0.55),
            ),
            filled: true,
            fillColor: tonos.fondo.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: tonos.textoSuave.withValues(alpha: 0.15),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: tonos.textoSuave.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.terracota,
                width: 1.5,
              ),
            ),
            counterText: '',
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '$usados / $maxCaracteres',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: usados >= maxCaracteres
                    ? AppColors.terracota
                    : tonos.textoSuave,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Algunas ideas:',
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: tonos.textoSuave,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sugerencias.map((s) => _chipSugerencia(s, tonos)).toList(),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: puedeGuardar && !_guardando ? _guardar : null,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_guardando ? 'Guardando...' : 'Confirmar intención'),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Mejor después →',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tonos.textoSuave,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chipSugerencia(String texto, Tonos tonos) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _ctrl.text = texto;
          _ctrl.selection = TextSelection.fromPosition(
            TextPosition(offset: texto.length),
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.naranjaSuave.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.naranjaSuave.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          texto,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: tonos.textoOscuro,
          ),
        ),
      ),
    );
  }

  Widget _confirmacion(Tonos tonos) {
    return SizedBox(
      height: 280,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _checkScale,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.naranjaSuave.withValues(alpha: 0.3),
                      AppColors.naranjaSuave.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.terracota,
                  ),
                  child: const Icon(
                    Icons.flag_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Hoy vas con foco',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: tonos.textoOscuro,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Te la vamos a recordar todo el día',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: tonos.textoSuave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
