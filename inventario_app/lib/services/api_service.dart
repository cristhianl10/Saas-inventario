import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class ApiService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  void _checkAuth() {
    if (_userId == null) {
      throw Exception('Sesión expirada. Inicia sesión nuevamente.');
    }
  }

  // ==================== CATEGORIAS ====================

  Future<List<Categoria>> getCategorias() async {
    _checkAuth();
    final response = await _client
        .from('categorias')
        .select()
        .eq('user_id', _userId!)
        .order('id');
    return response.map((json) => Categoria.fromJson(json)).toList();
  }

  Future<Categoria> createCategoria(Categoria categoria) async {
    _checkAuth();
    final response = await _client
        .from('categorias')
        .insert({'nombre': categoria.nombre, 'user_id': _userId!})
        .select()
        .single();
    return Categoria.fromJson(response);
  }

  Future<Categoria> updateCategoria(Categoria categoria) async {
    _checkAuth();
    final response = await _client
        .from('categorias')
        .update({'nombre': categoria.nombre})
        .eq('id', categoria.id!)
        .eq('user_id', _userId!)
        .select()
        .single();
    return Categoria.fromJson(response);
  }

  Future<void> deleteCategoria(int id) async {
    _checkAuth();
    await _client
        .from('categorias')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  // ==================== PRODUCTOS ====================

  Future<List<Producto>> getProductos() async {
    _checkAuth();
    final response = await _client
        .from('productos')
        .select()
        .eq('user_id', _userId!)
        .order('id');
    return response.map((json) => Producto.fromJson(json)).toList();
  }

  Future<Map<int, int>> getProductosCountPorCategoria() async {
    final productos = await getProductos();
    final counts = <int, int>{};
    for (final p in productos) {
      if (p.categoriaId != null) {
        counts[p.categoriaId!] = (counts[p.categoriaId!] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<List<Producto>> getProductosPorCategoria(int categoriaId) async {
    _checkAuth();
    final response = await _client
        .from('productos')
        .select()
        .eq('categoria_id', categoriaId)
        .eq('user_id', _userId!)
        .order('id');
    return response.map((json) => Producto.fromJson(json)).toList();
  }

  Future<Producto> createProducto(Producto producto) async {
    _checkAuth();
    final response = await _client
        .from('productos')
        .insert({
          'categoria_id': producto.categoriaId,
          'nombre': producto.nombre,
          'descripcion': producto.descripcion,
          'cantidad': producto.cantidad,
          'precio': producto.precio,
          'proveedor_id': producto.proveedorId,
          'costo': producto.costo,
          'user_id': _userId!,
        })
        .select()
        .single();
    return Producto.fromJson(response);
  }

  Future<Producto> updateProducto(Producto producto) async {
    _checkAuth();
    if (producto.id == null) {
      throw Exception('ID del producto no válido');
    }
    // Validar que la cantidad nunca sea negativa
    final cantidadValida = producto.cantidad < 0 ? 0 : producto.cantidad;
    final response = await _client
        .from('productos')
        .update({
          'cantidad': cantidadValida,
          'precio': producto.precio,
          'nombre': producto.nombre,
          'descripcion': producto.descripcion,
          'categoria_id': producto.categoriaId,
          'proveedor_id': producto.proveedorId,
          'costo': producto.costo,
          'fecha_actualizacion': DateTime.now().toIso8601String(),
        })
        .eq('id', producto.id!)
        .eq('user_id', _userId!)
        .select()
        .single();
    return Producto.fromJson(response);
  }

  Future<void> deleteProducto(int id) async {
    _checkAuth();
    await _client
        .from('productos')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  // ==================== VENTAS ====================

  Future<List<Venta>> getVentas() async {
    _checkAuth();
    final response = await _client
        .from('ventas')
        .select()
        .eq('user_id', _userId!)
        .order('fecha_venta', ascending: false);
    return response.map((json) => Venta.fromJson(json)).toList();
  }

  Future<Venta> createVenta(Venta venta) async {
    _checkAuth();
    final response = await _client
        .from('ventas')
        .insert({
          'producto_id': venta.productoId,
          'cantidad': venta.cantidad,
          'precio_unitario': venta.precioUnitario,
          'total': venta.total,
          'fecha_venta': venta.fechaVenta.toIso8601String(),
          'vendido_a': venta.vendidoA,
          'observaciones': venta.observaciones,
          'user_id': _userId!,
        })
        .select()
        .single();
    return Venta.fromJson(response);
  }

  Future<Venta> updateVenta(Venta venta) async {
    _checkAuth();
    final response = await _client
        .from('ventas')
        .update({
          'producto_id': venta.productoId,
          'cantidad': venta.cantidad,
          'precio_unitario': venta.precioUnitario,
          'total': venta.total,
          'fecha_venta': venta.fechaVenta.toIso8601String(),
          'vendido_a': venta.vendidoA,
          'observaciones': venta.observaciones,
        })
        .eq('id', venta.id!)
        .eq('user_id', _userId!)
        .select()
        .single();
    return Venta.fromJson(response);
  }

  Future<void> deleteVenta(int id) async {
    _checkAuth();
    await _client.from('ventas').delete().eq('id', id).eq('user_id', _userId!);
  }

  // ==================== TARIFA PRECIOS ====================

  Future<List<PrecioTarifa>> getTarifasPorProducto(int productoId) async {
    _checkAuth();
    final response = await _client
        .from('tarifa_precios')
        .select()
        .eq('producto_id', productoId)
        .eq('user_id', _userId!)
        .order('cantidad_min');
    return response.map((json) => PrecioTarifa.fromJson(json)).toList();
  }

  Future<List<PrecioTarifa>> getTodasTarifas() async {
    _checkAuth();
    final response = await _client
        .from('tarifa_precios')
        .select()
        .eq('user_id', _userId!)
        .order('producto_id')
        .order('cantidad_min');
    return response.map((json) => PrecioTarifa.fromJson(json)).toList();
  }

  Future<PrecioTarifa> createTarifa(PrecioTarifa tarifa) async {
    _checkAuth();
    final response = await _client
        .from('tarifa_precios')
        .insert({
          'producto_id': tarifa.productoId,
          'cantidad_min': tarifa.cantidadMin,
          'cantidad_max': tarifa.cantidadMax,
          'precio_unitario': tarifa.precioUnitario,
          'user_id': _userId!,
        })
        .select()
        .single();
    return PrecioTarifa.fromJson(response);
  }

  Future<PrecioTarifa> updateTarifa(PrecioTarifa tarifa) async {
    _checkAuth();
    final response = await _client
        .from('tarifa_precios')
        .update({
          'producto_id': tarifa.productoId,
          'cantidad_min': tarifa.cantidadMin,
          'cantidad_max': tarifa.cantidadMax,
          'precio_unitario': tarifa.precioUnitario,
        })
        .eq('id', tarifa.id!)
        .eq('user_id', _userId!)
        .select()
        .single();
    return PrecioTarifa.fromJson(response);
  }

  Future<void> deleteTarifa(int id) async {
    _checkAuth();
    await _client
        .from('tarifa_precios')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  Future<void> deleteTarifasPorProducto(int productoId) async {
    _checkAuth();
    await _client
        .from('tarifa_precios')
        .delete()
        .eq('producto_id', productoId)
        .eq('user_id', _userId!);
  }

  // ==================== PROVEEDORES ====================

  Future<List<Proveedor>> getProveedores() async {
    _checkAuth();
    final response = await _client
        .from('proveedores')
        .select()
        .eq('user_id', _userId!)
        .order('nombre');
    return response.map((json) => Proveedor.fromJson(json)).toList();
  }

  Future<Proveedor> createProveedor(Proveedor proveedor) async {
    _checkAuth();
    final response = await _client
        .from('proveedores')
        .insert({
          'nombre': proveedor.nombre,
          'telefono': proveedor.telefono,
          'user_id': _userId!,
        })
        .select()
        .single();
    return Proveedor.fromJson(response);
  }

  Future<Proveedor> updateProveedor(Proveedor proveedor) async {
    _checkAuth();
    final response = await _client
        .from('proveedores')
        .update({'nombre': proveedor.nombre, 'telefono': proveedor.telefono})
        .eq('id', proveedor.id!)
        .eq('user_id', _userId!)
        .select()
        .single();
    return Proveedor.fromJson(response);
  }

  Future<void> detachProductosFromProveedor(int proveedorId) async {
    _checkAuth();
    await _client
        .from('productos')
        .update({'proveedor_id': null})
        .eq('proveedor_id', proveedorId)
        .eq('user_id', _userId!);
  }

  Future<void> deleteProveedor(int id) async {
    _checkAuth();
    await detachProductosFromProveedor(id);
    await _client
        .from('proveedores')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  // ==================== COMBOS ====================

  Future<Categoria> _getOrCreateComboCategory() async {
    _checkAuth();
    final response = await _client
        .from('categorias')
        .select()
        .eq('nombre', 'Combo')
        .eq('user_id', _userId!)
        .limit(1);

    if (response.isNotEmpty) {
      return Categoria.fromJson(response.first);
    }

    final newResponse = await _client
        .from('categorias')
        .insert({'nombre': 'Combo', 'user_id': _userId!})
        .select()
        .single();
    return Categoria.fromJson(newResponse);
  }

  Future<List<Producto>> getCombos() async {
    _checkAuth();
    final response = await _client
        .from('productos')
        .select()
        .eq('es_combo', true)
        .eq('user_id', _userId!)
        .order('nombre');
    return response.map((json) => Producto.fromJson(json)).toList();
  }

  Future<Producto> createCombo(Producto combo) async {
    _checkAuth();
    final comboCategory = await _getOrCreateComboCategory();

    final response = await _client
        .from('productos')
        .insert({
          'nombre': combo.nombre,
          'descripcion': combo.descripcion,
          'cantidad': combo.cantidad,
          'precio': combo.precio,
          'es_combo': true,
          'costo': combo.costo,
          'categoria_id': comboCategory.id,
          'user_id': _userId!,
        })
        .select()
        .single();
    return Producto.fromJson(response);
  }

  Future<Producto> updateCombo(Producto combo) async {
    _checkAuth();
    final comboCategory = await _getOrCreateComboCategory();

    final response = await _client
        .from('productos')
        .update({
          'nombre': combo.nombre,
          'descripcion': combo.descripcion,
          'precio': combo.precio,
          'categoria_id': comboCategory.id,
          'fecha_actualizacion': DateTime.now().toIso8601String(),
        })
        .eq('id', combo.id!)
        .eq('es_combo', true)
        .eq('user_id', _userId!)
        .select()
        .single();
    return Producto.fromJson(response);
  }

  Future<void> deleteCombo(int id) async {
    _checkAuth();
    await deleteComboItems(id);
    await _client
        .from('productos')
        .delete()
        .eq('id', id)
        .eq('es_combo', true)
        .eq('user_id', _userId!);
  }

  Future<List<ComboItem>> getComboItems(int comboId) async {
    _checkAuth();
    final response = await _client
        .from('combo_items')
        .select()
        .eq('combo_id', comboId)
        .eq('user_id', _userId!);

    return response.map((json) {
      return ComboItem.fromJson(json);
    }).toList();
  }

  Future<ComboItem> addComboItem(ComboItem item) async {
    _checkAuth();
    final response = await _client
        .from('combo_items')
        .insert({
          'combo_id': item.comboId,
          'producto_id': item.productoId,
          'cantidad': item.cantidad,
          'user_id': _userId!,
        })
        .select()
        .single();
    return ComboItem.fromJson(response);
  }

  Future<void> updateComboItem(ComboItem item) async {
    _checkAuth();
    await _client
        .from('combo_items')
        .update({'cantidad': item.cantidad})
        .eq('id', item.id!)
        .eq('user_id', _userId!);
  }

  Future<void> deleteComboItem(int id) async {
    _checkAuth();
    await _client
        .from('combo_items')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  Future<void> deleteComboItems(int comboId) async {
    _checkAuth();
    await _client
        .from('combo_items')
        .delete()
        .eq('combo_id', comboId)
        .eq('user_id', _userId!);
  }

  Future<void> descontarStockCombo(int comboId, int cantidadVenta) async {
    final items = await getComboItems(comboId);
    final productos = await getProductos();

    for (final item in items) {
      final producto = productos
          .where((p) => p.id == item.productoId)
          .firstOrNull;
      if (producto != null) {
        final nuevaCantidad =
            producto.cantidad - (item.cantidad * cantidadVenta);
        // Asegurar que nunca sea negativo
        final cantidadValida = nuevaCantidad < 0 ? 0 : nuevaCantidad;
        await updateProducto(producto.copyWith(cantidad: cantidadValida));
      }
    }
  }

  Future<void> restaurarStockCombo(int comboId, int cantidadDevolver) async {
    final items = await getComboItems(comboId);
    final productos = await getProductos();

    for (final item in items) {
      final producto = productos
          .where((p) => p.id == item.productoId)
          .firstOrNull;
      if (producto != null) {
        final nuevaCantidad =
            producto.cantidad + (item.cantidad * cantidadDevolver);
        await updateProducto(producto.copyWith(cantidad: nuevaCantidad));
      }
    }
  }
}
