class Venta {
  final int? id;
  final int productoId;
  final int cantidad;
  final double precioUnitario;
  final double total;
  final DateTime fechaVenta;
  final String? vendidoA;
  final String? observaciones;

  Venta({
    this.id,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
    required this.fechaVenta,
    this.vendidoA,
    this.observaciones,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id'] as int?,
      productoId: json['producto_id'] as int,
      cantidad: json['cantidad'] as int,
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      fechaVenta: DateTime.parse(json['fecha_venta'] as String),
      vendidoA: json['vendido_a'] as String?,
      observaciones: json['observaciones'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'total': total,
      'fecha_venta': fechaVenta.toIso8601String(),
      'vendido_a': vendidoA,
      'observaciones': observaciones,
    };
  }

  Venta copyWith({
    int? id,
    int? productoId,
    int? cantidad,
    double? precioUnitario,
    double? total,
    DateTime? fechaVenta,
    String? vendidoA,
    String? observaciones,
  }) {
    return Venta(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      total: total ?? this.total,
      fechaVenta: fechaVenta ?? this.fechaVenta,
      vendidoA: vendidoA ?? this.vendidoA,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}
