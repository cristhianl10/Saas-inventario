import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/subscription_service.dart';

class PlanesScreen extends StatefulWidget {
  const PlanesScreen({super.key});

  @override
  State<PlanesScreen> createState() => _PlanesScreenState();
}

class _PlanesScreenState extends State<PlanesScreen> {
  String? _currentPlan;
  bool _isLoading = true;
  String? _processingPlan;

  @override
  void initState() {
    super.initState();
    _loadCurrentPlan();
  }

  Future<void> _loadCurrentPlan() async {
    final plan = await SubscriptionService.getCurrentPlanName();
    if (mounted) {
      setState(() {
        _currentPlan = plan;
        _isLoading = false;
      });
    }
  }

  Future<void> _subscribeToPlan(String plan) async {
    if (_currentPlan == plan) return;

    setState(() {
      _processingPlan = plan;
    });

    final result = await SubscriptionService.initiatePayment(plan);

    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar. Intenta más tarde.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _processingPlan = null;
      });
      return;
    }

    if (result['isFree'] == true) {
      await _loadCurrentPlan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan activado'),
            backgroundColor: Colors.green,
          ),
        );
      }
      setState(() {
        _processingPlan = null;
      });
      return;
    }

    final payphoneUrl = result['payphoneUrl'] as String?;
    bool launched = false;
    if (payphoneUrl != null && payphoneUrl.isNotEmpty) {
      launched = await SubscriptionService.openPaymentUrl(payphoneUrl);
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el pago. Intenta más tarde.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _processingPlan = null;
    });

    if (mounted && launched) {
      _showPaymentPendingDialog(plan);
    }
  }

  void _showPaymentPendingDialog(String plan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.access_time, color: Colors.orange),
            SizedBox(width: 8),
            Text('Pago en proceso'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu pago está siendo procesado. Una vez confirmado, tu plan se activará automáticamente.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cierra la app y vuelve a abrirla después de pagar.',
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
            onPressed: () {
              Navigator.pop(context);
              _loadCurrentPlan();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Planes')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Elige tu plan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona el plan que mejor se adapte a tu negocio',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildPlanCard(
              plan: 'gratis',
              name: 'Gratis',
              price: '\$0 /mes',
              description: 'Para probar sin riesgo',
              features: SubscriptionService.planFeatures['gratis']!,
              isCurrentPlan: _currentPlan == 'gratis',
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              plan: 'basico',
              name: 'Básico',
              price: '\$9 /mes',
              description: 'Para negocios en crecimiento',
              features: SubscriptionService.planFeatures['basico']!,
              isCurrentPlan: _currentPlan == 'basico',
              isPopular: true,
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              plan: 'pro',
              name: 'Pro',
              price: '\$19 /mes',
              description: 'Para negocios establecidos',
              features: SubscriptionService.planFeatures['pro']!,
              isCurrentPlan: _currentPlan == 'pro',
            ),
            const SizedBox(height: 32),
            _buildFaqSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String plan,
    required String name,
    required String price,
    required String description,
    required List<String> features,
    required bool isCurrentPlan,
    bool isPopular = false,
  }) {
    final isProcessing = _processingPlan == plan;
    final isDisabled = isCurrentPlan || _processingPlan != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? AppConfig.primaryColor : Colors.grey[300]!,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppConfig.primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: const Text(
                'Más popular',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isCurrentPlan)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Plan actual',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppConfig.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: isPopular
                              ? AppConfig.primaryColor
                              : Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(feature, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isDisabled ? null : () => _subscribeToPlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular
                          ? AppConfig.primaryColor
                          : Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isCurrentPlan
                                ? 'Plan actual'
                                : name == 'Gratis'
                                ? 'Usar gratis'
                                : 'Suscribirse',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preguntas frecuentes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFaqItem(
            '¿Puedo cambiar de plan?',
            'Sí, puedes cambiar de plan en cualquier momento desde esta pantalla.',
          ),
          _buildFaqItem(
            '¿Cómo funciona el pago?',
            'Usamos PayPhone para procesar pagos de forma segura. Puedes pagar con tarjeta, transferencia o billeteras digitales.',
          ),
          _buildFaqItem(
            '¿Se renueva automáticamente?',
            'Sí, tu suscripción se renueva mensualmente de forma automática.',
          ),
          _buildFaqItem(
            '¿Cómo cancelo?',
            'Puedes cancelar en cualquier momento desde la configuración de tu cuenta. Seguirás teniendo acceso hasta el final del período pagado.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(answer, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
