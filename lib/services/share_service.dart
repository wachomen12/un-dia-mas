import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> compartirDesdeKey(
    GlobalKey key, {
    double pixelRatio = 3.0,
    String? texto,
  }) async {
    final bytes = await capturar(key, pixelRatio: pixelRatio);
    await _compartirBytes(bytes, texto: texto);
  }

  static Future<Uint8List> capturar(
    GlobalKey key, {
    double pixelRatio = 3.0,
  }) async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static Future<void> _compartirBytes(Uint8List bytes, {String? texto}) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/un_dia_mas_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: texto ?? 'Un Día Más 🌅',
    );
  }
}
