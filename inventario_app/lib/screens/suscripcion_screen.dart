import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/subscription_service.dart';
import 'planes_screen.dart';

class SuscripcionScreen extends StatefulWidget {
  const SuscripcionScreen({super.key});

  @override
  State<SuscripcionScreen> createState() => _SuscripcionScreenState();
}

class _SuscripcionScreenState extends State<SuscripcionScreen> {
  Map<String, dynamic>? _subscription;
  Map<String, dynamic>? _userPlan;
  bool _isLoading = true;
  bool _isCanceling = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final subscription = await SubscriptionService.getSubscription();
    final userPlan = await SubscriptionService.getCurrentPlan();

    if (mounted) {
      setState(() {
        _subscription = subscription;
        _userPlan = userPlan;
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Cancelar Suscripción'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Estás seguro de que quieres cancelar tu suscripción?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Regresarás al plan Gratis. Podrás seguir usando la app con las funciones limitadas.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, mantener'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCanceling = true);

    final success = await SubscriptionService.cancelSubscription();

    if (mounted) {
      setState(() => _isCanceling = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suscripción cancelada. Has vuelto al plan Gratis.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cancelar. Intenta más tarde.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Plan'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCurrentPlanCard(),
                    const SizedBox(height: 16),
                    _buildSubscriptionDetails(),
                    const SizedBox(height: 16),
                    _buildPlanFeatures(),
                    const SizedBox(height: 24),
                    if (_subscription?['status'] == 'active')
                      _buildCancelButton(),
                    const SizedBox(height: 16),
                    _buildChangePlanButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPlanCard() {
    final planName = _userPlan?['plan'] ?? 'gratis';
    final isActive = _userPlan?['plan_active'] ?? true;
    final status = _subscription?['status'] ?? 'active';

    Color statusColor;
    String statusText;

    if (planName == 'gratis') {
      statusColor = Colors.grey;
      statusText = 'Plan Gratuito';
    } else if (status == 'active' && isActive) {
      statusColor = Colors.green;
      statusText = 'Plan Activo';
    } else if (status == 'canceled') {
      statusColor = Colors.orange;
      statusText = 'Cancelado';
    } else if (status == 'expired') {
      statusColor = Colors.red;
      statusText = 'Expirado';
    } else {
      statusColor = Colors.grey;
      statusText = 'Activo';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConfig.primaryColor,
            AppConfig.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConfig.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                SubscriptionService.planNames[planName] ?? 'Gratis',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            SubscriptionService.getPlanPrice(planName),
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          if (planName != 'gratis' && _subscription?['expires_at'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Renovación: ${SubscriptionService.formatDate(DateTime.tryParse(_subscription!['expires_at'] ?? ''))}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetails() {
    if (_subscription == null && (_userPlan?['plan'] ?? 'gratis') == 'gratis') {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles de la Suscripción',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Estado',
              SubscriptionService.getStatusLabel(_subscription?['status']),
              _getStatusIcon(_subscription?['status']),
            ),
            if (_subscription?['started_at'] != null) ...[
              const Divider(),
              _buildDetailRow(
                'Inicio',
                SubscriptionService.formatDate(
                  DateTime.tryParse(_subscription!['started_at'] ?? ''),
                ),
                Icons.play_arrow,
              ),
            ],
            if (_subscription?['expires_at'] != null) ...[
              const Divider(),
              _buildDetailRow(
                'Próxima renovación',
                SubscriptionService.formatDate(
                  DateTime.tryParse(_subscription!['expires_at'] ?? ''),
                ),
                Icons.event,
              ),
            ],
            if (_subscription?['canceled_at'] != null) ...[
              const Divider(),
              _buildDetailRow(
                'Cancelado el',
                SubscriptionService.formatDate(
                  DateTime.tryParse(_subscription!['canceled_at'] ?? ''),
                ),
                Icons.cancel,
                color: Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'active':
        return Icons.check_circle;
      case 'canceled':
        return Icons.cancel;
      case 'expired':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Widget _buildPlanFeatures() {
    final planName = _userPlan?['plan'] ?? 'gratis';
    final features = SubscriptionService.planFeatures[planName] ?? [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Características de tu Plan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return OutlinedButton.icon(
      onPressed: _isCanceling ? null : _cancelSubscription,
      icon: _isCanceling
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.cancel_outlined),
      label: Text(_isCanceling ? 'Cancelando...' : 'Cancelar Suscripción'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildChangePlanButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlanesScreen()),
        );
      },
      icon: const Icon(Icons.swap_horiz),
      label: const Text('Cambiar de Plan'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
