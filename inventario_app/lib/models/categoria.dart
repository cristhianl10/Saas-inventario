import 'package:flutter/material.dart';

class Categoria {
  final int? id;
  final String nombre;
  final String? descripcion;
  final String emoji;
  final String color;

  Categoria({
    this.id,
    required this.nombre,
    this.descripcion,
    this.emoji = '📦',
    this.color = '#ffffff',
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      emoji: json['emoji'] as String? ?? '📦',
      color: json['color'] as String? ?? '#ffffff',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'emoji': emoji,
      'color': color,
    };
  }

  Categoria copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    String? emoji,
    String? color,
  }) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
    );
  }

  Color get colorValue {
    final hex = color.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
