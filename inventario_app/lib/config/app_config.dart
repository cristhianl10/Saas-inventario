import 'package:flutter/material.dart';

class AppConfig {
  static String appName = 'StockFlow';
  static String logoPath = 'assets/logos/logo_default.png';
  static String brandName = 'Mi Negocio';
  
  static String primaryColorHex = '#C1356F';
  static String secondaryColorHex = '#597FA9';
  static String accentColorHex = '#E57836';
  static String backgroundColorHex = '#FBF8F1';
  
  static Color get primaryColor => _hexToColor(primaryColorHex);
  static Color get secondaryColor => _hexToColor(secondaryColorHex);
  static Color get accentColor => _hexToColor(accentColorHex);
  static Color get backgroundColor => _hexToColor(backgroundColorHex);
  
  static final ValueNotifier<int> configNotifier = ValueNotifier(0);
  
  static Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
  
  static void loadFromMap(Map<String, dynamic> config) {
    appName = config['app_name'] ?? 'StockFlow';
    logoPath = config['logo_path'] ?? 'assets/logos/logo_default.png';
    brandName = config['brand_name'] ?? 'Mi Negocio';
    primaryColorHex = config['primary_color'] ?? '#C1356F';
    secondaryColorHex = config['secondary_color'] ?? '#597FA9';
    accentColorHex = config['accent_color'] ?? '#E57836';
    backgroundColorHex = config['background_color'] ?? '#FBF8F1';
    configNotifier.value++;
  }
  
  static Map<String, dynamic> toMap() {
    return {
      'app_name': appName,
      'logo_path': logoPath,
      'brand_name': brandName,
      'primary_color': primaryColorHex,
      'secondary_color': secondaryColorHex,
      'accent_color': accentColorHex,
      'background_color': backgroundColorHex,
    };
  }

  /// Calcula la luminosidad relativa de un color (0-1)
  /// Usa la fórmula de luminosidad percibida:
  /// L = 0.299*R + 0.587*G + 0.114*B
  static double _getLuminance(Color color) {
    final r = color.r;
    final g = color.g;
    final b = color.b;
    return 0.299 * r + 0.587 * g + 0.114 * b;
  }

  /// Determina si el color es oscuro (requiere texto claro)
  /// Retorna true si el color es oscuro (luminosidad < 0.5)
  static bool isDarkColor(Color color) {
    return _getLuminance(color) < 0.5;
  }

  /// Retorna el color de texto apropiado para el contraste
  /// Blanco para fondos oscuros, negro para fondos claros
  static Color getContrastTextColor(Color backgroundColor) {
    return isDarkColor(backgroundColor) ? Colors.white : Colors.black;
  }

  /// Colores de texto de alto contraste para los colores principales de la app
  static Color get primaryContrastColor => getContrastTextColor(primaryColor);
  static Color get secondaryContrastColor => getContrastTextColor(secondaryColor);
  static Color get accentContrastColor => getContrastTextColor(accentColor);
}
