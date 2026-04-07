class Producto {
  final int? id;
  final int categoriaId;
  final String nombre;
  final String? descripcion;
  final int cantidad;
  final double? precio;
  final int? proveedorId;
  final double? costo;
  final bool esCombo;
  final int? umbralAlerta;
  final DateTime? fechaActualizacion;
  final int version;

  Producto({
    this.id,
    required this.categoriaId,
    required this.nombre,
    this.descripcion,
    required this.cantidad,
    this.precio,
    this.proveedorId,
    this.costo,
    this.esCombo = false,
    this.umbralAlerta,
    this.fechaActualizacion,
    this.version = 1,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int?,
      categoriaId: (json['categoria_id'] as num?)?.toInt() ?? 0,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      precio: json['precio'] != null
          ? (json['precio'] as num?)?.toDouble() ?? 0.0
          : null,
      proveedorId: json['proveedor_id'] as int?,
      costo: json['costo'] != null
          ? (json['costo'] as num?)?.toDouble() ?? 0.0
          : null,
      esCombo: json['es_combo'] as bool? ?? false,
      umbralAlerta: json['umbral_alerta'] as int?,
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.parse(json['fecha_actualizacion'] as String)
          : null,
      version: (json['version'] as num?)?.toInt() ?? 1,
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
      'es_combo': esCombo,
      if (umbralAlerta != null) 'umbral_alerta': umbralAlerta,
      'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
      'version': version,
    };
  }

  bool get tieneStockBajo {
    if (umbralAlerta == null) return false;
    return cantidad <= umbralAlerta!;
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
    bool? esCombo,
    int? umbralAlerta,
    DateTime? fechaActualizacion,
    int? version,
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
      esCombo: esCombo ?? this.esCombo,
      umbralAlerta: umbralAlerta ?? this.umbralAlerta,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      version: version ?? this.version,
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
