import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Muestra un diálogo tipo messagebox para mensajes de éxito, error o información
/// Reemplaza el uso de SnackBar para mensajes importantes
Future<void> showMessageDialog({
  required BuildContext context,
  required String title,
  required String message,
  MessageType type = MessageType.info,
  String? buttonText,
  VoidCallback? onButtonPressed,
  bool barrierDismissible = true,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  final colors = _getMessageColors(type);
  
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      icon: Icon(
        colors.icon,
        color: colors.iconColor,
        size: 48,
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onButtonPressed?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(buttonText ?? 'Aceptar'),
          ),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    ),
  );
}

/// Muestra un diálogo de confirmación con opciones Sí/No
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Sí',
  String cancelText = 'No',
  bool isDangerous = false,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      content: Text(
        message,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDangerous ? Colors.red : SubliriumColors.cyan,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  
  return result ?? false;
}

MessageColors _getMessageColors(MessageType type) {
  switch (type) {
    case MessageType.success:
      return MessageColors(
        icon: Icons.check_circle_outline,
        iconColor: SubliriumColors.stockOkText,
        buttonColor: SubliriumColors.stockOkText,
      );
    case MessageType.error:
      return MessageColors(
        icon: Icons.error_outline,
        iconColor: Colors.red,
        buttonColor: Colors.red,
      );
    case MessageType.warning:
      return MessageColors(
        icon: Icons.warning_amber,
        iconColor: Colors.orange,
        buttonColor: Colors.orange,
      );
    case MessageType.info:
    default:
      return MessageColors(
        icon: Icons.info_outline,
        iconColor: SubliriumColors.cyan,
        buttonColor: SubliriumColors.cyan,
      );
  }
}

enum MessageType {
  success,
  error,
  warning,
  info,
}

class MessageColors {
  final IconData icon;
  final Color iconColor;
  final Color buttonColor;

  MessageColors({
    required this.icon,
    required this.iconColor,
    required this.buttonColor,
  });
}
