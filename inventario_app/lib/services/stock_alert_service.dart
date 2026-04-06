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

  static Future<int> getDefaultThreshold(String userId) async {
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
    final defaultThreshold = await getDefaultThreshold(userId);

    if (!enabled) {
      return _getLocalAlerts(prefs, userId);
    }

    final items = await _getLocalAlerts(prefs, userId);
    final seenIds = prefs.getStringList(_key(userId, _seenSuffix)) ?? [];
    final existingByProduct = {for (final item in items) item.productId: item};
    final now = DateTime.now();

    final lowStock = products.where((product) {
      if (product.umbralAlerta != null) {
        return product.cantidad <= product.umbralAlerta!;
      }
      return product.cantidad <= defaultThreshold;
    }).toList();

    final generated = lowStock.map((product) {
      final existing = existingByProduct[product.id];
      return StockAlert(
        id: existing?.id ?? '${product.id}-${now.millisecondsSinceEpoch}',
        productId: product.id ?? 0,
        productName: product.nombre,
        quantity: product.cantidad,
        threshold: product.umbralAlerta ?? defaultThreshold,
        createdAt: existing?.createdAt ?? now,
        acknowledged: seenIds.contains(existing?.id),
      );
    }).toList();

    final persisted = generated
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList(_key(userId, _itemsSuffix), persisted);
    return generated;
  }

  static Future<List<StockAlert>> _getLocalAlerts(
    SharedPreferences prefs,
    String userId,
  ) async {
    final rawItems = prefs.getStringList(_key(userId, _itemsSuffix)) ?? [];
    return rawItems
        .map(
          (item) =>
              StockAlert.fromJson(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<List<StockAlert>> getAlerts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return _getLocalAlerts(prefs, userId);
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
      alerts
          .map((item) => jsonEncode(item.copyWith(acknowledged: true).toJson()))
          .toList(),
    );
  }

  static List<Producto> getProductosConStockBajo(
    List<Producto> productos, {
    int defaultThreshold = 5,
  }) {
    return productos.where((p) {
      if (p.umbralAlerta != null) {
        return p.cantidad <= p.umbralAlerta!;
      }
      return p.cantidad <= defaultThreshold;
    }).toList()..sort((a, b) => a.cantidad.compareTo(b.cantidad));
  }

  static int getCountProductosStockBajo(
    List<Producto> productos, {
    int defaultThreshold = 5,
  }) {
    return productos.where((p) {
      if (p.umbralAlerta != null) {
        return p.cantidad <= p.umbralAlerta!;
      }
      return p.cantidad <= defaultThreshold;
    }).length;
  }
}

class StockAlert {
  final String id;
  final int productId;
  final String productName;
  final int quantity;
  final int threshold;
  final DateTime createdAt;
  final bool acknowledged;

  StockAlert({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.threshold,
    required this.createdAt,
    required this.acknowledged,
  });

  factory StockAlert.fromJson(Map<String, dynamic> json) {
    return StockAlert(
      id: json['id'] as String,
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      threshold: json['threshold'] as int? ?? 5,
      createdAt: DateTime.parse(json['createdAt'] as String),
      acknowledged: json['acknowledged'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'threshold': threshold,
      'createdAt': createdAt.toIso8601String(),
      'acknowledged': acknowledged,
    };
  }

  StockAlert copyWith({
    String? id,
    int? productId,
    String? productName,
    int? quantity,
    int? threshold,
    DateTime? createdAt,
    bool? acknowledged,
  }) {
    return StockAlert(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      threshold: threshold ?? this.threshold,
      createdAt: createdAt ?? this.createdAt,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }

  String get mensaje {
    if (quantity == 0) {
      return '¡$productName está AGOTADO! (Umbral: $threshold)';
    }
    return '¡$productName tiene stock bajo! $quantity unidades (Umbral: $threshold)';
  }
}
