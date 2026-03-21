class PrecioTarifa {
  final int? id;
  final int productoId;
  final int cantidadMin;
  final int? cantidadMax;
  final double precioUnitario;
  final DateTime? fechaCreacion;

  PrecioTarifa({
    this.id,
    required this.productoId,
    required this.cantidadMin,
    this.cantidadMax,
    required this.precioUnitario,
    this.fechaCreacion,
  });

  factory PrecioTarifa.fromJson(Map<String, dynamic> json) {
    return PrecioTarifa(
      id: json['id'] as int?,
      productoId: json['producto_id'] as int,
      cantidadMin: json['cantidad_min'] as int,
      cantidadMax: json['cantidad_max'] as int?,
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'producto_id': productoId,
      'cantidad_min': cantidadMin,
      if (cantidadMax != null) 'cantidad_max': cantidadMax,
      'precio_unitario': precioUnitario,
    };
  }

  PrecioTarifa copyWith({
    int? id,
    int? productoId,
    int? cantidadMin,
    int? cantidadMax,
    double? precioUnitario,
    DateTime? fechaCreacion,
  }) {
    return PrecioTarifa(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      cantidadMin: cantidadMin ?? this.cantidadMin,
      cantidadMax: cantidadMax ?? this.cantidadMax,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  bool get esIlimitado => cantidadMax == null;

  String get rangoCantidad {
    if (esIlimitado) {
      return 'Más de ${cantidadMin - 1}';
    }
    return '$cantidadMin - $cantidadMax';
  }
}
