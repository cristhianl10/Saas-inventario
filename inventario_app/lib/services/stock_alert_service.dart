import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class StockAlertService {
  static const _enabledSuffix = 'stock_alerts_enabled';
  static const _thresholdSuffix = 'stock_alerts_threshold';
  static const _itemsSuffix = 'stock_alerts_items';
  static const _seenSuffix = 'stock_alerts_seen';

  static String _key(String userId, String suffix) => '${userId}_$suffix';

  static Future<bool> isEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(userId, _enabledSuffix)) ?? true;
  }

  static Future<int> getThreshold(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(userId, _thresholdSuffix)) ?? 5;
  }

  static Future<void> saveSettings({
    required String userId,
    required bool enabled,
    required int threshold,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(userId, _enabledSuffix), enabled);
    await prefs.setInt(_key(userId, _thresholdSuffix), threshold);
  }

  static Future<List<StockAlert>> syncAlerts({
    required String userId,
    required List<Producto> products,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = await isEnabled(userId);
    if (!enabled) return getAlerts(userId);

    final threshold = await getThreshold(userId);
    final items = getAlerts(userId);
    final seenIds = prefs.getStringList(_key(userId, _seenSuffix)) ?? [];
    final existingByProduct = {for (final item in items) item.productId: item};
    final now = DateTime.now();

    final lowStock = products.where((product) => product.cantidad <= threshold).toList();
    final generated = lowStock.map((product) {
      final existing = existingByProduct[product.id];
      return StockAlert(
        id: existing?.id ?? '${product.id}-${now.millisecondsSinceEpoch}',
        productId: product.id ?? 0,
        productName: product.nombre,
        quantity: product.cantidad,
        createdAt: existing?.createdAt ?? now,
        acknowledged: seenIds.contains(existing?.id),
      );
    }).toList();

    final persisted = generated.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_key(userId, _itemsSuffix), persisted);
    return generated;
  }

  static Future<List<StockAlert>> getAlerts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_key(userId, _itemsSuffix)) ?? [];
    return rawItems
        .map((item) => StockAlert.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<int> getUnreadCount(String userId) async {
    final alerts = await getAlerts(userId);
    return alerts.where((item) => !item.acknowledged).length;
  }

  static Future<void> markAllAsRead(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await getAlerts(userId);
    final ids = alerts.map((item) => item.id).toList();
    await prefs.setStringList(_key(userId, _seenSuffix), ids);
    await prefs.setStringList(
      _key(userId, _itemsSuffix),
      alerts.map((item) => jsonEncode(item.copyWith(acknowledged: true).toJson())).toList(),
    );
  }
}
