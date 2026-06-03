import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_nombre_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'services/widget_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  Future<void> intentar(Future<void> Function() f, String etiqueta) async {
    try {
      await f().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Init "$etiqueta" falló: $e');
    }
  }

  await intentar(() => initializeDateFormatting('es'), 'fechas');
  await intentar(() => NotificationService.inicializar(), 'notificaciones');
  await intentar(() => ThemeService.cargar(), 'tema');
  await intentar(() => WidgetService.inicializar(), 'widget');

  runApp(const UnDiaMasApp());
}

class UnDiaMasApp extends StatelessWidget {
  const UnDiaMasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.mode,
      builder: (_, modo, __) => MaterialApp(
        title: 'Un Día Más',
        debugShowCheckedModeBanner: false,
        themeMode: modo,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es'), Locale('en')],
        locale: const Locale('es'),
        home: const _Arranque(),
      ),
    );
  }
}

class _Arranque extends StatefulWidget {
  const _Arranque();

  @override
  State<_Arranque> createState() => _ArranqueState();
}

class _ArranqueState extends State<_Arranque> {
  @override
  void initState() {
    super.initState();
    _decidir();
  }

  Future<void> _decidir() async {
    bool hecho = false;
    try {
      hecho = await StorageService.onboardingCompleto()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
    } catch (e) {
      debugPrint('Error en onboardingCompleto: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => hecho
            ? const HomeScreen()
            : const OnboardingNombreScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.terracota),
      ),
    );
  }
}
