import 'package:flutter/material.dart';

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
  
  // Colores genéricos para usar en ambos temas (estado financiero más suave y profesional)
  static const positive = Color(0xFF81C784); // Material soft green
  static const negative = Color(0xFFE57373); // Material soft red
  
  // Color de acento azul suave para acciones secundarias
  static const accentBlue = Color(0xFF64B5F6); // azul pastel Material 300
} 