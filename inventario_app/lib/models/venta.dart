class Venta {
  final int? id;
  final int productoId;
  final int cantidad;
  final double precioUnitario;
  final double total;
  final DateTime fechaVenta;
  final int? clienteId;
  final String? vendidoA;
  final String? observaciones;

  Venta({
    this.id,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
    required this.fechaVenta,
    this.clienteId,
    this.vendidoA,
    this.observaciones,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id'] as int?,
      productoId: (json['producto_id'] as num?)?.toInt() ?? 0,
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      precioUnitario: (json['precio_unitario'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      fechaVenta: json['fecha_venta'] != null
          ? DateTime.parse(json['fecha_venta'] as String)
          : DateTime.now(),
      clienteId: (json['cliente_id'] as num?)?.toInt(),
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
      if (clienteId != null) 'cliente_id': clienteId,
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
    int? clienteId,
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
      clienteId: clienteId ?? this.clienteId,
      vendidoA: vendidoA ?? this.vendidoA,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}
