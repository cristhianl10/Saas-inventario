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
        .update({'nombre': categoria.nombre, 'version': categoria.version + 1})
        .eq('id', categoria.id!)
        .eq('user_id', _userId!)
        .eq('version', categoria.version)
        .select()
        .single();

    if (response.isEmpty) {
      throw Exception(
        'Este registro fue modificado por otro dispositivo. Recarga e intenta de nuevo.',
      );
    }

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
      final catId = p.categoriaId;
      if (catId != null) {
        counts[catId] = (counts[catId] ?? 0) + 1;
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
          'es_combo': producto.esCombo,
          'umbral_alerta': producto.umbralAlerta,
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
          'es_combo': producto.esCombo,
          'umbral_alerta': producto.umbralAlerta,
          'fecha_actualizacion': DateTime.now().toIso8601String(),
        })
        .eq('id', producto.id!)
        .eq('user_id', _userId!)
        .eq('version', producto.version)
        .select()
        .single();

    if (response.isEmpty) {
      throw Exception(
        'Este producto fue modificado por otro dispositivo. Recarga e intenta de nuevo.',
      );
    }

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
          'cliente_id': venta.clienteId,
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
          'cliente_id': venta.clienteId,
          'vendido_a': venta.vendidoA,
          'observaciones': venta.observaciones,
        })
        .eq('id', venta.id!)
        .eq('user_id', _userId!)
        .select()
        .single();

    if (response.isEmpty) {
      throw Exception(
        'Esta venta fue modificada por otro dispositivo. Recarga e intenta de nuevo.',
      );
    }

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
        .eq('version', tarifa.version)
        .select()
        .single();

    if (response.isEmpty) {
      throw Exception(
        'Esta tarifa fue modificada por otro dispositivo. Recarga e intenta de nuevo.',
      );
    }

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
        .eq('version', proveedor.version)
        .select()
        .single();

    if (response.isEmpty) {
      throw Exception(
        'Este proveedor fue modificado por otro dispositivo. Recarga e intenta de nuevo.',
      );
    }

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

    try {
      final newResponse = await _client
          .from('categorias')
          .insert({'nombre': 'Combo', 'user_id': _userId!})
          .select()
          .single();
      return Categoria.fromJson(newResponse);
    } catch (e) {
      if (e.toString().contains('duplicate') ||
          e.toString().contains('unique') ||
          e.toString().contains('23505')) {
        final retryResponse = await _client
            .from('categorias')
            .select()
            .eq('nombre', 'Combo')
            .eq('user_id', _userId!)
            .limit(1);
        if (retryResponse.isNotEmpty) {
          return Categoria.fromJson(retryResponse.first);
        }
      }
      rethrow;
    }
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
    final response = await _client
        .from('combo_items')
        .update({'cantidad': item.cantidad})
        .eq('id', item.id!)
        .eq('user_id', _userId!)
        .eq('version', item.version);

    if (response.isEmpty) {
      throw Exception(
        'Este item fue modificado por otro dispositivo. Recarga e intenta de nuevo.',
      );
    }
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

  // ==================== PURCHASE ORDERS ====================

  Future<List<Map<String, dynamic>>> getPurchaseOrders({
    int? providerId,
  }) async {
    _checkAuth();
    var query = _client
        .from('purchase_orders')
        .select()
        .eq('user_id', _userId!);
    if (providerId != null) {
      query = query.eq('provider_id', providerId);
    }
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createPurchaseOrder(
    Map<String, dynamic> order,
  ) async {
    _checkAuth();
    final response = await _client
        .from('purchase_orders')
        .insert({...order, 'user_id': _userId})
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> updatePurchaseOrder(
    String id,
    Map<String, dynamic> data, {
    int? version,
  }) async {
    _checkAuth();

    var query = _client
        .from('purchase_orders')
        .update({...data, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('user_id', _userId!);

    if (version != null) {
      query = query.eq('version', version);
    }

    final response = await query.select().single();

    if (response.isEmpty) {
      throw Exception(
        'Esta orden fue modificada por otro dispositivo. Recarga e intenta de nuevo.',
      );
    }

    return Map<String, dynamic>.from(response);
  }

  Future<void> deletePurchaseOrder(String id) async {
    _checkAuth();
    await _client
        .from('purchase_orders')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  // ==================== PURCHASE HISTORY ====================

  Future<List<Map<String, dynamic>>> getPurchaseHistory({
    int? providerId,
  }) async {
    _checkAuth();
    var query = _client
        .from('purchase_history')
        .select()
        .eq('user_id', _userId!);
    if (providerId != null) {
      query = query.eq('provider_id', providerId);
    }
    final response = await query.order('received_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deletePurchaseHistory(
    String id, {
    required bool removeFromStock,
  }) async {
    _checkAuth();

    if (removeFromStock) {
      final item = await _client
          .from('purchase_history')
          .select()
          .eq('id', id)
          .eq('user_id', _userId!)
          .maybeSingle();

      if (item != null && item['product_id'] != null) {
        final productos = await getProductos();
        final producto = productos
            .where((p) => p.id == item['product_id'])
            .firstOrNull;
        if (producto != null) {
          final nuevaCantidad =
              producto.cantidad - ((item['quantity'] as num?)?.toInt() ?? 0);
          await updateProducto(
            producto.copyWith(cantidad: nuevaCantidad < 0 ? 0 : nuevaCantidad),
          );
        }
      }
    }

    await _client
        .from('purchase_history')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  Future<Map<String, dynamic>> receivePurchaseOrder(
    String orderId,
    List<Map<String, dynamic>> items,
  ) async {
    _checkAuth();

    // Update order status
    await _client
        .from('purchase_orders')
        .update({
          'status': 'received',
          'received_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId)
        .eq('user_id', _userId!);

    // Add items to history and update stock
    for (final item in items) {
      await _client.from('purchase_history').insert({
        'purchase_order_id': orderId,
        'user_id': _userId,
        'product_id': item['product_id'],
        'product_name': item['product_name'],
        'quantity': item['quantity'],
        'unit_cost': item['unit_cost'],
        'total_cost': item['quantity'] * item['unit_cost'],
      });

      // Update product stock
      if (item['product_id'] != null) {
        final productos = await getProductos();
        final producto = productos
            .where((p) => p.id == item['product_id'])
            .firstOrNull;
        if (producto != null) {
          final nuevaCantidad =
              producto.cantidad + ((item['quantity'] as num?)?.toInt() ?? 0);
          await updateProducto(producto.copyWith(cantidad: nuevaCantidad));
        }
      }
    }

    final response = await _client
        .from('purchase_orders')
        .select()
        .eq('id', orderId)
        .single();
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> receivePurchaseOrderSimple({
    required String orderId,
    required int providerId,
    required int productId,
    required String productName,
    required int quantity,
    required double unitCost,
    required bool updateStock,
  }) async {
    _checkAuth();

    final orderResponse = await _client
        .from('purchase_orders')
        .select()
        .eq('id', orderId)
        .eq('user_id', _userId!)
        .maybeSingle();

    if (orderResponse == null) {
      throw Exception('Orden no encontrada');
    }

    await _client
        .from('purchase_orders')
        .update({
          'status': 'received',
          'received_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId)
        .eq('user_id', _userId!);

    await _client.from('purchase_history').insert({
      'purchase_order_id': orderId,
      'user_id': _userId,
      'provider_id': providerId,
      'product_id': productId > 0 ? productId : null,
      'product_name': productName,
      'quantity': quantity,
      'unit_cost': unitCost,
      'total_cost': quantity * unitCost,
    });

    if (updateStock && productId > 0) {
      final productos = await getProductos();
      final producto = productos.where((p) => p.id == productId).firstOrNull;
      if (producto != null) {
        final nuevaCantidad = producto.cantidad + quantity;
        await updateProducto(producto.copyWith(cantidad: nuevaCantidad));
      }
    }

    return Map<String, dynamic>.from(orderResponse);
  }

  Future<Map<String, dynamic>> getProviderStats(int providerId) async {
    _checkAuth();

    final history = await getPurchaseHistory(providerId: providerId);
    final orders = await getPurchaseOrders(providerId: providerId);

    double totalComprado = 0;
    int totalUnidades = 0;
    int ordenesCompletadas = 0;

    for (final h in history) {
      totalComprado += (h['total_cost'] as num?)?.toDouble() ?? 0;
      totalUnidades += (h['quantity'] as num?)?.toInt() ?? 0;
    }

    for (final o in orders) {
      if (o['status'] == 'received') ordenesCompletadas++;
    }

    return {
      'total_comprado': totalComprado,
      'total_unidades': totalUnidades,
      'ordenes_completadas': ordenesCompletadas,
      'ultima_compra': history.isNotEmpty ? history.first['received_at'] : null,
    };
  }

  // ==================== CLIENTES ====================

  Future<List<Cliente>> getClientes() async {
    _checkAuth();
    final response = await _client
        .from('clientes')
        .select()
        .eq('user_id', _userId!)
        .order('nombre');
    return response.map((json) => Cliente.fromJson(json)).toList();
  }

  Future<Cliente> createCliente(Cliente cliente) async {
    _checkAuth();
    final response = await _client
        .from('clientes')
        .insert({...cliente.toJson(), 'user_id': _userId})
        .select()
        .single();
    return Cliente.fromJson(response);
  }

  Future<Cliente> updateCliente(Cliente cliente) async {
    _checkAuth();
    final response = await _client
        .from('clientes')
        .update({
          'nombre': cliente.nombre,
          'telefono': cliente.telefono,
          'email': cliente.email,
          'direccion': cliente.direccion,
          'notas': cliente.notas,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', cliente.id!)
        .eq('user_id', _userId!)
        .eq('version', cliente.version)
        .select()
        .single();

    if (response.isEmpty) {
      throw Exception(
        'Este cliente fue modificado por otro dispositivo. Recarga e intenta de nuevo.',
      );
    }

    return Cliente.fromJson(response);
  }

  Future<void> deleteCliente(int id) async {
    _checkAuth();
    await _client
        .from('clientes')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  Future<List<Venta>> getVentasPorCliente(int clienteId) async {
    _checkAuth();
    final response = await _client
        .from('ventas')
        .select()
        .eq('cliente_id', clienteId)
        .eq('user_id', _userId!)
        .order('fecha_venta', ascending: false);
    return response.map((json) => Venta.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getClienteStats(int clienteId) async {
    _checkAuth();
    final ventas = await getVentasPorCliente(clienteId);

    double totalGastado = 0;
    int totalProductos = 0;
    DateTime? ultimaCompra;

    for (final venta in ventas) {
      totalGastado += venta.total;
      totalProductos += venta.cantidad;
      if (ultimaCompra == null || venta.fechaVenta.isAfter(ultimaCompra)) {
        ultimaCompra = venta.fechaVenta;
      }
    }

    return {
      'total_compras': ventas.length,
      'total_gastado': totalGastado,
      'total_productos': totalProductos,
      'ultima_compra': ultimaCompra?.toIso8601String(),
    };
  }
}
