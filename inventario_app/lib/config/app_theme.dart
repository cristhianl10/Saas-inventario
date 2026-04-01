import 'package:flutter/material.dart';
import 'app_config.dart';

import 'package:google_fonts/google_fonts.dart';

class SubliriumColors {
  static Color get rosa => AppConfig.primaryColor;
  static Color get azul => AppConfig.secondaryColor;
  static Color get naranja => AppConfig.accentColor;
  static Color get crema => AppConfig.backgroundColor;

  static const negro = Color(0xFF1C1C18); // Premium dark instead of pure black
  static const amarillo = Color(0xFFF9C706);

  static LinearGradient get headerGradient => LinearGradient(
    colors: [azul, rosa],
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

  static Color get background => AppConfig.backgroundColor; // Tonal paper-like background based on brand config
  static const cardBackground = Color(0xFFFFFFFF); // Clean white for cards

  static const textPrimary = negro;
  static const textSecondary = Color(0xFF574147); // Softer text for secondary info

  static const border = Color(0xFFE5E2DB); // Very subtle border

  static const stockOkBg = Color(0xFFEFFBF3);
  static const stockOkText = Color(0xFF0F8C3B);
  static const stockLowBg = Color(0xFFFFF0F2);
  static const stockLowText = Color(0xFFD31842);
  static const stockZeroBg = Color(0xFFF6F3EC);
  static const stockZeroText = Color(0xFF8A7077);

  static const pendingBg = Color(0xFFFFFBEB);
  static const pendingBorder = Color(0xFFFDE68A);
  static const pendingText = Color(0xFF92400E);

  static const backButton = Color(0xFF597FA9);
  static const deleteBorder = Color(0xFFFECDD3);
  static const deleteText = Color(0xFFE11D48);
  static const inputFocusedBorder = Color(0xFFC1356F); // Primary
  static const inputFocusedBg = Color(0xFFFFFFFF);
  static const cancelBg = Color(0xFFF6F3EC);
  static const cancelText = Color(0xFF574147);

  static const logoCircleBg = Color(0xFFFCF9F2);
  static const logoCircleBorder = Color(0xFF1C1C18);

  static const cyan = Color(0xFF597FA9);
  static const purple = Color(0xFFC1356F);
  static const magenta = Color(0xFFC1356F);
  static const logoOrange = Color(0xFFE57836);
  static const logoCyan = Color(0xFF597FA9);
  static const logoPurple = Color(0xFFC1356F);
  static const logoPink = Color(0xFFC1356F);
  static const logoYellow = Color(0xFFF9C706);
  static const cream = Color(0xFFFCF9F2);

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
    final baseTextTheme = GoogleFonts.interTextTheme();
    final displayFont = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConfig.primaryColor,
        primary: AppConfig.primaryColor,
        secondary: AppConfig.secondaryColor,
        tertiary: AppConfig.accentColor,
        brightness: Brightness.light,
        surface: SubliriumColors.background,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: SubliriumColors.background,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: SubliriumColors.textPrimary,
        titleTextStyle: displayFont.titleLarge?.copyWith(
          color: SubliriumColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: SubliriumColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: SubliriumColors.cardBackground,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConfig.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0EEE7), // surface_container
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Removes explicitly bold borders for text fields
        ),
        labelStyle: GoogleFonts.inter(color: SubliriumColors.textSecondary),
        hintStyle: GoogleFonts.inter(color: SubliriumColors.border),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: displayFont.displayLarge?.copyWith(color: SubliriumColors.textPrimary),
        displayMedium: displayFont.displayMedium?.copyWith(color: SubliriumColors.textPrimary),
        displaySmall: displayFont.displaySmall?.copyWith(color: SubliriumColors.textPrimary),
        headlineLarge: displayFont.headlineLarge?.copyWith(color: SubliriumColors.textPrimary),
        headlineMedium: displayFont.headlineMedium?.copyWith(color: SubliriumColors.textPrimary),
        headlineSmall: displayFont.headlineSmall?.copyWith(color: SubliriumColors.textPrimary),
        titleLarge: displayFont.titleLarge?.copyWith(color: SubliriumColors.textPrimary, fontWeight: FontWeight.bold),
        titleMedium: displayFont.titleMedium?.copyWith(color: SubliriumColors.textPrimary, fontWeight: FontWeight.w600),
        titleSmall: displayFont.titleSmall?.copyWith(color: SubliriumColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: SubliriumColors.textPrimary),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: SubliriumColors.textPrimary),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: SubliriumColors.textSecondary),
      ),
      iconTheme: const IconThemeData(color: SubliriumColors.textPrimary, size: 24),
    );
  }

  static ThemeData darkTheme() {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    final displayFont = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);
    const darkBg = Color(0xFF0F0F0F);   // Near-black background
    const darkSurface = Color(0xFF1A1A1A); // Dark surface for cards
    const darkCard = Color(0xFF242424);  // Slightly lighter for cards

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConfig.primaryColor,
        primary: AppConfig.primaryColor,
        secondary: AppConfig.secondaryColor,
        tertiary: AppConfig.accentColor,
        brightness: Brightness.dark,
        surface: darkBg,
        onSurface: Colors.white,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkCard,
      canvasColor: darkSurface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkBg,
        foregroundColor: Colors.white,
        titleTextStyle: displayFont.titleLarge?.copyWith(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCard,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConfig.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC1356F), width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: Colors.white60),
        hintStyle: GoogleFonts.inter(color: Colors.white38),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: displayFont.displayLarge?.copyWith(color: Colors.white),
        displayMedium: displayFont.displayMedium?.copyWith(color: Colors.white),
        displaySmall: displayFont.displaySmall?.copyWith(color: Colors.white),
        headlineLarge: displayFont.headlineLarge?.copyWith(color: Colors.white),
        headlineMedium: displayFont.headlineMedium?.copyWith(color: Colors.white),
        headlineSmall: displayFont.headlineSmall?.copyWith(color: Colors.white),
        titleLarge: displayFont.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        titleMedium: displayFont.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        titleSmall: displayFont.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: Colors.white),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: Colors.white),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: Colors.white70),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: Colors.white60),
        labelSmall: baseTextTheme.labelSmall?.copyWith(color: Colors.white60),
      ),
      iconTheme: const IconThemeData(color: Colors.white, size: 24),
      dividerColor: Colors.white12,
      popupMenuTheme: const PopupMenuThemeData(color: Color(0xFF2A2A2A)),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1A1A1A)),
    );
  }
}
