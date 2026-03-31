import 'package:flutter/material.dart';
import 'app_config.dart';

class SubliriumColors {
  static Color get rosa => AppConfig.primaryColor;
  static Color get azul => AppConfig.secondaryColor;
  static Color get naranja => AppConfig.accentColor;
  static Color get crema => AppConfig.backgroundColor;

  static const negro = Color(0xFF010101);
  static const amarillo = Color(0xFFF9C706);

  static LinearGradient get headerGradient => LinearGradient(
    colors: [azul, rosa, naranja],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const fabGradient = LinearGradient(
    colors: [Color(0xFFC1356F), Color(0xFFE57836), Color(0xFFF9C706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const logoSGradient = LinearGradient(
    colors: [Color(0xFF597FA9), Color(0xFFC1356F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const logoRGradient = LinearGradient(
    colors: [Color(0xFFC1356F), Color(0xFFE57836), Color(0xFFF9C706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const background = Color(0xFFFBF8F1);
  static const cardBackground = Colors.white;

  static const textPrimary = negro;
  static const textSecondary = negro;

  static const border = Color(0xFFE5E7EB);

  static const stockOkBg = Color(0xFFF0FDF4);
  static const stockOkText = Color(0xFF16A34A);
  static const stockLowBg = Color(0xFFFFF1F2);
  static const stockLowText = Color(0xFFE11D48);
  static const stockZeroBg = Color(0xFFF5F5F5);
  static const stockZeroText = Color(0xFF9CA3AF);

  static const pendingBg = Color(0xFFFFFBEB);
  static const pendingBorder = Color(0xFFFDE68A);
  static const pendingText = Color(0xFF92400E);

  static const backButton = Color(0xFF597FA9);
  static const deleteBorder = Color(0xFFFECDD3);
  static const deleteText = Color(0xFFE11D48);
  static const inputFocusedBorder = Color(0xFF597FA9);
  static const inputFocusedBg = Color(0xFFF0F9FF);
  static const cancelBg = Color(0xFFFBF8F1);
  static const cancelText = Color(0xFF6B7280);

  static const logoCircleBg = Color(0xFFFBF8F1);
  static const logoCircleBorder = Color(0xFF010101);

  static const cyan = Color(0xFF597FA9);
  static const purple = Color(0xFFC1356F);
  static const magenta = Color(0xFFC1356F);
  static const logoOrange = Color(0xFFE57836);
  static const logoCyan = Color(0xFF597FA9);
  static const logoPurple = Color(0xFFC1356F);
  static const logoPink = Color(0xFFC1356F);
  static const logoYellow = Color(0xFFF9C706);
  static const cream = Color(0xFFFBF8F1);

  static const navActiveGreen = Color(0xFF25D366);
  static const navActiveGreenLight = Color(0xFFE8F5E9);

  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF597FA9), Color(0xFFC1356F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color get primary => AppConfig.primaryColor;
  static Color get secondary => AppConfig.secondaryColor;
  static Color get accent => AppConfig.accentColor;
}

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConfig.primaryColor,
        primary: AppConfig.primaryColor,
        secondary: AppConfig.secondaryColor,
        tertiary: AppConfig.accentColor,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: SubliriumColors.background,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: SubliriumColors.border, width: 1.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConfig.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: SubliriumColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: SubliriumColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppConfig.secondaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: SubliriumColors.textPrimary),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: SubliriumColors.textPrimary),
        bodyMedium: TextStyle(color: SubliriumColors.textPrimary),
        bodySmall: TextStyle(color: SubliriumColors.textPrimary),
        titleLarge: TextStyle(
          color: SubliriumColors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
        titleMedium: TextStyle(
          color: SubliriumColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: TextStyle(
          color: SubliriumColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConfig.primaryColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
