import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class ApiService {
  final SupabaseClient _client = Supabase.instance.client;

  // ==================== CATEGORÍAS ====================

  Future<List<Categoria>> getCategorias() async {
    final response = await _client
        .from('categorias')
        .select()
        .order('id');
    
    return response.map((json) => Categoria.fromJson(json)).toList();
  }

  Future<Categoria> createCategoria(Categoria categoria) async {
    final response = await _client
        .from('categorias')
        .insert(categoria.toJson())
        .select()
        .single();
    
    return Categoria.fromJson(response);
  }

  Future<Categoria> updateCategoria(Categoria categoria) async {
    final response = await _client
        .from('categorias')
        .update(categoria.toJson())
        .eq('id', categoria.id!)
        .select()
        .single();
    
    return Categoria.fromJson(response);
  }

  Future<void> deleteCategoria(int id) async {
    await _client
        .from('categorias')
        .delete()
        .eq('id', id);
  }

  // ==================== PRODUCTOS ====================

  Future<List<Producto>> getProductos() async {
    final response = await _client
        .from('productos')
        .select()
        .order('id');
    
    return response.map((json) => Producto.fromJson(json)).toList();
  }

  Future<List<Producto>> getProductosPorCategoria(int categoriaId) async {
    final response = await _client
        .from('productos')
        .select()
        .eq('categoria_id', categoriaId)
        .order('id');
    
    return response.map((json) => Producto.fromJson(json)).toList();
  }

  Future<Producto> createProducto(Producto producto) async {
    final response = await _client
        .from('productos')
        .insert(producto.toJson())
        .select()
        .single();
    
    return Producto.fromJson(response);
  }

  Future<Producto> updateProducto(Producto producto) async {
    final response = await _client
        .from('productos')
        .update(producto.toJson())
        .eq('id', producto.id!)
        .select()
        .single();
    
    return Producto.fromJson(response);
  }

  Future<void> deleteProducto(int id) async {
    await _client
        .from('productos')
        .delete()
        .eq('id', id);
  }

  // ==================== VENTAS ====================

  Future<List<Venta>> getVentas() async {
    final response = await _client
        .from('ventas')
        .select()
        .order('fecha_venta', ascending: false);
    
    return response.map((json) => Venta.fromJson(json)).toList();
  }

  Future<Venta> createVenta(Venta venta) async {
    final response = await _client
        .from('ventas')
        .insert(venta.toJson())
        .select()
        .single();
    
    return Venta.fromJson(response);
  }

  Future<Venta> updateVenta(Venta venta) async {
    final response = await _client
        .from('ventas')
        .update(venta.toJson())
        .eq('id', venta.id!)
        .select()
        .single();
    
    return Venta.fromJson(response);
  }

  Future<void> deleteVenta(int id) async {
    await _client
        .from('ventas')
        .delete()
        .eq('id', id);
  }
}
