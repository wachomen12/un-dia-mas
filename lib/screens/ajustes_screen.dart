import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/frases.dart';
import '../models/categoria.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import 'cartas_screen.dart';
import 'diario_screen.dart';
import 'favoritas_screen.dart';
import 'logros_screen.dart';
import 'mi_camino_screen.dart';
import 'mood_grafica_screen.dart';
import 'plantita_screen.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  Categoria _categoria = Categoria.momentoDificil;
  TimeOfDay _hora = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaNoche = const TimeOfDay(hour: 21, minute: 0);
  bool _noche = false;
  String _nombre = '';
  bool _cargado = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final cat = await StorageService.obtenerCategoria();
    final h = await StorageService.obtenerHora();
    final hn = await StorageService.obtenerHoraNoche();
    final na = await StorageService.notifNocheActiva();
    final nom = await StorageService.obtenerNombre();
    if (!mounted) return;
    setState(() {
      _categoria = cat;
      _hora = TimeOfDay(hour: h.hora, minute: h.minuto);
      _horaNoche = TimeOfDay(hour: hn.hora, minute: hn.minuto);
      _noche = na;
      _nombre = nom;
      _cargado = true;
    });
  }

  Future<void> _cambiarHora() async {
    final res = await showTimePicker(context: context, initialTime: _hora);
    if (res != null) {
      setState(() => _hora = res);
      await StorageService.guardarHora(res.hour, res.minute);
      await NotificationService.programarDiaria(
        hora: res.hour,
        minuto: res.minute,
        categoria: _categoria,
      );
      if (!mounted) return;
      _toast('Hora actualizada a ${res.format(context)}');
    }
  }

  Future<void> _cambiarHoraNoche() async {
    final res = await showTimePicker(context: context, initialTime: _horaNoche);
    if (res != null) {
      setState(() => _horaNoche = res);
      await StorageService.guardarHoraNoche(res.hour, res.minute);
      if (_noche) {
        await NotificationService.programarNoche(
          hora: res.hour,
          minuto: res.minute,
        );
      }
      if (!mounted) return;
      _toast('Hora de la noche: ${res.format(context)}');
    }
  }

  Future<void> _toggleNoche(bool valor) async {
    setState(() => _noche = valor);
    await StorageService.guardarNotifNocheActiva(valor);
    if (valor) {
      await NotificationService.programarNoche(
        hora: _horaNoche.hour,
        minuto: _horaNoche.minute,
      );
      _toast('Notificación de la noche activada');
    } else {
      await NotificationService.cancelarNoche();
      _toast('Notificación de la noche desactivada');
    }
  }

  Future<void> _cambiarCategoria(Categoria c) async {
    setState(() => _categoria = c);
    await StorageService.guardarCategoria(c);
    await NotificationService.programarDiaria(
      hora: _hora.hour,
      minuto: _hora.minute,
      categoria: c,
    );
    await WidgetService.actualizarConDatos();
    _toast('Categoría: ${c.nombre}');
  }

  Future<void> _probarNotificacion() async {
    final ok = await NotificationService.permisosOtorgados();
    if (!ok) {
      await NotificationService.pedirPermisos();
    }
    final frase = Frases.delDia(_categoria, DateTime.now());
    await NotificationService.enviarPrueba(frase);
    if (!mounted) return;
    _toast('Notificación enviada 🔔');
  }

  Future<void> _probarEn30Seg() async {
    final ok = await NotificationService.permisosOtorgados();
    if (!ok) {
      await NotificationService.pedirPermisos();
    }
    final frase = Frases.delDia(_categoria, DateTime.now());
    await NotificationService.programarPruebaEn(30, frase);
    if (!mounted) return;
    _toast('Programada para llegar en 30 seg. Cierra la app y espera 🕒');
  }

  Future<void> _diagnosticar() async {
    final notif = await NotificationService.permisosOtorgados();
    final exactas = await NotificationService.alarmasExactasOtorgadas();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Diagnóstico de notificaciones'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _filaDiagnostico(
              'Permiso de notificaciones',
              notif,
            ),
            const SizedBox(height: 12),
            _filaDiagnostico(
              'Alarmas exactas',
              exactas,
            ),
            const SizedBox(height: 16),
            const Text(
              'Si alguna está roja, toca el botón "Pedir permisos" abajo.\n\nSi ambas están verdes pero la notificación no llega: tu celular está matando la app por ahorro de batería. Ve a Ajustes → Apps → Un Día Más → Batería → "Sin restricciones".',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await NotificationService.pedirPermisos();
              if (mounted) _toast('Permisos solicitados');
            },
            child: const Text('Pedir permisos'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _filaDiagnostico(String etiqueta, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.cancel,
          color: ok ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            etiqueta,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          ok ? 'OK' : 'Falta',
          style: TextStyle(
            color: ok ? Colors.green : Colors.red,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Future<void> _editarNombre() async {
    final ctrl = TextEditingController(text: _nombre);
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cómo te llamas?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Tu nombre'),
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
      await StorageService.guardarNombre(res);
      setState(() => _nombre = res);
      await WidgetService.actualizarConDatos();
      _toast('Hola, $res 🌅');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    if (!_cargado) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            _seccion('Perfil', tonos),
            _tarjeta(
              tonos,
              child: ListTile(
                onTap: _editarNombre,
                leading: const Icon(Icons.person_outline,
                    color: AppColors.terracota),
                title: Text(
                  _nombre.isEmpty ? 'Sin nombre' : _nombre,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: tonos.textoOscuro,
                  ),
                ),
                subtitle: Text(
                  'Toca para cambiar',
                  style: GoogleFonts.nunito(color: tonos.textoSuave),
                ),
                trailing: Icon(Icons.chevron_right, color: tonos.textoSuave),
              ),
            ),
            const SizedBox(height: 24),
            _seccion('Apariencia', tonos),
            _tarjeta(
              tonos,
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeService.mode,
                builder: (_, modo, __) => Column(
                  children: [
                    _opcionTema(ThemeMode.system, modo, tonos),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _opcionTema(ThemeMode.light, modo, tonos),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _opcionTema(ThemeMode.dark, modo, tonos),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _seccion('Categoría de frases', tonos),
            ...Categoria.values.map((c) => _tarjetaCategoria(c, tonos)),
            const SizedBox(height: 24),
            _seccion('Notificación de la mañana', tonos),
            _tarjeta(
              tonos,
              child: Column(
                children: [
                  ListTile(
                    onTap: _cambiarHora,
                    leading: const Icon(Icons.wb_sunny_outlined,
                        color: AppColors.terracota),
                    title: Text(
                      _hora.format(context),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: tonos.textoOscuro,
                      ),
                    ),
                    subtitle: Text(
                      'Toca para cambiar',
                      style: GoogleFonts.nunito(color: tonos.textoSuave),
                    ),
                    trailing:
                        Icon(Icons.chevron_right, color: tonos.textoSuave),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    onTap: _probarNotificacion,
                    leading: const Icon(Icons.notifications_active_outlined,
                        color: AppColors.terracota),
                    title: Text(
                      'Probar al instante',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        color: tonos.textoOscuro,
                      ),
                    ),
                    subtitle: Text(
                      'Llega ahora mismo',
                      style: GoogleFonts.nunito(color: tonos.textoSuave),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    onTap: _probarEn30Seg,
                    leading: const Icon(Icons.timer_outlined,
                        color: AppColors.terracota),
                    title: Text(
                      'Probar en 30 segundos',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        color: tonos.textoOscuro,
                      ),
                    ),
                    subtitle: Text(
                      'Verifica que llegan programadas',
                      style: GoogleFonts.nunito(color: tonos.textoSuave),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    onTap: _diagnosticar,
                    leading: const Icon(Icons.health_and_safety_outlined,
                        color: AppColors.terracota),
                    title: Text(
                      'Diagnóstico',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        color: tonos.textoOscuro,
                      ),
                    ),
                    subtitle: Text(
                      'Revisar permisos',
                      style: GoogleFonts.nunito(color: tonos.textoSuave),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.naranjaSuave.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.naranjaSuave.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Si las notificaciones no llegan: ve a Ajustes del celu → Apps → Un Día Más → Batería → "Sin restricciones" (o "Permitir actividad en segundo plano"). Esto pasa más en celulares con ahorro de batería agresivo.',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        height: 1.4,
                        color: tonos.textoOscuro,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _seccion('Notificación de la noche (opcional)', tonos),
            _tarjeta(
              tonos,
              child: Column(
                children: [
                  SwitchListTile(
                    value: _noche,
                    onChanged: _toggleNoche,
                    activeColor: AppColors.terracota,
                    secondary: const Icon(Icons.nightlight_outlined,
                        color: AppColors.terracota),
                    title: Text(
                      'Frase para dormir',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        color: tonos.textoOscuro,
                      ),
                    ),
                    subtitle: Text(
                      'Una segunda notif para cerrar tu día',
                      style: GoogleFonts.nunito(color: tonos.textoSuave),
                    ),
                  ),
                  if (_noche) ...[
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      onTap: _cambiarHoraNoche,
                      leading: const Icon(Icons.alarm,
                          color: AppColors.terracota),
                      title: Text(
                        _horaNoche.format(context),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: tonos.textoOscuro,
                        ),
                      ),
                      subtitle: Text(
                        'Hora de la noche',
                        style: GoogleFonts.nunito(color: tonos.textoSuave),
                      ),
                      trailing: Icon(Icons.chevron_right,
                          color: tonos.textoSuave),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _seccion('Mis cosas', tonos),
            _tarjeta(
              tonos,
              child: Column(
                children: [
                  _itemNav(
                    icono: Icons.eco_outlined,
                    titulo: 'Mi plantita',
                    subtitulo: 'Cómo va creciendo contigo',
                    tonos: tonos,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PlantitaScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _itemNav(
                    icono: Icons.timeline_outlined,
                    titulo: 'Mi Camino',
                    subtitulo: 'Tus reflexiones en el tiempo',
                    tonos: tonos,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MiCaminoScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _itemNav(
                    icono: Icons.mail_outline,
                    titulo: 'Cartas a mi yo futuro',
                    subtitulo: 'Escribe hoy, recibe mañana',
                    tonos: tonos,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartasScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _itemNav(
                    icono: Icons.book_outlined,
                    titulo: 'Mi diario',
                    subtitulo: 'Una línea por día + mood',
                    tonos: tonos,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DiarioScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _itemNav(
                    icono: Icons.show_chart,
                    titulo: 'Gráfica de mi mood',
                    subtitulo: 'Cómo te has sentido',
                    tonos: tonos,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const MoodGraficaScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _itemNav(
                    icono: Icons.emoji_events_outlined,
                    titulo: 'Mis logros',
                    subtitulo: 'Medallas que has ganado',
                    tonos: tonos,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LogrosScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _itemNav(
                    icono: Icons.favorite_outline,
                    titulo: 'Mis favoritas',
                    subtitulo: 'Frases que guardaste',
                    tonos: tonos,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const FavoritasScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Un Día Más • v6.0',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: tonos.textoSuave,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo, Tonos tonos) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
        child: Text(
          titulo,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: tonos.textoSuave,
            letterSpacing: 0.4,
          ),
        ),
      );

  Widget _tarjeta(Tonos tonos, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: tonos.cremaTarjeta,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _itemNav({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Tonos tonos,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icono, color: AppColors.terracota),
      title: Text(titulo,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: tonos.textoOscuro,
          )),
      subtitle: Text(subtitulo,
          style: GoogleFonts.nunito(color: tonos.textoSuave)),
      trailing: Icon(Icons.chevron_right, color: tonos.textoSuave),
    );
  }

  Widget _opcionTema(ThemeMode m, ThemeMode actual, Tonos tonos) {
    return RadioListTile<ThemeMode>(
      value: m,
      groupValue: actual,
      activeColor: AppColors.terracota,
      onChanged: (v) {
        if (v != null) ThemeService.cambiar(v);
      },
      title: Text(
        ThemeService.etiqueta(m),
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          color: tonos.textoOscuro,
        ),
      ),
    );
  }

  Widget _tarjetaCategoria(Categoria c, Tonos tonos) {
    final sel = c == _categoria;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _cambiarCategoria(c),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: sel ? AppColors.terracota : tonos.cremaTarjeta,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: sel
                  ? AppColors.terracota
                  : AppColors.naranjaSuave.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Text(c.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  c.nombre,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : tonos.textoOscuro,
                  ),
                ),
              ),
              if (sel)
                const Icon(Icons.check_circle, color: Colors.white)
              else
                const Icon(Icons.circle_outlined,
                    color: AppColors.naranjaSuave),
            ],
          ),
        ),
      ),
    );
  }
}
