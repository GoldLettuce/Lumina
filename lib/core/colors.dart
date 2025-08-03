import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lumina/core/theme.dart';
import 'package:lumina/ui/providers/theme_mode_provider.dart';

/// Colores centralizados para el tema claro de la aplicación
class AppColors {
  // Colores primarios del tema claro
  static const lightPrimary = Color(0xFF3949AB); // Azul índigo suave
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightSecondary = Color(0xFF3949AB);
  static const lightOnSecondary = Color(0xFFFFFFFF);

  // Colores de fondo y superficie
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnBackground = Colors.black;
  static const lightOnSurface = Color(0xFF212121);

  // Colores de texto
  static const lightTextPrimary = Color(0xFF212121);
  static const lightTextSecondary = Color(0xFF757575);

  // Colores de estado
  static const lightPositive = Color(0xFF4CAF50); // Verde suave
  static const lightNegative = Color(0xFFE53935); // Rojo apagado

  // Colores de bordes y divisores
  static const lightBorder = Color(0xFFE0E0E0);
  static const lightDivider = Color(0xFFE0E0E0);

  // Colores de iconos
  static const lightIconPrimary = Color(0xFF3949AB);
  static const lightIconSecondary = Color(0xFF757575);
  static const lightIconError = Color(0xFFE53935);
  static const lightIconSuccess = Color(0xFF4CAF50);

  // Colores de tarjetas y elementos UI
  static const lightCardBackground = Color(0xFFFFFFFF);
  static const lightCardBorder = Color(0xFFE0E0E0);
  static const lightAppBarBackground = Color(0xFFFFFFFF);
  static const lightAppBarForeground = Color(0xFF212121);

  // Colores de botones
  static const lightButtonPrimary = Color(0xFF3949AB);
  static const lightButtonOnPrimary = Color(0xFFFFFFFF);
  static const lightButtonSecondary = Color(0xFFE0E0E0);
  static const lightButtonOnSecondary = Color(0xFF212121);

  // Colores de inputs
  static const lightInputBackground = Color(0xFFFFFFFF);
  static const lightInputBorder = Color(0xFFE0E0E0);
  static const lightInputText = Color(0xFF212121);
  static const lightInputPlaceholder = Color(0xFF757575);

  // DARK THEME (recomendación basada en Material Design + apps reales)
  static const darkBackground = Color(0xFF121212); // fondo base
  static const darkSurface = Color(0xFF1E1E1E);    // tarjetas, dialogs
  static const darkPrimary = Color(0xFF4FD8EB);    // color de acento actual
  static const darkOnPrimary = Color(0xFF00363F);
  static const darkOnBackground = Color(0xE0FFFFFF); // 88% blanco para texto
  static const darkOnSurface = Color(0xB3FFFFFF);    // 70% blanco para texto secundario
  static const darkDivider = Color(0x29FFFFFF);      // 16% blanco
  
  // Colores de estado para tema oscuro (tonos refinados pastel)
  static const darkPositive = Color(0xFF81C784); // Material soft green
  static const darkNegative = Color(0xFFE57373); // Material soft red
  
  // Colores genéricos para usar en ambos temas (estado financiero más suave y profesional)
  static const positive = Color(0xFF81C784); // Material soft green
  static const negative = Color(0xFFE57373); // Material soft red
  
  // Color de acento azul suave para acciones secundarias
  static const accentBlue = Color(0xFF64B5F6); // azul pastel Material 300

  // Color transparente para uso consistente
  static const transparent = Colors.transparent;

  /// Devuelve el color apropiado para valores negativos según el modo de tema
  /// En modo monoclaro, usa el color de texto primario en lugar del rojo
  static Color textNegative(BuildContext context) {
    // Obtener el provider usando Provider.of
    final themeModeProvider = Provider.of<ThemeModeProvider>(context, listen: false);
    final themeMode = themeModeProvider.mode;
    
    // Si el modo es monoclaro, usar el color de texto primario
    if (themeMode == AppThemeMode.lightMono || themeMode == AppThemeMode.darkMono) {
      return Theme.of(context).colorScheme.onSurface;
    }
    
    // En cualquier otro caso, usar el color rojo estándar
    return Colors.red;
  }
}

// Colores botón SELL (azul adaptado)
const Color sellButtonBlueLight = Color(0xFF2979FF);         // Base claro
const Color sellButtonBlueDark = Color(0xFF82B1FF);          // Base oscuro
const Color sellButtonBlueSelectedLight = Color(0xFF1565C0); // Seleccionado claro
const Color sellButtonBlueSelectedDark = Color(0xFF448AFF);  // Seleccionado oscuro

// Botón de VENTA (SELL) minimalista
const Color sellButtonNeutralLight = Color(0xFFC2D4E5);         // Modo claro (ajustado con azul suave)
const Color sellButtonNeutralDark = Color(0xFF2E3A44);          // Modo oscuro
const Color sellButtonSelectedLight = Color(0xFF90B6DA);        // Pastel azul (claro)
const Color sellButtonSelectedDark = Color(0xFF4B5B68);         // Azul sobrio (oscuro)

// Botón de COMPRA (BUY) minimalista
const Color buyButtonGreenLight = Color(0xFFDFF5E3);     // no seleccionado (modo claro)
const Color buyButtonGreenSelectedLight = Color(0xFF98C7A7); // seleccionado (modo claro)

// Botón CANCEL rojo pastel minimalista
const Color cancelButtonLight = Color(0xFFF5DADA);  // Rojo pastel claro
const Color cancelButtonDark = Color(0xFF5A3C3C);   // Rojo apagado oscuro 

// Texto del botón CANCEL
const Color cancelButtonTextLight = Color(0xFFBB4444);   // Texto rojo más fuerte (claro)
const Color cancelButtonTextDark = Color(0xFFFF8888);    // Texto rojo suave vibrante (oscuro) 

// Colores de selección de transacción  ─── ¡SOLO CONSTANTES!
const Color selectedTileLight       = Color(0xFFE3F2FD); // azul claro pastel
const Color selectedTileDark        = Color(0xFF263238); // azul gris-azul oscuro
const Color selectedTileMonoLight   = Color(0xFFE0E0E0); // gris claro mono
const Color selectedTileMonoDark    = Color(0xFF303030); // gris oscuro mono