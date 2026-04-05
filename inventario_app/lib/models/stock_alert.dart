class StockAlert {
  final String id;
  final int productId;
  final String productName;
  final int quantity;
  final DateTime createdAt;
  final bool acknowledged;

  StockAlert({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.createdAt,
    this.acknowledged = false,
  });

  factory StockAlert.fromJson(Map<String, dynamic> json) {
    return StockAlert(
      id: json['id'] as String? ?? '',
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      productName: json['product_name'] as String? ?? 'Producto',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      acknowledged: json['acknowledged'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'acknowledged': acknowledged,
    };
  }

  StockAlert copyWith({bool? acknowledged}) {
    return StockAlert(
      id: id,
      productId: productId,
      productName: productName,
      quantity: quantity,
      createdAt: createdAt,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }
}
