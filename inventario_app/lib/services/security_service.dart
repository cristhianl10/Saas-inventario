import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final List<String> _securityLog = [];
  static const int _maxLogEntries = 100;

  void logSecurityEvent(String event, {String? details}) {
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'event': event,
      'details': details,
    };
    _securityLog.add(jsonEncode(entry));
    if (_securityLog.length > _maxLogEntries) {
      _securityLog.removeAt(0);
    }
  }

  List<Map<String, dynamic>> getSecurityLogs() {
    return _securityLog
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    return input
        .trim()
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('\\', '')
        .replaceAll('/', '')
        .replaceAll('&', '')
        .replaceAll(';', '')
        .replaceAll('|', '')
        .replaceAll('\$', '')
        .replaceAll('`', '')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ');
  }

  String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String generateSecureToken(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool isStrongPassword(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) return false;
    return true;
  }

  String getPasswordStrength(String password) {
    if (password.isEmpty) return 'empty';
    if (password.length < 6) return 'weak';
    if (password.length < 8) return 'medium';
    if (!isStrongPassword(password)) return 'medium';

    int score = 0;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password))
      score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score >= 4) return 'strong';
    if (score >= 3) return 'good';
    return 'medium';
  }

  bool isSuspiciousInput(String input) {
    final suspiciousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'data:', caseSensitive: false),
      RegExp(r'eval\s*\(', caseSensitive: false),
      RegExp(r'expression\s*\(', caseSensitive: false),
    ];

    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(input)) return true;
    }
    return false;
  }

  Map<String, dynamic> validateAndSanitizeProductData(
    Map<String, dynamic> data,
  ) {
    final sanitized = <String, dynamic>{};

    if (data.containsKey('nombre')) {
      final nombre = data['nombre']?.toString() ?? '';
      if (isSuspiciousInput(nombre)) {
        logSecurityEvent('SUSPICIOUS_INPUT', details: 'nombre: $nombre');
        throw Exception('Entrada sospechosa detectada');
      }
      sanitized['nombre'] = sanitizeInput(nombre);
    }

    if (data.containsKey('descripcion')) {
      final descripcion = data['descripcion']?.toString() ?? '';
      if (isSuspiciousInput(descripcion)) {
        logSecurityEvent('SUSPICIOUS_INPUT', details: 'descripcion');
        throw Exception('Entrada sospechosa detectada');
      }
      sanitized['descripcion'] = sanitizeInput(descripcion);
    }

    if (data.containsKey('precio')) {
      final precio = double.tryParse(data['precio']?.toString() ?? '0') ?? 0;
      sanitized['precio'] = precio.abs();
    }

    if (data.containsKey('cantidad')) {
      final cantidad = int.tryParse(data['cantidad']?.toString() ?? '0') ?? 0;
      sanitized['cantidad'] = cantidad.abs();
    }

    return sanitized;
  }

  bool checkRateLimit(
    String key, {
    int maxAttempts = 5,
    Duration window = const Duration(minutes: 1),
  }) {
    final now = DateTime.now();
    final keyName = 'rate_$key';

    if (!_rateLimitStore.containsKey(keyName)) {
      _rateLimitStore[keyName] = <DateTime>[];
    }

    final attempts = _rateLimitStore[keyName]!;
    attempts.removeWhere((t) => now.difference(t) > window);

    if (attempts.length >= maxAttempts) {
      logSecurityEvent('RATE_LIMIT_EXCEEDED', details: key);
      return false;
    }

    attempts.add(now);
    return true;
  }

  final Map<String, List<DateTime>> _rateLimitStore = {};

  void clearRateLimit(String key) {
    _rateLimitStore.remove('rate_$key');
  }

  String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars) return '*' * data.length;
    final masked = '*' * (data.length - visibleChars);
    return masked + data.substring(data.length - visibleChars);
  }
}
