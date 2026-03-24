class Producto {
  final int? id;
  final int categoriaId;
  final String nombre;
  final String? descripcion;
  final int cantidad;
  final double? precio;
  final int? proveedorId;
  final double? costo;
  final DateTime? fechaActualizacion;

  Producto({
    this.id,
    required this.categoriaId,
    required this.nombre,
    this.descripcion,
    required this.cantidad,
    this.precio,
    this.proveedorId,
    this.costo,
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
      proveedorId: json['proveedor_id'] as int?,
      costo: json['costo'] != null ? (json['costo'] as num).toDouble() : null,
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
      'proveedor_id': proveedorId,
      'costo': costo,
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
    int? proveedorId,
    double? costo,
    DateTime? fechaActualizacion,
  }) {
    return Producto(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      cantidad: cantidad ?? this.cantidad,
      precio: precio ?? this.precio,
      proveedorId: proveedorId ?? this.proveedorId,
      costo: costo ?? this.costo,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Producto && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
