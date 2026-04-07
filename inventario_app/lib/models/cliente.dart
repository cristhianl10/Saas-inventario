class Cliente {
  final int? id;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? notas;
  final DateTime createdAt;
  final int version;

  Cliente({
    this.id,
    required this.nombre,
    this.telefono,
    this.email,
    this.direccion,
    this.notas,
    DateTime? createdAt,
    this.version = 1,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      direccion: json['direccion'] as String?,
      notas: json['notas'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      if (direccion != null) 'direccion': direccion,
      if (notas != null) 'notas': notas,
      'created_at': createdAt.toIso8601String(),
      'version': version,
    };
  }

  Cliente copyWith({
    int? id,
    String? nombre,
    String? telefono,
    String? email,
    String? direccion,
    String? notas,
    DateTime? createdAt,
    int? version,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      notas: notas ?? this.notas,
      createdAt: createdAt ?? this.createdAt,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cliente && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
