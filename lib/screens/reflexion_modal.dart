import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/categoria.dart';
import '../models/mood.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mood_selector.dart';

Future<bool> abrirReflexionModal(
  BuildContext context, {
  required String frase,
  required Categoria categoria,
}) async {
  HapticFeedback.lightImpact();
  final res = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _ReflexionSheet(frase: frase, categoria: categoria),
  );
  return res == true;
}

class _ReflexionSheet extends StatefulWidget {
  final String frase;
  final Categoria categoria;
  const _ReflexionSheet({required this.frase, required this.categoria});

  @override
  State<_ReflexionSheet> createState() => _ReflexionSheetState();
}

class _ReflexionSheetState extends State<_ReflexionSheet>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  Mood? _mood;
  bool _guardando = false;
  bool _guardado = false;

  late final AnimationController _checkCtrl;
  late final Animation<double> _checkScale;

  static const int maxCaracteres = 150;

  @override
  void initState() {
    super.initState();
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

    await StorageService.guardarReflexion(
      frase: widget.frase,
      categoriaId: widget.categoria.id,
      moodId: _mood?.id,
      texto: texto,
    );

    if (!mounted) return;
    setState(() {
      _guardando = false;
      _guardado = true;
    });
    _checkCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
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
        constraints: BoxConstraints(
          maxHeight: mq.size.height * 0.9,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: esDark
                ? [
                    AppColors.fondoClaroDark,
                    AppColors.fondoDark,
                  ]
                : [
                    AppColors.cremaTarjeta,
                    AppColors.fondoClaro,
                  ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
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
    final caracteresUsados = _ctrl.text.length;
    final puedeGuardar = caracteresUsados > 0;
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
            const Text('💭', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¿Qué significa esta frase para ti hoy?',
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: tonos.textoOscuro,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.terracota.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.terracota.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '“',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  height: 0.7,
                  color: AppColors.naranjaSuave,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.frase,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: tonos.textoOscuro,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        MoodSelector(
          seleccionado: _mood,
          onCambio: (m) => setState(() => _mood = m),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _ctrl,
          autofocus: false,
          maxLines: 5,
          minLines: 3,
          maxLength: maxCaracteres,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.nunito(
            fontSize: 16,
            height: 1.5,
            color: tonos.textoOscuro,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText:
                'Escribe lo que sientes hoy, en breve...',
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
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '$caracteresUsados / $maxCaracteres',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: caracteresUsados >= maxCaracteres
                    ? AppColors.terracota
                    : tonos.textoSuave,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
                : const Icon(Icons.favorite_outline),
            label: Text(_guardando ? 'Guardando...' : 'Guardar reflexión'),
          ),
        ),
        const SizedBox(height: 8),
      ],
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
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Guardada en Mi Camino',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: tonos.textoOscuro,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vas a poder leerla cuando la necesites',
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
