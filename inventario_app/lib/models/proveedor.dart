class Proveedor {
  final int? id;
  final String nombre;
  final String? telefono;

  Proveedor({
    this.id,
    required this.nombre,
    this.telefono,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      if (telefono != null) 'telefono': telefono,
    };
  }

  Proveedor copyWith({
    int? id,
    String? nombre,
    String? telefono,
  }) {
    return Proveedor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Proveedor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
