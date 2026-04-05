import '../config/tenant_service.dart';
import '../models/models.dart';

class SupplierInsightsService {
  static const _profilesKey = 'supplier_profiles';
  static const _ordersKey = 'purchase_orders';

  static List<SupplierProfile> getProfiles() {
    final raw = TenantService.currentConfig[_profilesKey];
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => SupplierProfile.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static SupplierProfile? getProfileFor(int providerId) {
    return getProfiles()
        .where((profile) => profile.providerId == providerId)
        .firstOrNull;
  }

  static Future<void> saveProfile(SupplierProfile profile) async {
    final profiles = getProfiles();
    final nextProfiles = [
      ...profiles.where((item) => item.providerId != profile.providerId),
      profile,
    ];

    await TenantService.mergeTenantConfig({
      _profilesKey: nextProfiles.map((item) => item.toJson()).toList(),
    });
  }

  static List<PurchaseOrder> getOrders() {
    final raw = TenantService.currentConfig[_ordersKey];
    if (raw is! List) return [];

    final orders = raw
        .whereType<Map>()
        .map((item) => PurchaseOrder.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  static List<PurchaseOrder> getOrdersFor(int providerId) {
    return getOrders().where((order) => order.providerId == providerId).toList();
  }

  static Future<void> saveOrder(PurchaseOrder order) async {
    final orders = getOrders();
    final nextOrders = [
      ...orders.where((item) => item.id != order.id),
      order,
    ];

    await TenantService.mergeTenantConfig({
      _ordersKey: nextOrders.map((item) => item.toJson()).toList(),
    });
  }

  static Future<void> updateOrderStatus(
    String orderId,
    PurchaseOrderStatus status,
  ) async {
    final orders = getOrders()
        .map((order) => order.id == orderId ? order.copyWith(status: status) : order)
        .toList();

    await TenantService.mergeTenantConfig({
      _ordersKey: orders.map((item) => item.toJson()).toList(),
    });
  }
}
