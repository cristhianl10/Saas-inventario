class Categoria {
  final int? id;
  final String nombre;

  Categoria({
    this.id,
    required this.nombre,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
    };
  }

  Categoria copyWith({
    int? id,
    String? nombre,
  }) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
    );
  }
}
