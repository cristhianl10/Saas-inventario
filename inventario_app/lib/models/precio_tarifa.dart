class PrecioTarifa {
  final int? id;
  final int productoId;
  final int cantidadMin;
  final int? cantidadMax;
  final double precioUnitario;
  final DateTime? fechaCreacion;
  final int version;

  PrecioTarifa({
    this.id,
    required this.productoId,
    required this.cantidadMin,
    this.cantidadMax,
    required this.precioUnitario,
    this.fechaCreacion,
    this.version = 1,
  });

  factory PrecioTarifa.fromJson(Map<String, dynamic> json) {
    return PrecioTarifa(
      id: json['id'] as int?,
      productoId: (json['producto_id'] as num?)?.toInt() ?? 0,
      cantidadMin: (json['cantidad_min'] as num?)?.toInt() ?? 0,
      cantidadMax: json['cantidad_max'] as int?,
      precioUnitario: (json['precio_unitario'] as num?)?.toDouble() ?? 0.0,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'] as String)
          : null,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'producto_id': productoId,
      'cantidad_min': cantidadMin,
      if (cantidadMax != null) 'cantidad_max': cantidadMax,
      'precio_unitario': precioUnitario,
      'version': version,
    };
  }

  PrecioTarifa copyWith({
    int? id,
    int? productoId,
    int? cantidadMin,
    int? cantidadMax,
    double? precioUnitario,
    DateTime? fechaCreacion,
    int? version,
  }) {
    return PrecioTarifa(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      cantidadMin: cantidadMin ?? this.cantidadMin,
      cantidadMax: cantidadMax ?? this.cantidadMax,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      version: version ?? this.version,
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
