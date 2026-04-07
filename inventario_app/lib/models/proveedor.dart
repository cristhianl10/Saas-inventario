class Proveedor {
  final int? id;
  final String nombre;
  final String? telefono;
  final int version;

  Proveedor({this.id, required this.nombre, this.telefono, this.version = 1});

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      if (telefono != null) 'telefono': telefono,
      'version': version,
    };
  }

  Proveedor copyWith({
    int? id,
    String? nombre,
    String? telefono,
    int? version,
  }) {
    return Proveedor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      version: version ?? this.version,
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
