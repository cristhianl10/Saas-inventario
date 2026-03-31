import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class ApiService {
  final SupabaseClient _client = Supabase.instance.client;
  bool _hasUserIdColumn = true;

  String get _userId => _client.auth.currentUser?.id ?? '';

  bool _isMissingUserIdColumnError(PostgrestException e) {
    final msg = e.message.toLowerCase();
    return e.code == '42703' ||
        (msg.contains('user_id') && msg.contains('does not exist'));
  }

  Future<T> _runWithUserIdFallback<T>(
    Future<T> Function(bool useUserId) operation,
  ) async {
    try {
      return await operation(_hasUserIdColumn);
    } on PostgrestException catch (e) {
      if (_hasUserIdColumn && _isMissingUserIdColumnError(e)) {
        _hasUserIdColumn = false;
        return operation(false);
      }
      rethrow;
    }
  }

  Future<List<Categoria>> getCategorias() async {
    return _runWithUserIdFallback((useUserId) async {
      final query = _client.from('categorias').select();
      final response = useUserId
          ? await query.eq('user_id', _userId).order('id')
          : await query.order('id');
      return response.map((json) => Categoria.fromJson(json)).toList();
    });
  }

  Future<Categoria> createCategoria(Categoria categoria) async {
    return _runWithUserIdFallback((useUserId) async {
      final data = <String, dynamic>{'nombre': categoria.nombre};
      if (useUserId) data['user_id'] = _userId;
      final response = await _client
          .from('categorias')
          .insert(data)
          .select()
          .single();
      return Categoria.fromJson(response);
    });
  }

  Future<Categoria> updateCategoria(Categoria categoria) async {
    return _runWithUserIdFallback((useUserId) async {
      var query = _client
          .from('categorias')
          .update({'nombre': categoria.nombre})
          .eq('id', categoria.id!);
      if (useUserId) query = query.eq('user_id', _userId);
      final response = await query.select().single();
      return Categoria.fromJson(response);
    });
  }

  Future<void> deleteCategoria(int id) async {
    await _runWithUserIdFallback((useUserId) async {
      var query = _client.from('categorias').delete().eq('id', id);
      if (useUserId) query = query.eq('user_id', _userId);
      await query;
    });
  }

  Future<List<Producto>> getProductos() async {
    return _runWithUserIdFallback((useUserId) async {
      final query = _client.from('productos').select();
      final response = useUserId
          ? await query.eq('user_id', _userId).order('id')
          : await query.order('id');
      return response.map((json) => Producto.fromJson(json)).toList();
    });
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
    return _runWithUserIdFallback((useUserId) async {
      var query = _client
          .from('productos')
          .select()
          .eq('categoria_id', categoriaId);
      if (useUserId) query = query.eq('user_id', _userId);
      final response = await query.order('id');
      return response.map((json) => Producto.fromJson(json)).toList();
    });
  }

  Future<Producto> createProducto(Producto producto) async {
    return _runWithUserIdFallback((useUserId) async {
      final data = <String, dynamic>{
        'categoria_id': producto.categoriaId,
        'nombre': producto.nombre,
        'descripcion': producto.descripcion,
        'cantidad': producto.cantidad,
        'precio': producto.precio,
        'proveedor_id': producto.proveedorId,
        'costo': producto.costo,
      };
      if (useUserId) data['user_id'] = _userId;
      final response = await _client
          .from('productos')
          .insert(data)
          .select()
          .single();
      return Producto.fromJson(response);
    });
  }

  Future<Producto> updateProducto(Producto producto) async {
    return _runWithUserIdFallback((useUserId) async {
      var query = _client
          .from('productos')
          .update({
            'categoria_id': producto.categoriaId,
            'nombre': producto.nombre,
            'descripcion': producto.descripcion,
            'cantidad': producto.cantidad,
            'precio': producto.precio,
            'proveedor_id': producto.proveedorId,
            'costo': producto.costo,
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('id', producto.id!);
      if (useUserId) query = query.eq('user_id', _userId);
      final response = await query.select().single();
      return Producto.fromJson(response);
    });
  }

  Future<void> deleteProducto(int id) async {
    await _runWithUserIdFallback((useUserId) async {
      var query = _client.from('productos').delete().eq('id', id);
      if (useUserId) query = query.eq('user_id', _userId);
      await query;
    });
  }

  Future<List<Venta>> getVentas() async {
    return _runWithUserIdFallback((useUserId) async {
      final query = _client.from('ventas').select();
      final response = useUserId
          ? await query
                .eq('user_id', _userId)
                .order('fecha_venta', ascending: false)
          : await query.order('fecha_venta', ascending: false);
      return response.map((json) => Venta.fromJson(json)).toList();
    });
  }

  Future<Venta> createVenta(Venta venta) async {
    return _runWithUserIdFallback((useUserId) async {
      final data = <String, dynamic>{
        'producto_id': venta.productoId,
        'cantidad': venta.cantidad,
        'precio_unitario': venta.precioUnitario,
        'total': venta.total,
        'fecha_venta': venta.fechaVenta.toIso8601String(),
        'vendido_a': venta.vendidoA,
        'observaciones': venta.observaciones,
      };
      if (useUserId) data['user_id'] = _userId;
      final response = await _client
          .from('ventas')
          .insert(data)
          .select()
          .single();
      return Venta.fromJson(response);
    });
  }

  Future<Venta> updateVenta(Venta venta) async {
    return _runWithUserIdFallback((useUserId) async {
      var query = _client
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
          .eq('id', venta.id!);
      if (useUserId) query = query.eq('user_id', _userId);
      final response = await query.select().single();
      return Venta.fromJson(response);
    });
  }

  Future<void> deleteVenta(int id) async {
    await _runWithUserIdFallback((useUserId) async {
      var query = _client.from('ventas').delete().eq('id', id);
      if (useUserId) query = query.eq('user_id', _userId);
      await query;
    });
  }

  Future<List<PrecioTarifa>> getTarifasPorProducto(int productoId) async {
    return _runWithUserIdFallback((useUserId) async {
      var query = _client
          .from('tarifa_precios')
          .select()
          .eq('producto_id', productoId);
      if (useUserId) query = query.eq('user_id', _userId);
      final response = await query.order('cantidad_min');
      return response.map((json) => PrecioTarifa.fromJson(json)).toList();
    });
  }

  Future<List<PrecioTarifa>> getTodasTarifas() async {
    return _runWithUserIdFallback((useUserId) async {
      var query = _client.from('tarifa_precios').select();
      if (useUserId) query = query.eq('user_id', _userId);
      final response = await query.order('producto_id').order('cantidad_min');
      return response.map((json) => PrecioTarifa.fromJson(json)).toList();
    });
  }

  Future<PrecioTarifa> createTarifa(PrecioTarifa tarifa) async {
    return _runWithUserIdFallback((useUserId) async {
      final data = <String, dynamic>{
        'producto_id': tarifa.productoId,
        'cantidad_min': tarifa.cantidadMin,
        'cantidad_max': tarifa.cantidadMax,
        'precio_unitario': tarifa.precioUnitario,
      };
      if (useUserId) data['user_id'] = _userId;
      final response = await _client
          .from('tarifa_precios')
          .insert(data)
          .select()
          .single();
      return PrecioTarifa.fromJson(response);
    });
  }

  Future<PrecioTarifa> updateTarifa(PrecioTarifa tarifa) async {
    return _runWithUserIdFallback((useUserId) async {
      var query = _client
          .from('tarifa_precios')
          .update({
            'producto_id': tarifa.productoId,
            'cantidad_min': tarifa.cantidadMin,
            'cantidad_max': tarifa.cantidadMax,
            'precio_unitario': tarifa.precioUnitario,
          })
          .eq('id', tarifa.id!);
      if (useUserId) query = query.eq('user_id', _userId);
      final response = await query.select().single();
      return PrecioTarifa.fromJson(response);
    });
  }

  Future<void> deleteTarifa(int id) async {
    await _runWithUserIdFallback((useUserId) async {
      var query = _client.from('tarifa_precios').delete().eq('id', id);
      if (useUserId) query = query.eq('user_id', _userId);
      await query;
    });
  }

  Future<void> deleteTarifasPorProducto(int productoId) async {
    await _runWithUserIdFallback((useUserId) async {
      var query = _client
          .from('tarifa_precios')
          .delete()
          .eq('producto_id', productoId);
      if (useUserId) query = query.eq('user_id', _userId);
      await query;
    });
  }

  Future<List<Proveedor>> getProveedores() async {
    return _runWithUserIdFallback((useUserId) async {
      final query = _client.from('proveedores').select();
      final response = useUserId
          ? await query.eq('user_id', _userId).order('nombre')
          : await query.order('nombre');
      return response.map((json) => Proveedor.fromJson(json)).toList();
    });
  }

  Future<Proveedor> createProveedor(Proveedor proveedor) async {
    return _runWithUserIdFallback((useUserId) async {
      final data = <String, dynamic>{
        'nombre': proveedor.nombre,
        'telefono': proveedor.telefono,
      };
      if (useUserId) data['user_id'] = _userId;
      final response = await _client
          .from('proveedores')
          .insert(data)
          .select()
          .single();
      return Proveedor.fromJson(response);
    });
  }

  Future<Proveedor> updateProveedor(Proveedor proveedor) async {
    return _runWithUserIdFallback((useUserId) async {
      var query = _client
          .from('proveedores')
          .update({'nombre': proveedor.nombre, 'telefono': proveedor.telefono})
          .eq('id', proveedor.id!);
      if (useUserId) query = query.eq('user_id', _userId);
      final response = await query.select().single();
      return Proveedor.fromJson(response);
    });
  }

  Future<void> detachProductosFromProveedor(int proveedorId) async {
    await _runWithUserIdFallback((useUserId) async {
      var query = _client
          .from('productos')
          .update({'proveedor_id': null})
          .eq('proveedor_id', proveedorId);
      if (useUserId) query = query.eq('user_id', _userId);
      await query;
    });
  }

  Future<void> deleteProveedor(int id) async {
    await detachProductosFromProveedor(id);
    await _runWithUserIdFallback((useUserId) async {
      var query = _client.from('proveedores').delete().eq('id', id);
      if (useUserId) query = query.eq('user_id', _userId);
      await query;
    });
  }

  // ==================== COMBOS ====================

  Future<List<Producto>> getCombos() async {
    return _runWithUserIdFallback((useUserId) async {
      var query = _client.from('productos').select().eq('es_combo', true);
      if (useUserId) query = query.eq('user_id', _userId);
      final response = await query.order('nombre');
      return response.map((json) => Producto.fromJson(json)).toList();
    });
  }

  Future<Producto> createCombo(Producto combo) async {
    return _runWithUserIdFallback((useUserId) async {
      final data = <String, dynamic>{
        'categoria_id': combo.categoriaId,
        'nombre': combo.nombre,
        'descripcion': combo.descripcion,
        'cantidad': combo.cantidad,
        'precio': combo.precio,
        'es_combo': true,
        'costo': combo.costo,
      };
      if (useUserId) data['user_id'] = _userId;
      final response = await _client
          .from('productos')
          .insert(data)
          .select()
          .single();
      return Producto.fromJson(response);
    });
  }

  Future<Producto> updateCombo(Producto combo) async {
    return _runWithUserIdFallback((useUserId) async {
      var query = _client
          .from('productos')
          .update({
            'nombre': combo.nombre,
            'descripcion': combo.descripcion,
            'precio': combo.precio,
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('id', combo.id!)
          .eq('es_combo', true);
      if (useUserId) query = query.eq('user_id', _userId);
      final response = await query.select().single();
      return Producto.fromJson(response);
    });
  }

  Future<void> deleteCombo(int id) async {
    await deleteComboItems(id);
    await _runWithUserIdFallback((useUserId) async {
      var query = _client
          .from('productos')
          .delete()
          .eq('id', id)
          .eq('es_combo', true);
      if (useUserId) query = query.eq('user_id', _userId);
      await query;
    });
  }

  Future<List<ComboItem>> getComboItems(int comboId) async {
    return _runWithUserIdFallback((useUserId) async {
      var query = _client
          .from('combo_items')
          .select('*, productos(nombre)')
          .eq('combo_id', comboId);
      if (useUserId) {
        query = query.eq('productos(user_id)', _userId);
      }
      final response = await query;
      return response.map((json) {
        final nombreProducto = json['productos']?['nombre'] as String?;
        return ComboItem.fromJson(
          json,
        ).copyWith(nombreProducto: nombreProducto);
      }).toList();
    });
  }

  Future<ComboItem> addComboItem(ComboItem item) async {
    return _runWithUserIdFallback((useUserId) async {
      final data = <String, dynamic>{
        'combo_id': item.comboId,
        'producto_id': item.productoId,
        'cantidad': item.cantidad,
      };
      if (useUserId) data['user_id'] = _userId;
      final response = await _client
          .from('combo_items')
          .insert(data)
          .select()
          .single();
      return ComboItem.fromJson(response);
    });
  }

  Future<void> updateComboItem(ComboItem item) async {
    await _runWithUserIdFallback((useUserId) async {
      var query = _client
          .from('combo_items')
          .update({'cantidad': item.cantidad})
          .eq('id', item.id!);
      if (useUserId) query = query.eq('user_id', _userId);
      await query;
    });
  }

  Future<void> deleteComboItem(int id) async {
    await _runWithUserIdFallback((useUserId) async {
      var query = _client.from('combo_items').delete().eq('id', id);
      if (useUserId) query = query.eq('user_id', _userId);
      await query;
    });
  }

  Future<void> deleteComboItems(int comboId) async {
    await _runWithUserIdFallback((useUserId) async {
      var query = _client.from('combo_items').delete().eq('combo_id', comboId);
      if (useUserId) query = query.eq('user_id', _userId);
      await query;
    });
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
        await updateProducto(producto.copyWith(cantidad: nuevaCantidad));
      }
    }
  }
}
