import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionService {
  static const String planGratis = 'gratis';
  static const String planBasico = 'basico';
  static const String planPro = 'pro';

  static const Map<String, int> planPrices = {
    planGratis: 0,
    planBasico: 900,
    planPro: 1900,
  };

  static const Map<String, String> planNames = {
    planGratis: 'Gratis',
    planBasico: 'Básico',
    planPro: 'Pro',
  };

  static const Map<String, List<String>> planFeatures = {
    planGratis: [
      'Hasta 30 productos',
      'Registro de ventas',
      'Dashboard básico',
    ],
    planBasico: [
      'Productos ilimitados',
      'Combos',
      'Precios por volumen',
      'Exportar PDF',
      'Gestión de proveedores',
    ],
    planPro: [
      'Todo lo de Básico',
      'Configuración de marca',
      'Soporte prioritario',
      'IA: análisis de stock (próximo)',
      'Reportes históricos (próximo)',
    ],
  };

  static const Map<String, int> planProductsLimit = {
    planGratis: 30,
    planBasico: -1,
    planPro: -1,
  };

  static Future<Map<String, dynamic>?> getCurrentPlan() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await Supabase.instance.client
          .from('users')
          .select('plan, plan_active, plan_expires_at')
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  static Future<String> getCurrentPlanName() async {
    final plan = await getCurrentPlan();
    if (plan == null) return planGratis;
    return plan['plan'] as String? ?? planGratis;
  }

  static Future<bool> isPlanActive() async {
    final plan = await getCurrentPlan();
    if (plan == null) return true;
    return plan['plan_active'] as bool? ?? true;
  }

  static Future<bool> hasFeature(String feature) async {
    final planName = await getCurrentPlanName();

    const proFeatures = ['brand_config', 'ai_analysis', 'historical_reports'];

    const basicoFeatures = [
      'unlimited_products',
      'combos',
      'volume_pricing',
      'pdf_export',
      'suppliers',
    ];

    if (proFeatures.contains(feature)) {
      return planName == planPro;
    }

    if (basicoFeatures.contains(feature)) {
      return planName == planBasico || planName == planPro;
    }

    return false;
  }

  static Future<int> getProductLimit() async {
    final planName = await getCurrentPlanName();
    return planProductsLimit[planName] ?? -1;
  }

  static Future<bool> canAddMoreProducts(int currentCount) async {
    final limit = await getProductLimit();
    if (limit == -1) return true;
    return currentCount < limit;
  }

  static Future<Map<String, dynamic>?> initiatePayment(String plan) async {
    if (plan == planGratis) {
      return {'isFree': true};
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final response = await Supabase.instance.client.functions.invoke(
        'payphone-payment',
        body: {'plan': plan, 'userId': user.id, 'userEmail': user.email},
      );

      if (response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> openPaymentUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (e) {
      return false;
    }
  }

  static Future<void> refreshPlan() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('users')
          .select('plan, plan_active, plan_expires_at')
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      // Ignore
    }
  }
}
