import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/carta.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'escribir_carta_screen.dart';
import 'leer_carta_screen.dart';

class CartasScreen extends StatefulWidget {
  const CartasScreen({super.key});

  @override
  State<CartasScreen> createState() => _CartasScreenState();
}

class _CartasScreenState extends State<CartasScreen> {
  List<Carta> _cartas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await StorageService.obtenerCartas();
    lista.sort((a, b) => a.fechaEntrega.compareTo(b.fechaEntrega));
    if (!mounted) return;
    setState(() {
      _cartas = lista;
      _cargando = false;
    });
  }

  Future<void> _escribir() async {
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EscribirCartaScreen()),
    );
    if (res == true) {
      _cargar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carta enviada al futuro 📬'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _abrir(Carta c) async {
    if (!c.yaDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Esta carta abre en ${c.diasParaEntrega} ${c.diasParaEntrega == 1 ? "día" : "días"}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LeerCartaScreen(carta: c)),
    );
    _cargar();
  }

  Future<void> _borrar(Carta c) async {
    await NotificationService.cancelarEntregaCarta(c.id);
    await StorageService.borrarCarta(c.id);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final tonos = Tonos.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cartas a mi yo futuro')),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _cartas.isEmpty
                ? _vacio(tonos)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
                    itemCount: _cartas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _tarjeta(_cartas[i], tonos),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _escribir,
        backgroundColor: AppColors.terracota,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Escribir carta'),
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
            const Text('📬', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Escribe a tu yo del futuro',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tonos.textoOscuro,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escribe una carta hoy y eliges cuándo\n te la quieres entregar: en 1 mes,\n6 meses, 1 año... la decides tú.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                height: 1.5,
                color: tonos.textoSuave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjeta(Carta c, Tonos tonos) {
    final disponible = c.yaDisponible;
    final noLeida = disponible && !c.leida;
    final entrega = DateFormat.yMMMMd('es').format(DateTime.parse(c.fechaEntrega));
    return Dismissible(
      key: ValueKey('carta-${c.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Borrar esta carta?'),
            content: const Text(
                'No vas a poder leerla. Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Borrar',
                  style: GoogleFonts.nunito(
                    color: AppColors.terracota,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.terracota.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _borrar(c),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _abrir(c),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tonos.cremaTarjeta,
              borderRadius: BorderRadius.circular(20),
              border: noLeida
                  ? Border.all(color: AppColors.terracota, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: disponible
                        ? AppColors.terracota.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    disponible ? '📬' : '🔒',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disponible
                            ? (c.leida ? 'Ya leída' : 'Disponible para abrir')
                            : 'En ${c.diasParaEntrega} ${c.diasParaEntrega == 1 ? "día" : "días"}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: disponible
                              ? AppColors.terracota
                              : tonos.textoSuave,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entrega,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: tonos.textoOscuro,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.contenido.length > 60
                            ? '${c.contenido.substring(0, 60)}...'
                            : c.contenido,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: tonos.textoSuave,
                        ),
                      ),
                    ],
                  ),
                ),
                if (noLeida)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.terracota,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  Icon(Icons.chevron_right, color: tonos.textoSuave),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
