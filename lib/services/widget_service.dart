import 'package:home_widget/home_widget.dart';

import '../data/frases.dart';
import 'storage_service.dart';

class WidgetService {
  static const String _appGroupId = 'group.com.undiamas.un_dia_mas';
  static const String _providerAndroid = 'UnDiaMasWidgetProvider';

  static Future<void> inicializar() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (_) {}
  }

  static Future<void> actualizarConDatos() async {
    try {
      final categoria = await StorageService.obtenerCategoria();
      final nombre = await StorageService.obtenerNombre();
      final frase = Frases.delDia(categoria, DateTime.now());

      await HomeWidget.saveWidgetData<String>('frase_del_dia', frase);
      await HomeWidget.saveWidgetData<String>('categoria_emoji', categoria.emoji);
      await HomeWidget.saveWidgetData<String>('nombre', nombre);

      await HomeWidget.updateWidget(
        name: _providerAndroid,
        androidName: _providerAndroid,
      );
    } catch (_) {
      // Silencioso: en web no hay widget, no es error.
    }
  }
}
