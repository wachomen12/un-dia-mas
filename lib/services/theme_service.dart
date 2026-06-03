import 'package:flutter/material.dart';

import 'storage_service.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> cargar() async {
    final guardado = await StorageService.obtenerModoOscuro();
    mode.value = _fromString(guardado);
  }

  static Future<void> cambiar(ThemeMode nuevo) async {
    mode.value = nuevo;
    await StorageService.guardarModoOscuro(_toString(nuevo));
  }

  static ThemeMode _fromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static String etiqueta(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Como el sistema';
    }
  }
}
