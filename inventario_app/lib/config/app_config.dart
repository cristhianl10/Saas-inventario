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
}
