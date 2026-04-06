import 'package:flutter/material.dart';
import '../config/app_config.dart';

class PlanUpgradeHelper {
  static void showUpgradeDialog(
    BuildContext context,
    String feature, {
    String? planRequired,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: AppConfig.primaryColor),
            const SizedBox(width: 8),
            const Expanded(child: Text('Función Premium')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta función está disponible en el plan $planRequired.',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConfig.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppConfig.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upgrade tu plan para desbloquear $feature y más funciones.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPlans(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ver Planes'),
          ),
        ],
      ),
    );
  }

  static void showLimitReachedDialog(BuildContext context, String limit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Límite Alcanzado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Has alcanzado el límite de $limit.',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            const Text(
              'Upgrade tu plan para desbloquear más.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPlans(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ver Planes'),
          ),
        ],
      ),
    );
  }

  static Future<void> _navigateToPlans(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _PlanesPlaceholder()),
    );
  }
}

class _PlanesPlaceholder extends StatelessWidget {
  const _PlanesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planes')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium,
              size: 64,
              color: AppConfig.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text('Ve a Planes desde el menú'),
          ],
        ),
      ),
    );
  }
}
