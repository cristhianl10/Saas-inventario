class Producto {
  final int? id;
  final int categoriaId;
  final String nombre;
  final String? descripcion;
  final int cantidad;
  final DateTime? fechaActualizacion;

  Producto({
    this.id,
    required this.categoriaId,
    required this.nombre,
    this.descripcion,
    required this.cantidad,
    this.fechaActualizacion,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int?,
      categoriaId: json['categoria_id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      cantidad: json['cantidad'] as int,
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
      'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  Producto copyWith({
    int? id,
    int? categoriaId,
    String? nombre,
    String? descripcion,
    int? cantidad,
    DateTime? fechaActualizacion,
  }) {
    return Producto(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      cantidad: cantidad ?? this.cantidad,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
