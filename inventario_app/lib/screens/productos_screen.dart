import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';

class ProductosScreen extends StatefulWidget {
  final Categoria categoria;
  const ProductosScreen({super.key, required this.categoria});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ApiService _apiService = ApiService();
  List<Producto> _productos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final productos = await _apiService.getProductosPorCategoria(
        widget.categoria.id!,
      );
      setState(() {
        _productos = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProducto(Producto producto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar producto?'),
        content: Text('Vas a eliminar "${producto.nombre}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: SubliriumColors.deleteText,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true && producto.id != null) {
      try {
        await _apiService.deleteProducto(producto.id!);
        _loadProductos();
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Producto eliminado')));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateCantidad(Producto producto, int cambio) async {
    final nuevaCantidad = producto.cantidad + cambio;
    if (nuevaCantidad < 0) return;
    try {
      final productoActualizado = producto.copyWith(
        cantidad: nuevaCantidad,
        fechaActualizacion: DateTime.now(),
      );
      await _apiService.updateProducto(productoActualizado);
      _loadProductos();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showProductoDialog([Producto? producto]) {
    final nombreController = TextEditingController(
      text: producto?.nombre ?? '',
    );
    final descripcionController = TextEditingController(
      text: producto?.descripcion ?? '',
    );
    final cantidadController = TextEditingController(
      text: producto?.cantidad.toString() ?? '0',
    );
    final isEditing = producto != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreController.text.trim();
              if (nombre.isEmpty) return;
              final cantidad =
                  int.tryParse(cantidadController.text.trim()) ?? 0;
              final nuevoProducto = Producto(
                id: producto?.id,
                categoriaId: widget.categoria.id!,
                nombre: nombre,
                descripcion: descripcionController.text.trim().isEmpty
                    ? null
                    : descripcionController.text.trim(),
                cantidad: cantidad,
                fechaActualizacion: DateTime.now(),
              );
              try {
                if (isEditing) {
                  await _apiService.updateProducto(nuevoProducto);
                } else {
                  await _apiService.createProducto(nuevoProducto);
                }
                _loadProductos();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(isEditing ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  int get _totalInventario => _productos.fold(0, (sum, p) => sum + p.cantidad);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 90,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.categoria.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: SubliriumColors.headerGradient,
                ),
              ),
            ),
            actions: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getCategoryColor(widget.categoria.emoji),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    widget.categoria.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFF9F8F5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total en inventario:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '$_totalInventario unidades',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: SubliriumColors.cardBackground,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 12),
                    Icon(
                      Icons.search,
                      size: 16,
                      color: Colors.black,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Buscar...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      size: 48,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadProductos,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else if (_productos.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sin productos',
                      style: TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toca + para agregar',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final producto = _productos[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: SubliriumColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                producto.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  color: Colors.black,
                                ),
                              ),
                              if (producto.descripcion != null)
                                Text(
                                  producto.descripcion!,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.black,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _buildStockBadge(producto.cantidad),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: producto.cantidad > 0
                                ? const Color(0xFFF0FDF4)
                                : const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: producto.cantidad > 0
                                    ? () => _updateCantidad(producto, -1)
                                    : null,
                                child: const Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: Color(0xFFE11D48),
                                ),
                              ),
                              Container(
                                constraints: const BoxConstraints(minWidth: 28),
                                alignment: Alignment.center,
                                child: Text(
                                  '${producto.cantidad}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: producto.cantidad > 0
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFE11D48),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _updateCantidad(producto, 1),
                                child: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _showProductoDialog(producto),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.edit, size: 14),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _deleteProducto(producto),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.delete,
                              size: 14,
                              color: Colors.red[300],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: _productos.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductoDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStockBadge(int cantidad) {
    if (cantidad == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '—',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF9CA3AF),
          ),
        ),
      );
    } else if (cantidad > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Stock',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: Color(0xFF16A34A),
          ),
        ),
      );
    }
    return const SizedBox();
  }

  Color _getCategoryColor(String emoji) {
    final colors = {
      '☕': const Color(0xFFFFF8F0),
      '🧊': const Color(0xFFF0FBFF),
      '🥤': const Color(0xFFF0FFF8),
      '🚰': const Color(0xFFFFFBF0),
      '👕': const Color(0xFFFDF4FF),
      '🧢': const Color(0xFFF0F8FF),
      '🖱️': const Color(0xFFF5F0FF),
      '🪨': const Color(0xFFF0FFF8),
      '👜': const Color(0xFFFFF8F0),
      '⏰': const Color(0xFFF0F8FF),
      '🖼️': const Color(0xFFFDF4FF),
      '📓': const Color(0xFFFFFBF0),
      '🔑': const Color(0xFFF0FFF8),
      '🪵': const Color(0xFFF5F0FF),
      '🛏️': const Color(0xFFFFF0F8),
    };
    return colors[emoji] ?? Colors.white;
  }
}
