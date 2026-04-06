import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../config/app_config.dart';

class PdfHelper {
  static pw.MemoryImage? _logoImage;
  static bool _logoLoaded = false;

  static int _hexToRgb(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);
      return (r << 16) | (g << 8) | b;
    }
    return 0x666666;
  }

  static PdfColor get primaryColor {
    return PdfColor.fromInt(0xFF000000 | _hexToRgb(AppConfig.primaryColorHex));
  }

  static PdfColor get secondaryColor {
    return PdfColor.fromInt(
      0xFF000000 | _hexToRgb(AppConfig.secondaryColorHex),
    );
  }

  static PdfColor get accentColor {
    return PdfColor.fromInt(0xFF000000 | _hexToRgb(AppConfig.accentColorHex));
  }

  static PdfColor get primaryLight {
    return PdfColor.fromInt(0x1A000000 | _hexToRgb(AppConfig.primaryColorHex));
  }

  static PdfColor get primaryDark {
    return PdfColor.fromInt(0xCC000000 | _hexToRgb(AppConfig.primaryColorHex));
  }

  static Future<void> loadLogo() async {
    if (_logoLoaded) return;
    try {
      final bytes = await rootBundle.load(AppConfig.logoPath);
      _logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      _logoImage = null;
    }
    _logoLoaded = true;
  }

  static void resetLogo() {
    _logoImage = null;
    _logoLoaded = false;
  }

  static pw.Widget buildHeader({String? title, String? subtitle}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [primaryColor, secondaryColor, accentColor],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 50,
            height: 50,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.ClipOval(
                child: _logoImage != null
                    ? pw.Image(
                        _logoImage!,
                        width: 45,
                        height: 45,
                        fit: pw.BoxFit.cover,
                      )
                    : pw.Text(
                        AppConfig.brandName.isNotEmpty
                            ? AppConfig.brandName.substring(0, 1).toUpperCase()
                            : 'S',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
              ),
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title ?? AppConfig.brandName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    subtitle,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado por ${AppConfig.appName}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(colors: [primaryColor, secondaryColor]),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget buildTableHeader(List<String> columns) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: pw.BoxDecoration(color: primaryLight),
      child: pw.Row(
        children: columns
            .map(
              (col) => pw.Expanded(
                child: pw.Text(
                  col,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    color: primaryColor,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
