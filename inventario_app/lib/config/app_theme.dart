import 'package:flutter/material.dart';

class SubliriumColors {
  // ========================================
  // COLORES OFICIALES DE LA MARCA SUBLIRIUM
  // ========================================
  static const negro = Color(0xFF010101); // #010101 - Negro principal
  static const crema = Color(0xFFFBF8F1); // #FBF8F1 - Fondo crema
  static const rosa = Color(0xFFC1356F); // #C1356F - Rosa
  static const naranja = Color(0xFFE57836); // #E57836 - Naranja
  static const amarillo = Color(0xFFF9C706); // #F9C706 - Amarillo
  static const azul = Color(0xFF597FA9); // #597FA9 - Azul

  // GRADIENTES DE LA MARCA
  static const headerGradient = LinearGradient(
    colors: [azul, rosa, naranja],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const fabGradient = LinearGradient(
    colors: [rosa, naranja, amarillo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const logoSGradient = LinearGradient(
    colors: [azul, rosa],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const logoRGradient = LinearGradient(
    colors: [rosa, naranja, amarillo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // FONDOS
  static const background = crema;
  static const cardBackground = Colors.white;

  // TEXTOS
  static const textPrimary = negro;
  static const textSecondary = negro;

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
  static const backButton = azul;
  static const deleteBorder = Color(0xFFFECDD3);
  static const deleteText = Color(0xFFE11D48);
  static const inputFocusedBorder = azul;
  static const inputFocusedBg = Color(0xFFF0F9FF);
  static const cancelBg = crema;
  static const cancelText = Color(0xFF6B7280);

  // Logo circle
  static const logoCircleBg = crema;
  static const logoCircleBorder = negro;

  // Aliases para compatibilidad con código existente
  static const cyan = azul;
  static const purple = rosa;
  static const magenta = rosa;
  static const logoOrange = naranja;
  static const logoCyan = azul;
  static const logoPurple = rosa;
  static const logoPink = rosa;
  static const logoYellow = amarillo;
  static const cream = crema;

  // Gradiente principal (alias)
  static const primaryGradient = headerGradient;
}

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: SubliriumColors.rosa,
        primary: SubliriumColors.rosa,
        secondary: SubliriumColors.azul,
        tertiary: SubliriumColors.naranja,
        brightness: Brightness.light,
        surface: SubliriumColors.cardBackground,
        background: SubliriumColors.background,
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
        backgroundColor: SubliriumColors.rosa,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SubliriumColors.rosa,
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
          borderSide: const BorderSide(color: SubliriumColors.azul, width: 2),
        ),
        labelStyle: const TextStyle(color: SubliriumColors.negro),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: SubliriumColors.negro),
        bodyMedium: TextStyle(color: SubliriumColors.negro),
        bodySmall: TextStyle(color: SubliriumColors.negro),
        titleLarge: TextStyle(
          color: SubliriumColors.negro,
          fontWeight: FontWeight.w900,
        ),
        titleMedium: TextStyle(
          color: SubliriumColors.negro,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: TextStyle(
          color: SubliriumColors.negro,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: SubliriumColors.rosa,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
