import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // CAMBIA ESTA URL POR LA DE TU BACKEND
  // Ejemplo: 'http://192.168.1.100:3000' o 'https://tu-servidor.com/api'
  static const String baseUrl = 'http://localhost:3000/api';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ==================== CATEGORÍAS ====================

  Future<List<Categoria>> getCategorias() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/categorias'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Categoria.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar categorías: ${response.statusCode}');
    }
  }

  Future<Categoria> createCategoria(Categoria categoria) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/categorias'),
      headers: _headers,
      body: json.encode(categoria.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Categoria.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear categoría: ${response.statusCode}');
    }
  }

  Future<Categoria> updateCategoria(Categoria categoria) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/categorias/${categoria.id}'),
      headers: _headers,
      body: json.encode(categoria.toJson()),
    );

    if (response.statusCode == 200) {
      return Categoria.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar categoría: ${response.statusCode}');
    }
  }

  Future<void> deleteCategoria(int id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/categorias/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar categoría: ${response.statusCode}');
    }
  }

  // ==================== PRODUCTOS ====================

  Future<List<Producto>> getProductos() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/productos'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Producto.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar productos: ${response.statusCode}');
    }
  }

  Future<List<Producto>> getProductosPorCategoria(int categoriaId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/productos?categoria_id=$categoriaId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Producto.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar productos: ${response.statusCode}');
    }
  }

  Future<Producto> createProducto(Producto producto) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/productos'),
      headers: _headers,
      body: json.encode(producto.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Producto.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear producto: ${response.statusCode}');
    }
  }

  Future<Producto> updateProducto(Producto producto) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/productos/${producto.id}'),
      headers: _headers,
      body: json.encode(producto.toJson()),
    );

    if (response.statusCode == 200) {
      return Producto.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar producto: ${response.statusCode}');
    }
  }

  Future<void> deleteProducto(int id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/productos/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar producto: ${response.statusCode}');
    }
  }
}
