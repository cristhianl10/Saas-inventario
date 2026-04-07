class Categoria {
  final int? id;
  final String nombre;
  final int version;

  Categoria({this.id, required this.nombre, this.version = 1});

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {if (id != null) 'id': id, 'nombre': nombre, 'version': version};
  }

  Categoria copyWith({int? id, String? nombre, int? version}) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Categoria && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
