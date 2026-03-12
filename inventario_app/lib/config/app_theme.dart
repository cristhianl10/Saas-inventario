import 'package:flutter/material.dart';

class SubliriumColors {
  // GRADIENTES
  static const headerGradient = LinearGradient(
    colors: [Color(0xFF2ABDE8), Color(0xFF7B2FBE), Color(0xFFD81B8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const fabGradient = LinearGradient(
    colors: [Color(0xFFD0185A), Color(0xFFF06B1A), Color(0xFFF5C200)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Logo "S" gradient
  static const logoSGradient = LinearGradient(
    colors: [Color(0xFF2ABDE8), Color(0xFF7B2FBE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Logo "R" gradient
  static const logoRGradient = LinearGradient(
    colors: [Color(0xFFD0185A), Color(0xFFF06B1A), Color(0xFFF5C200)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Colores individuales
  static const magenta = Color(0xFFD81B8A);
  static const cyan = Color(0xFF2ABDE8);
  static const purple = Color(0xFF7B2FBE);

  // FONDOS
  static const background = Color(0xFFF9F8F5);
  static const cream = Color(0xFFF5F0E8);
  static const cardBackground = Colors.white;

  // TEXTOS - todos en negro
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF111111);

  // BORDES
  static const border = Color(0xFFE5E7EB);

  // STOCK
  static const stockOkBg = Color(0xFFF0FDF4);
  static const stockOkText = Color(0xFF16A34A);
  static const stockLowBg = Color(0xFFFFF1F2);
  static const stockLowText = Color(0xFFE11D48);
  static const stockZeroBg = Color(0xFFF5F5F5);
  static const stockZeroText = Color(0xFF9CA3AF);

  // PENDIENTE
  static const pendingBg = Color(0xFFFFFBEB);
  static const pendingBorder = Color(0xFFFDE68A);
  static const pendingText = Color(0xFF92400E);

  // ACCIONES
  static const backButton = Color(0xFF2ABDE8);
  static const deleteBorder = Color(0xFFFECDD3);
  static const deleteText = Color(0xFFE11D48);
  static const inputFocusedBorder = Color(0xFF2ABDE8);
  static const inputFocusedBg = Color(0xFFF0FBFF);
  static const cancelBg = Color(0xFFF9F8F5);
  static const cancelText = Color(0xFF6B7280);

  // Logo circle
  static const logoCircleBg = Color(0xFFF5F0E8);
  static const logoCircleBorder = Color(0xFF111111);
}

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: SubliriumColors.stockLowText,
        primary: SubliriumColors.stockLowText,
        secondary: SubliriumColors.backButton,
        brightness: Brightness.light,
        surface: SubliriumColors.cardBackground,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: SubliriumColors.background,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: SubliriumColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SubliriumColors.border, width: 1.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: SubliriumColors.stockLowText,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SubliriumColors.stockLowText,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SubliriumColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SubliriumColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SubliriumColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: SubliriumColors.inputFocusedBorder,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(color: SubliriumColors.textSecondary),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: SubliriumColors.textPrimary),
        bodyMedium: TextStyle(color: SubliriumColors.textPrimary),
        bodySmall: TextStyle(color: SubliriumColors.textSecondary),
        titleLarge: TextStyle(
          color: SubliriumColors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
        titleMedium: TextStyle(
          color: SubliriumColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: TextStyle(
          color: SubliriumColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: SubliriumColors.stockLowText,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
