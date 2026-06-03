import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

import '../data/frases.dart';
import '../models/categoria.dart';

class NotificationService {
  static const int _idDiaria = 0;
  static const int _idNoche = 1;
  static const int _idRecordatorio = 2;
  static const int _idPrueba = 99;

  static const String _canalId = 'un_dia_mas_canal';
  static const String _canalNombre = 'Mensaje diario';
  static const String _canalDesc = 'Tu frase del día para no rendirte.';

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;

  static Future<void> inicializar() async {
    if (_inicializado) return;
    try {
      tz.initializeTimeZones();
      try {
        final tzNombre = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(tzNombre));
      } catch (_) {
        try {
          tz.setLocalLocation(tz.getLocation('America/Guayaquil'));
        } catch (_) {}
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _plugin.initialize(settings);

      try {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _canalId,
            _canalNombre,
            description: _canalDesc,
            importance: Importance.high,
            showBadge: true,
          ),
        );
      } catch (_) {}
    } catch (_) {}
    _inicializado = true;
  }

  static Future<bool> pedirPermisos() async {
    await inicializar();
    try {
      await Permission.notification.request();
    } catch (_) {}
    bool granted = false;
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      granted = await androidPlugin?.requestNotificationsPermission() ?? false;
      try {
        await androidPlugin?.requestExactAlarmsPermission();
      } catch (_) {}
    } catch (_) {}
    return granted;
  }

  static Future<bool> permisosOtorgados() async {
    try {
      return await Permission.notification.isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> alarmasExactasOtorgadas() async {
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  static NotificationDetails _detalles() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _canalId,
        _canalNombre,
        channelDescription: _canalDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(''),
      ),
    );
  }

  static Future<void> programarDiaria({
    required int hora,
    required int minuto,
    required Categoria categoria,
  }) async {
    try {
      await inicializar();
      await _plugin.cancel(_idDiaria);

      final frase = Frases.delDia(categoria, DateTime.now());

      await _plugin.zonedSchedule(
        _idDiaria,
        'Un Día Más 🌅',
        frase,
        _siguienteOcurrencia(hora, minuto),
        _detalles(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  static Future<void> programarNoche({
    required int hora,
    required int minuto,
  }) async {
    try {
      await inicializar();
      await _plugin.cancel(_idNoche);

      final frase = Frases.fraseCalma(DateTime.now());

      await _plugin.zonedSchedule(
        _idNoche,
        'Buenas noches 🌙',
        frase,
        _siguienteOcurrencia(hora, minuto),
        _detalles(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  static Future<void> cancelarNoche() async {
    await inicializar();
    await _plugin.cancel(_idNoche);
  }

  static Future<void> programarRecordatorioCarinoso() async {
    try {
      await inicializar();
      await _plugin.cancel(_idRecordatorio);

      final cuando = tz.TZDateTime.now(tz.local).add(const Duration(days: 2));

      await _plugin.zonedSchedule(
        _idRecordatorio,
        'Te extrañamos 🤍',
        'Vuelve cuando quieras, sin culpa. Aquí estamos.',
        cuando,
        _detalles(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  static Future<void> enviarPrueba(String frase) async {
    try {
      await inicializar();
      await _plugin.show(_idPrueba, 'Un Día Más 🌅', frase, _detalles());
    } catch (_) {}
  }

  static Future<void> programarPruebaEn(int segundos, String frase) async {
    try {
      await inicializar();
      await _plugin.cancel(_idPrueba);
      final cuando = tz.TZDateTime.now(tz.local)
          .add(Duration(seconds: segundos));
      await _plugin.zonedSchedule(
        _idPrueba,
        'Un Día Más 🌅 (prueba)',
        frase,
        cuando,
        _detalles(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  static Future<void> programarEntregaCarta({
    required int idCarta,
    required DateTime cuando,
  }) async {
    await inicializar();
    final id = 1000 + idCarta;
    final tzCuando = tz.TZDateTime.from(cuando, tz.local);
    final ahora = tz.TZDateTime.now(tz.local);
    if (tzCuando.isBefore(ahora)) return;

    await _plugin.zonedSchedule(
      id,
      'Te llegó una carta 📬',
      'La escribiste hace un tiempo. Toca para leerla.',
      tzCuando,
      _detalles(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelarEntregaCarta(int idCarta) async {
    await inicializar();
    await _plugin.cancel(1000 + idCarta);
  }

  static Future<List<PendingNotificationRequest>> pendientes() async {
    await inicializar();
    return _plugin.pendingNotificationRequests();
  }

  static tz.TZDateTime _siguienteOcurrencia(int hora, int minuto) {
    final ahora = tz.TZDateTime.now(tz.local);
    var programada = tz.TZDateTime(
      tz.local,
      ahora.year,
      ahora.month,
      ahora.day,
      hora,
      minuto,
    );
    if (programada.isBefore(ahora)) {
      programada = programada.add(const Duration(days: 1));
    }
    return programada;
  }
}
