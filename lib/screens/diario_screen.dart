import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/mood.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mood_selector.dart';
import 'mood_grafica_screen.dart';

class DiarioScreen extends StatefulWidget {
  const DiarioScreen({super.key});

  @override
  State<DiarioScreen> createState() => _DiarioScreenState();
}

class _DiarioScreenState extends State<DiarioScreen> {
  List<EntradaDiario> _entradas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await StorageService.obtenerDiario();
    if (!mounted) return;
    setState(() {
      _entradas = lista;
      _cargando = false;
    });
  }

  Future<void> _editarHoy() async {
    final hoy = await StorageService.entradaDiarioHoy();
    if (!mounted) return;
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DiarioEditorScreen(
          textoInicial: hoy?.texto ?? '',
          moodInicial: hoy?.mood,
        ),
      ),
    );
    if (res == true) _cargar();
  }

  Future<void> _borrar(String fecha) async {
    await StorageService.borrarEntradaDiario(fecha);
    _cargar();
  }

  String _formatearFecha(String fechaIso) {
    try {
      final partes = fechaIso.split('-');
      final d = DateTime(
        int.parse(partes[0]),
        int.parse(partes[1]),
        int.parse(partes[2]),
      );
      return DateFormat.yMMMMd('es').format(d);
    } catch (_) {
      return fechaIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi diario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'Gráfica de mood',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MoodGraficaScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _entradas.isEmpty
                ? _vacio(tonos)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
                    itemCount: _entradas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _tarjeta(_entradas[i], tonos),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _editarHoy,
        backgroundColor: AppColors.terracota,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Escribir de hoy'),
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
            const Text('🌱', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Tu diario está esperando',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tonos.textoOscuro,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cada día puedes escribir una línea\ny elegir cómo te sentiste.\nMañana lo vas a agradecer.',
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

  Widget _tarjeta(EntradaDiario e, Tonos tonos) {
    return Dismissible(
      key: ValueKey(e.fecha),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.terracota.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _borrar(e.fecha),
      child: Container(
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
                Expanded(
                  child: Text(
                    _formatearFecha(e.fecha),
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.terracota,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (e.mood != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.terracota.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.mood!.emoji,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          e.mood!.nombre,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.terracota,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              e.texto,
              style: GoogleFonts.nunito(
                fontSize: 16,
                height: 1.5,
                color: tonos.textoOscuro,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiarioEditorScreen extends StatefulWidget {
  final String textoInicial;
  final Mood? moodInicial;
  const DiarioEditorScreen({
    super.key,
    required this.textoInicial,
    this.moodInicial,
  });

  @override
  State<DiarioEditorScreen> createState() => _DiarioEditorScreenState();
}

class _DiarioEditorScreenState extends State<DiarioEditorScreen> {
  late final TextEditingController _ctrl;
  Mood? _mood;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.textoInicial);
    _mood = widget.moodInicial;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty && _mood == null) {
      Navigator.of(context).pop(false);
      return;
    }
    await StorageService.guardarEntradaDiario(t, mood: _mood);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cómo estuvo tu día'),
        actions: [
          TextButton(
            onPressed: _guardar,
            child: Text(
              'Guardar',
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoodSelector(
                seleccionado: _mood,
                onCambio: (m) => setState(() => _mood = m),
              ),
              const SizedBox(height: 18),
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
                        'Escribe una línea, un párrafo o lo que necesites soltar...',
                    hintStyle: GoogleFonts.nunito(
                      color: tonos.textoSuave.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
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
            ],
          ),
        ),
      ),
    );
  }
}
