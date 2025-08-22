import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'colors.dart';

class AppTheme {
  /// Función reutilizable para construir AppBarTheme consistente
  static AppBarTheme _buildAppBarTheme(ThemeData base) {
    return AppBarTheme(
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Roboto',
        color: base.colorScheme.onSurface,
      ),
      backgroundColor: base.appBarTheme.backgroundColor ?? base.colorScheme.surface,
      foregroundColor: base.appBarTheme.foregroundColor ?? base.colorScheme.onSurface,
      elevation: base.appBarTheme.elevation ?? 0,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData.light(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.lightPrimary,
      colorScheme: ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        onPrimary: AppColors.lightOnPrimary,
        surface: AppColors.lightBackground,
        onSurface: AppColors.lightOnBackground,
        tertiary: AppColors.lightPositive,
        error: AppColors.lightNegative,
      ),
      appBarTheme: _buildAppBarTheme(ThemeData.light(useMaterial3: true)),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.lightTextPrimary,
          fontFamily: 'Roboto',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.lightTextPrimary,
          fontFamily: 'Roboto',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.lightTextSecondary,
          fontFamily: 'Roboto',
        ),
      ),
      dividerColor: AppColors.lightDivider,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: AppColors.lightBackground,
        contentTextStyle: TextStyle(color: AppColors.lightOnBackground),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        showCloseIcon: false,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        surface: AppColors.darkBackground,
        onSurface: AppColors.darkOnBackground,
        tertiary: AppColors.darkPositive,
        error: AppColors.darkNegative,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkOnBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      dividerColor: AppColors.darkDivider,
      textTheme: Typography.whiteCupertino.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.darkOnBackground,
          fontFamily: 'Roboto',
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: AppColors.darkOnBackground,
          fontFamily: 'Roboto',
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: AppColors.darkOnSurface,
          fontFamily: 'Roboto',
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: AppColors.darkBackground,
        contentTextStyle: TextStyle(color: AppColors.darkOnBackground),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        showCloseIcon: false,
      ),
    );
    
    return baseTheme.copyWith(
      appBarTheme: _buildAppBarTheme(baseTheme),
    );
  }

  static ThemeData get lightMonoTheme {
    return ThemeData.light(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightTextPrimary,
        secondary: AppColors.lightTextPrimary,
        onPrimary: AppColors.lightOnPrimary,
        surface: AppColors.lightBackground,
        onSurface: AppColors.lightTextPrimary,
      ),
      appBarTheme: _buildAppBarTheme(ThemeData.light(useMaterial3: true)),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.lightTextPrimary,
          fontFamily: 'Roboto',
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.lightTextPrimary),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.lightTextSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: AppColors.lightBackground,
        contentTextStyle: TextStyle(color: AppColors.lightTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        showCloseIcon: false,
      ),
    );
  }

  static ThemeData get darkMonoTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.darkOnBackground,
        secondary: AppColors.darkOnBackground,
        onPrimary: AppColors.darkBackground,
        surface: AppColors.darkBackground,
        onSurface: AppColors.darkOnBackground,
      ),
      appBarTheme: _buildAppBarTheme(ThemeData.dark(useMaterial3: true)),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.darkOnBackground,
          fontFamily: 'Roboto',
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.darkOnBackground),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkOnSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: AppColors.darkBackground,
        contentTextStyle: TextStyle(color: AppColors.darkOnBackground),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        showCloseIcon: false,
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
