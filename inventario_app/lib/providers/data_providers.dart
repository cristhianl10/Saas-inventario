import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/api_service.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final productosStreamProvider = StreamProvider<List<Producto>>((ref) {
  final client = ref.watch(supabaseProvider);
  return client
      .from('productos')
      .stream(primaryKey: ['id'])
      .order('id')
      .map((maps) => maps.map((map) => Producto.fromJson(map)).toList());
});

final categoriasStreamProvider = StreamProvider<List<Categoria>>((ref) {
  final client = ref.watch(supabaseProvider);
  return client
      .from('categorias')
      .stream(primaryKey: ['id'])
      .order('id')
      .map((maps) => maps.map((map) => Categoria.fromJson(map)).toList());
});

final ventasStreamProvider = StreamProvider<List<Venta>>((ref) {
  final client = ref.watch(supabaseProvider);
  return client
      .from('ventas')
      .stream(primaryKey: ['id'])
      .order('fecha_venta', ascending: false)
      .map((maps) => maps.map((map) => Venta.fromJson(map)).toList());
});

final clientesStreamProvider = StreamProvider<List<Cliente>>((ref) {
  final client = ref.watch(supabaseProvider);
  return client
      .from('clientes')
      .stream(primaryKey: ['id'])
      .order('id')
      .map((maps) => maps.map((map) => Cliente.fromJson(map)).toList());
});

final proveedoresStreamProvider = StreamProvider<List<Proveedor>>((ref) {
  final client = ref.watch(supabaseProvider);
  return client
      .from('proveedores')
      .stream(primaryKey: ['id'])
      .order('id')
      .map((maps) => maps.map((map) => Proveedor.fromJson(map)).toList());
});

final tarifasStreamProvider = StreamProvider<List<PrecioTarifa>>((ref) {
  final client = ref.watch(supabaseProvider);
  return client
      .from('tarifas')
      .stream(primaryKey: ['id'])
      .order('id')
      .map((maps) => maps.map((map) => PrecioTarifa.fromJson(map)).toList());
});

final purchaseOrdersStreamProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    final client = ref.watch(supabaseProvider);
    return client
        .from('purchase_orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (maps) => maps.map((map) => Map<String, dynamic>.from(map)).toList(),
        );
  },
);

final purchaseHistoryStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
      final client = ref.watch(supabaseProvider);
      return client
          .from('purchase_history')
          .stream(primaryKey: ['id'])
          .order('received_at', ascending: false)
          .map(
            (maps) =>
                maps.map((map) => Map<String, dynamic>.from(map)).toList(),
          );
    });

final selectedCategoryFilterProvider = StateProvider<int?>((ref) => null);

final filteredProductosProvider = Provider<AsyncValue<List<Producto>>>((ref) {
  final productosAsync = ref.watch(productosStreamProvider);
  final selectedCategory = ref.watch(selectedCategoryFilterProvider);

  return productosAsync.whenData((productos) {
    if (selectedCategory == null) {
      return productos;
    }
    return productos.where((p) => p.categoriaId == selectedCategory).toList();
  });
});

final stockAlertCountProvider = Provider<int>((ref) {
  final productosAsync = ref.watch(productosStreamProvider);
  return productosAsync.when(
    data: (productos) => productos
        .where((p) => p.cantidad <= (p.umbralAlerta ?? 5) && p.cantidad > 0)
        .length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final lowStockCountProvider = Provider<int>((ref) {
  final productosAsync = ref.watch(productosStreamProvider);
  return productosAsync.when(
    data: (productos) => productos.where((p) => p.cantidad <= 0).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final totalVentasProvider = Provider<double>((ref) {
  final ventasAsync = ref.watch(ventasStreamProvider);
  return ventasAsync.when(
    data: (ventas) => ventas.fold(0.0, (sum, v) => sum + v.total),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

final totalProductosProvider = Provider<int>((ref) {
  final productosAsync = ref.watch(productosStreamProvider);
  return productosAsync.when(
    data: (productos) => productos.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final totalClientesProvider = Provider<int>((ref) {
  final clientesAsync = ref.watch(clientesStreamProvider);
  return clientesAsync.when(
    data: (clientes) => clientes.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final recientesVentasProvider = Provider<AsyncValue<List<Venta>>>((ref) {
  final ventasAsync = ref.watch(ventasStreamProvider);
  return ventasAsync.whenData((ventas) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return ventas.where((v) => v.fechaVenta.isAfter(weekAgo)).take(10).toList();
  });
});
