import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';

class ResumenScreen extends StatefulWidget {
  const ResumenScreen({super.key});

  @override
  State<ResumenScreen> createState() => _ResumenScreenState();
}

class _ResumenScreenState extends State<ResumenScreen> {
  final ApiService _apiService = ApiService();
  List<Producto> _productos = [];
  List<Categoria> _categorias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final productos = await _apiService.getProductos();
      final categorias = await _apiService.getCategorias();
      setState(() {
        _productos = productos;
        _categorias = categorias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Producto> get _productosVendidos => _productos.where((p) => p.vendido).toList();
  List<Producto> get _productosEnStock => _productos.where((p) => p.cantidad > 0 && !p.vendido).toList();
  List<Producto> get _productosSinStock => _productos.where((p) => p.cantidad == 0 && !p.vendido).toList();

  double get _totalVentas => _productosVendidos.fold(0, (sum, p) => sum + (p.precioVenta ?? 0));
  double get _gananciaEstimada {
    double costo = 0;
    for (var p in _productosVendidos) {
      if (p.precio != null && p.precioVenta != null) {
        costo += p.precio!;
      }
    }
    return _totalVentas - costo;
  }
  int get _totalUnidadesVendidas => _productosVendidos.length;

  String _getNombreCategoria(int categoriaId) {
    final cat = _categorias.where((c) => c.id == categoriaId).firstOrNull;
    return cat?.nombre ?? 'Sin categoría';
  }

  String _getEmojiCategoria(int categoriaId) {
    final cat = _categorias.where((c) => c.id == categoriaId).firstOrNull;
    return cat?.emoji ?? '📦';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Resumen de Ventas',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: SubliriumColors.headerGradient,
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else ...[
            // Stats principales
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ESTADÍSTICAS GENERALES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: SubliriumColors.textSecondary, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    Row(children: [
                      _buildStatCard('Total Ventas', '\$${_totalVentas.toStringAsFixed(2)}', Icons.attach_money, SubliriumColors.stockOkText),
                      const SizedBox(width: 12),
                      _buildStatCard('Unidades Vendidas', '$_totalUnidadesVendidas', Icons.shopping_bag, SubliriumColors.cyan),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      _buildStatCard('Ganancia Est.', '\$${_gananciaEstimada.toStringAsFixed(2)}', Icons.trending_up, SubliriumColors.purple),
                      const SizedBox(width: 12),
                      _buildStatCard('En Stock', '${_productosEnStock.length}', Icons.inventory, SubliriumColors.logoOrange),
                    ]),
                  ],
                ),
              ),
            ),
            // Lista de ventas
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('REGISTRO DE VENTAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: SubliriumColors.textSecondary, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    if (_productosVendidos.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: SubliriumColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SubliriumColors.border),
                        ),
                        child: const Center(
                          child: Column(children: [
                            Icon(Icons.receipt_long, size: 40, color: SubliriumColors.textSecondary),
                            SizedBox(height: 8),
                            Text('No hay ventas registradas', style: TextStyle(color: SubliriumColors.textSecondary)),
                          ]),
                        ),
                      )
                    else
                      ...(_productosVendidos.map((p) => _buildVentaCard(p))),
                  ],
                ),
              ),
            ),
            // Productos en stock
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PRODUCTOS EN INVENTARIO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: SubliriumColors.textSecondary, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    _buildResumenCard('En Stock', _productosEnStock.length, _totalInventarioStock, SubliriumColors.stockOkText),
                    const SizedBox(height: 8),
                    _buildResumenCard('Sin Stock', _productosSinStock.length, 0, SubliriumColors.stockLowText),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
    );
  }

  int get _totalInventarioStock => _productosEnStock.fold(0, (sum, p) => sum + p.cantidad);

  Widget _buildStatCard(String titulo, String valor, IconData icono, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SubliriumColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SubliriumColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color, size: 24),
            const SizedBox(height: 8),
            Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(titulo, style: const TextStyle(fontSize: 10, color: SubliriumColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildVentaCard(Producto producto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SubliriumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SubliriumColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: SubliriumColors.stockLowBg, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_getEmojiCategoria(producto.categoriaId), style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.person, size: 12, color: SubliriumColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(producto.vendidoA ?? 'Cliente', style: const TextStyle(fontSize: 10, color: SubliriumColors.textSecondary)),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_today, size: 12, color: SubliriumColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(producto.fechaVenta != null ? _formatFecha(producto.fechaVenta!) : '', style: const TextStyle(fontSize: 10, color: SubliriumColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${producto.precioVenta?.toStringAsFixed(2) ?? '0'}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: SubliriumColors.stockOkText)),
              Text('Costo: \$${producto.precio?.toStringAsFixed(2) ?? '0'}', style: const TextStyle(fontSize: 9, color: SubliriumColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard(String titulo, int cantidad, int unidades, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SubliriumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SubliriumColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(cantidad > 0 ? Icons.check_circle : Icons.warning, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                Text('$cantidad productos', style: const TextStyle(fontSize: 11, color: SubliriumColors.textSecondary)),
              ],
            ),
          ),
          if (unidades > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('$unidades uds', style: TextStyle(fontWeight: FontWeight.w900, color: color)),
            ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
