import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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
    return ThemeData.light(
      useMaterial3: true,
    ).copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        onPrimary: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Roboto',
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary, fontFamily: 'Roboto'),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontFamily: 'Roboto'),
      ),
      dividerColor: AppColors.border,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData.dark(
      useMaterial3: true,
    ).copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        onPrimary: Colors.white,
        surface: const Color(0xFF1E1E1E),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Roboto',
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Roboto'),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Roboto'),
      ),
      dividerColor: const Color(0xFF424242),
    );
  }

  static ThemeData get lightMonoTheme {
    return ThemeData.light(
      useMaterial3: true,
    ).copyWith(
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        secondary: Colors.black,
        onPrimary: Colors.white,
        surface: Colors.white,
        background: Colors.white,
        onSurface: Colors.black,
        onBackground: Colors.black,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }

  static ThemeData get darkMonoTheme {
    return ThemeData.dark(
      useMaterial3: true,
    ).copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Colors.white,
        onPrimary: Colors.black,
        surface: Colors.black,
        background: Colors.black,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
      ),
    );
  }
}

@HiveType(typeId: 11)
enum AppThemeMode {
  @HiveField(0)
  system,
  @HiveField(1)
  light,
  @HiveField(2)
  dark,
  @HiveField(3)
  lightMono,
  @HiveField(4)
  darkMono,
}

class AppThemeModeAdapter extends TypeAdapter<AppThemeMode> {
  @override
  final int typeId = 11;

  @override
  AppThemeMode read(BinaryReader reader) {
    return AppThemeMode.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, AppThemeMode obj) {
    writer.writeByte(obj.index);
  }
}
