class Producto {
  final int? id;
  final int categoriaId;
  final String nombre;
  final String? descripcion;
  final int cantidad;
  final double? precio;
  final bool vendido;
  final double? precioVenta;
  final DateTime? fechaVenta;
  final String? vendidoA;
  final DateTime? fechaActualizacion;

  Producto({
    this.id,
    required this.categoriaId,
    required this.nombre,
    this.descripcion,
    required this.cantidad,
    this.precio,
    this.vendido = false,
    this.precioVenta,
    this.fechaVenta,
    this.vendidoA,
    this.fechaActualizacion,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int?,
      categoriaId: json['categoria_id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      cantidad: json['cantidad'] as int? ?? 0,
      precio: json['precio'] != null ? (json['precio'] as num).toDouble() : null,
      vendido: json['vendido'] as bool? ?? false,
      precioVenta: json['precio_venta'] != null ? (json['precio_venta'] as num).toDouble() : null,
      fechaVenta: json['fecha_venta'] != null ? DateTime.parse(json['fecha_venta'] as String) : null,
      vendidoA: json['vendido_a'] as String?,
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.parse(json['fecha_actualizacion'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'categoria_id': categoriaId,
      'nombre': nombre,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'precio': precio,
      'vendido': vendido,
      'precio_venta': precioVenta,
      'fecha_venta': fechaVenta?.toIso8601String(),
      'vendido_a': vendidoA,
      'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  Producto copyWith({
    int? id,
    int? categoriaId,
    String? nombre,
    String? descripcion,
    int? cantidad,
    double? precio,
    bool? vendido,
    double? precioVenta,
    DateTime? fechaVenta,
    String? vendidoA,
    DateTime? fechaActualizacion,
  }) {
    return Producto(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      cantidad: cantidad ?? this.cantidad,
      precio: precio ?? this.precio,
      vendido: vendido ?? this.vendido,
      precioVenta: precioVenta ?? this.precioVenta,
      fechaVenta: fechaVenta ?? this.fechaVenta,
      vendidoA: vendidoA ?? this.vendidoA,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
