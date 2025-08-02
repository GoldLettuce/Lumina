import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData.light(
      useMaterial3: true,
    ).copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.lightPrimary,
      colorScheme: ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        onPrimary: AppColors.lightOnPrimary,
        surface: AppColors.lightSurface,
        background: AppColors.lightBackground,
        onSurface: AppColors.lightOnSurface,
        onBackground: AppColors.lightOnBackground,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.lightTextPrimary,
          fontFamily: 'Roboto',
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.lightTextPrimary, fontFamily: 'Roboto'),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.lightTextSecondary, fontFamily: 'Roboto'),
      ),
      dividerColor: AppColors.lightDivider,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        background: AppColors.darkBackground,
        onBackground: AppColors.darkOnBackground,
        surface: AppColors.darkBackground,
        onSurface: AppColors.darkOnSurface,
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
    );
  }

  static ThemeData get lightMonoTheme {
    return ThemeData.light(
      useMaterial3: true,
    ).copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        secondary: Colors.black,
        onPrimary: AppColors.lightOnPrimary,
        surface: AppColors.lightSurface,
        background: AppColors.lightBackground,
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
