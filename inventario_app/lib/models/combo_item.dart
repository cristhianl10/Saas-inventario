class ComboItem {
  final int? id;
  final int comboId;
  final int productoId;
  final int cantidad;
  final String? nombreProducto;

  ComboItem({
    this.id,
    required this.comboId,
    required this.productoId,
    required this.cantidad,
    this.nombreProducto,
  });

  factory ComboItem.fromJson(Map<String, dynamic> json) {
    return ComboItem(
      id: json['id'] as int?,
      comboId: json['combo_id'] as int,
      productoId: json['producto_id'] as int,
      cantidad: json['cantidad'] as int,
      nombreProducto: json['nombre_producto'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'combo_id': comboId,
      'producto_id': productoId,
      'cantidad': cantidad,
    };
  }

  ComboItem copyWith({
    int? id,
    int? comboId,
    int? productoId,
    int? cantidad,
    String? nombreProducto,
  }) {
    return ComboItem(
      id: id ?? this.id,
      comboId: comboId ?? this.comboId,
      productoId: productoId ?? this.productoId,
      cantidad: cantidad ?? this.cantidad,
      nombreProducto: nombreProducto ?? this.nombreProducto,
    );
  }
}
