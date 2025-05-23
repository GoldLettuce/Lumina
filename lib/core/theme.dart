import 'package:flutter/material.dart';

class AppColors {
  static const background = Colors.white;
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const primary = Color(0xFF3949AB); // Azul índigo suave
  static const positive = Color(0xFF4CAF50); // Verde suave
  static const negative = Color(0xFFE53935); // Rojo apagado
  static const border = Color(0xFFE0E0E0);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        onPrimary: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      dividerColor: AppColors.border,
      fontFamily: 'Roboto',
      useMaterial3: true,
    );
  }
}
