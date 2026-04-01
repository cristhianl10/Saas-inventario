class Combo {
  final int? id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final bool activo;
  final DateTime? fechaCreacion;
  final List<ComboItem> items;

  Combo({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.activo = true,
    this.fechaCreacion,
    this.items = const [],
  });

  factory Combo.fromJson(Map<String, dynamic> json) {
    return Combo(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      precio: (json['precio'] as num).toDouble(),
      activo: json['activo'] as bool? ?? true,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'] as String)
          : null,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => ComboItem.fromJson(i as Map<String, dynamic>)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      'precio': precio,
      'activo': activo,
    };
  }

  Combo copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    double? precio,
    bool? activo,
    DateTime? fechaCreacion,
    List<ComboItem>? items,
  }) {
    return Combo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      items: items ?? this.items,
    );
  }

  double get precioOriginal {
    return items.fold(0, (sum, item) {
      // Asumiendo que el precio original es el precio del producto * cantidad
      // Esto se calculará cuando tengamos los datos del producto
      return sum;
    });
  }

  double get ahorroPorcentaje {
    if (precioOriginal <= 0) return 0;
    return ((precioOriginal - precio) / precioOriginal * 100).clamp(0, 100);
  }
}

class ComboItem {
  final int? id;
  final int comboId;
  final int productoId;
  final int cantidad;
  final String? nombreProducto;
  final double? precioUnitario;

  ComboItem({
    this.id,
    required this.comboId,
    required this.productoId,
    required this.cantidad,
    this.nombreProducto,
    this.precioUnitario,
  });

  factory ComboItem.fromJson(Map<String, dynamic> json) {
    return ComboItem(
      id: json['id'] as int?,
      comboId: json['combo_id'] as int,
      productoId: json['producto_id'] as int,
      cantidad: json['cantidad'] as int,
      nombreProducto: json['nombre_producto'] as String?,
      precioUnitario: json['precio_unitario'] != null
          ? (json['precio_unitario'] as num).toDouble()
          : null,
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
    double? precioUnitario,
  }) {
    return ComboItem(
      id: id ?? this.id,
      comboId: comboId ?? this.comboId,
      productoId: productoId ?? this.productoId,
      cantidad: cantidad ?? this.cantidad,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      precioUnitario: precioUnitario ?? this.precioUnitario,
    );
  }

  double get total {
    return (precioUnitario ?? 0) * cantidad;
  }
}
