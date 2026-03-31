import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';

class TenantService {
  static String? _currentTenantId;
  static Map<String, dynamic>? _tenantConfig;
  
  static String? get currentTenantId => _currentTenantId;
  static bool get isConfigured => _tenantConfig != null;
  
  static Future<void> initialize() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await loadTenantConfig(user.id);
    }
  }
  
  static Future<void> loadTenantConfig(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('tenant_config')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response != null) {
        _currentTenantId = response['id']?.toString();
        
        // Extraer el config del response
        final configData = response['config'];
        if (configData != null) {
          if (configData is Map) {
            _tenantConfig = Map<String, dynamic>.from(configData);
          } else if (configData is String) {
            // Si viene como string JSON, parsear
            try {
              _tenantConfig = Map<String, dynamic>.from(
                (configData as dynamic)
              );
            } catch (_) {}
          }
          
          if (_tenantConfig != null) {
            AppConfig.loadFromMap(_tenantConfig!);
          }
        }
      } else {
        _loadDefaultConfig();
      }
    } catch (e) {
      _loadDefaultConfig();
    }
  }
  
  static void _loadDefaultConfig() {
    AppConfig.appName = 'StockFlow';
    AppConfig.brandName = 'Mi Negocio';
    AppConfig.logoPath = 'assets/logos/logo_default.png';
    AppConfig.primaryColorHex = '#C1356F';
    AppConfig.secondaryColorHex = '#597FA9';
    AppConfig.accentColorHex = '#E57836';
    AppConfig.backgroundColorHex = '#FBF8F1';
  }
  
  static Future<void> saveTenantConfig(Map<String, dynamic> config) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    try {
      final existing = await Supabase.instance.client
          .from('tenant_config')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (existing != null) {
        await Supabase.instance.client
            .from('tenant_config')
            .update({'config': config})
            .eq('user_id', user.id);
      } else {
        await Supabase.instance.client
            .from('tenant_config')
            .insert({
              'user_id': user.id,
              'config': config,
            });
      }
      
      _tenantConfig = config;
      AppConfig.loadFromMap(config);
    } catch (e) {
      _tenantConfig = config;
      AppConfig.loadFromMap(config);
    }
  }
  
  static void clearTenant() {
    _currentTenantId = null;
    _tenantConfig = null;
    _loadDefaultConfig();
  }
}
