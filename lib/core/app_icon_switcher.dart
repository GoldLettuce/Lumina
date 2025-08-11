import 'package:flutter/services.dart';

/// Cambia el icono de la app en iOS usando Alternate App Icons.
/// name:
///   - "AppIconDark" para usar el alternativo oscuro.
///   - null para volver al icono principal (AppIcon).
class AppIconSwitcher {
  static const MethodChannel _ch = MethodChannel('app_icon');

  static Future<void> setIcon({String? name}) async {
    try {
      await _ch.invokeMethod('setIcon', {'name': name});
    } on MissingPluginException {
      // Silencioso en plataformas no iOS o si el canal no existe.
    }
  }
}
