import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';
import '../utils/pdf_helper.dart';
import 'tabla_precios_screen.dart';

String _parsePrice(String value) {
  if (value.isEmpty) return value;
  String parsed = value.replaceAll(',', '.');
  final regex = RegExp(r'^\d*\.?\d*$');
  if (!regex.hasMatch(parsed)) {
    return '';
  }
  return parsed;
}

int? _parseQuantity(String value) {
  if (value.isEmpty) return null;
  final parsed = int.tryParse(value.trim());
  return parsed;
}

enum FiltroStock { todos, enStock, sinStock }

class ProductosScreen extends StatefulWidget {
  final Categoria? categoria;
  const ProductosScreen({super.key, this.categoria});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ApiService _apiService = ApiService();
  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  List<Categoria> _categorias = [];
  bool _isLoading = true;
  String? _error;
  FiltroStock _filtroActual = FiltroStock.todos;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProductos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      List<Producto> productos;
      if (widget.categoria != null) {
        productos = await _apiService.getProductosPorCategoria(
          widget.categoria!.id!,
        );
      } else {
        productos = await _apiService.getProductos();
      }
      final categorias = await _apiService.getCategorias();
      setState(() {
        _productos = productos;
        _categorias = categorias;
        _aplicarFiltro();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltro() {
    var productosFiltrados = List<Producto>.from(_productos);
    
    switch (_filtroActual) {
      case FiltroStock.todos:
        productosFiltrados = List.from(_productos);
        break;
      case FiltroStock.enStock:
        productosFiltrados = _productos
            .where((p) => p.cantidad > 0)
            .toList();
        break;
      case FiltroStock.sinStock:
        productosFiltrados = _productos
            .where((p) => p.cantidad == 0)
            .toList();
        break;
    }
    
    if (_searchQuery.isNotEmpty) {
      productosFiltrados = productosFiltrados.where((p) =>
        p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (p.descripcion?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    
    _productosFiltrados = productosFiltrados;
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cantidad actualizada'), backgroundColor: SubliriumColors.stockOkText));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showVendidoDialog(Producto producto) {
    final precioController = TextEditingController(
      text: producto.precio?.toStringAsFixed(2) ?? '',
    );
    final cantidadController = TextEditingController(text: '1');
    final vendedorController = TextEditingController();
    final observacionesController = TextEditingController();
    DateTime fechaSeleccionada = DateTime.now();
    bool precioPorUnidad = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final cantidad = int.tryParse(cantidadController.text) ?? 1;
          final precio = double.tryParse(precioController.text) ?? 0;
          final total = precioPorUnidad ? (cantidad * precio) : precio;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Registrar Venta'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  if (producto.descripcion != null)
                    Text(
                      producto.descripcion!,
                      style: const TextStyle(fontSize: 11, color: Colors.black),
                    ),
                  const SizedBox(height: 16),

                  // Fecha de venta
                  GestureDetector(
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: dialogContext,
                        initialDate: fechaSeleccionada,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (fecha != null) {
                        setDialogState(() => fechaSeleccionada = fecha);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: SubliriumColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cantidad
                  TextField(
                    controller: cantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // Toggle precio
                  Row(
                    children: [
                      const Text(
                        'Precio por unidad',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      Switch(
                        value: precioPorUnidad,
                        onChanged: (v) =>
                            setDialogState(() => precioPorUnidad = v),
                        activeColor: SubliriumColors.cyan,
                      ),
                      Text(
                        precioPorUnidad ? 'x1' : 'Total',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Precio
                  TextField(
                    controller: precioController,
                    decoration: InputDecoration(
                      labelText: precioPorUnidad
                          ? 'Precio unitario'
                          : 'Precio total',
                      prefixText: '\$ ',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                    ],
                    onChanged: (value) {
                      final parsed = _parsePrice(value);
                      if (parsed != value) {
                        precioController.value = TextEditingValue(
                          text: parsed,
                          selection: TextSelection.collapsed(offset: parsed.length),
                        );
                      }
                      setDialogState(() {});
                    },
                  ),

                  // Total calculado
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SubliriumColors.stockOkBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: SubliriumColors.stockOkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cliente
                  TextField(
                    controller: vendedorController,
                    decoration: const InputDecoration(
                      labelText: 'Vendido a (cliente)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Observaciones
                  TextField(
                    controller: observacionesController,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              Container(
                decoration: BoxDecoration(
                  color: SubliriumColors.stockOkText,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:               ElevatedButton(
                  onPressed: () async {
                    final cantidadVenta =
                        int.tryParse(cantidadController.text) ?? 1;
                    final precioText = _parsePrice(precioController.text);
                    final precioUnit = double.tryParse(precioText) ?? 0;

                    if (cantidadVenta <= 0 ||
                        cantidadVenta > producto.cantidad) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Cantidad inválida. Máximo disponible: ${producto.cantidad}',
                          ),
                        ),
                      );
                      return;
                    }
                    if (precioUnit <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Ingrese un precio válido'),
                        ),
                      );
                      return;
                    }

                    // Crear venta
                    final venta = Venta(
                      productoId: producto.id!,
                      cantidad: cantidadVenta,
                      precioUnitario: precioUnit,
                      total: total,
                      fechaVenta: fechaSeleccionada,
                      vendidoA: vendedorController.text.trim().isEmpty
                          ? null
                          : vendedorController.text.trim(),
                      observaciones: observacionesController.text.trim().isEmpty
                          ? null
                          : observacionesController.text.trim(),
                    );

                    try {
                      await _apiService.createVenta(venta);

                      // Actualizar stock del producto
                      final productoActualizado = producto.copyWith(
                        cantidad: producto.cantidad - cantidadVenta,
                        fechaActualizacion: DateTime.now(),
                      );
                      await _apiService.updateProducto(productoActualizado);

                      _loadProductos();
                      if (mounted) Navigator.pop(dialogContext);
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Vendido: $cantidadVenta unidad(es) por \$${total.toStringAsFixed(2)}',
                            ),
                          ),
                        );
                    } catch (e) {
                      if (mounted)
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text(
                    'Registrar Venta',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
    final precioController = TextEditingController(
      text: producto?.precio?.toStringAsFixed(2) ?? '',
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                onChanged: (value) {
                  final parsed = _parsePrice(value);
                  if (parsed != value) {
                    precioController.value = TextEditingValue(
                      text: parsed,
                      selection: TextSelection.collapsed(offset: parsed.length),
                    );
                  }
                },
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
              if (nombre.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre es obligatorio')));
                return;
              }
              final cantidad = int.tryParse(cantidadController.text.trim());
              if (cantidad == null || cantidad < 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese una cantidad válida (número entero)')));
                return;
              }
              final precioText = _parsePrice(precioController.text.trim());
              final precio = double.tryParse(precioText);
              if (precio != null && precio < 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El precio no puede ser negativo')));
                return;
              }
              final nuevoProducto = Producto(
                id: producto?.id,
                categoriaId: widget.categoria?.id ?? producto?.categoriaId ?? 1,
                nombre: nombre,
                descripcion: descripcionController.text.trim().isEmpty
                    ? null
                    : descripcionController.text.trim(),
                cantidad: cantidad,
                precio: precio,
                fechaActualizacion: DateTime.now(),
              );
              try {
                if (isEditing) {
                  await _apiService.updateProducto(nuevoProducto);

                  // Sincronizar precio base con tarifa de cantidad = 1
                  if (precio != null) {
                    final tarifas = await _apiService.getTarifasPorProducto(producto!.id!);
                    final tarifaBase = tarifas.where((t) => t.cantidadMin == 1).firstOrNull;
                    if (tarifaBase != null) {
                      // Actualizar tarifa existente
                      await _apiService.updateTarifa(tarifaBase.copyWith(precioUnitario: precio));
                    } else {
                      // Crear nueva tarifa para cantidad = 1
                      await _apiService.createTarifa(PrecioTarifa(
                        productoId: producto!.id!,
                        cantidadMin: 1,
                        precioUnitario: precio,
                      ));
                    }
                  }

                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto actualizado con éxito'), backgroundColor: SubliriumColors.stockOkText));
                } else {
                  await _apiService.createProducto(nuevoProducto);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto creado con éxito'), backgroundColor: SubliriumColors.stockOkText));
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

  int get _totalInventario =>
      _productos.fold(0, (sum, p) => sum + p.cantidad);

  @override
  Widget build(BuildContext context) {
    final bool esVistaGlobal = widget.categoria == null;

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
                esVistaGlobal
                    ? 'Todos los Productos'
                    : (widget.categoria?.nombre ?? 'Productos'),
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
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                onPressed: _generarPdfProductos,
                tooltip: 'Descargar PDF',
              ),
              if (!esVistaGlobal) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: SubliriumColors.cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.folder,
                      size: 18,
                      color: SubliriumColors.cyan,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: SubliriumColors.background,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        esVistaGlobal
                            ? 'Total productos:'
                            : 'Total en inventario:',
                        style: const TextStyle(
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
                  if (esVistaGlobal) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _aplicarFiltro();
                        });
                      },
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Buscar producto...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: const Icon(Icons.search, color: SubliriumColors.cyan),
                        filled: true,
                        fillColor: SubliriumColors.crema,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: SubliriumColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFiltroChip('Todos', FiltroStock.todos),
                        const SizedBox(width: 8),
                        _buildFiltroChip('En stock', FiltroStock.enStock),
                        const SizedBox(width: 8),
                        _buildFiltroChip('Sin stock', FiltroStock.sinStock),
                      ],
                    ),
                  ],
                ],
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
                    const Icon(Icons.wifi_off, size: 48, color: Colors.black),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadProductos,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else if (_productosFiltrados.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sin productos',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Toca + para agregar',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final producto = _productosFiltrados[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: SubliriumColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SubliriumColors.border),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          producto.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 11,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (producto.descripcion != null)
                                    Text(
                                      producto.descripcion!,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.black,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (producto.precio != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: SubliriumColors.inputFocusedBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '\$${producto.precio!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: SubliriumColors.cyan,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStockBadge(producto.cantidad),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: producto.cantidad > 0
                                    ? SubliriumColors.stockOkBg
                                    : SubliriumColors.stockZeroBg,
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
                                      color: SubliriumColors.stockLowText,
                                      ),
                                    ),
                                    Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${producto.cantidad}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: producto.cantidad > 0
                                              ? SubliriumColors.stockOkText
                                              : SubliriumColors.stockZeroText,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _updateCantidad(producto, 1),
                                      child: const Icon(
                                        Icons.add,
                                        size: 16,
                                        color: SubliriumColors.stockOkText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _showVendidoDialog(producto),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: SubliriumColors.stockOkBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Registrar venta',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: SubliriumColors.stockOkText,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _showProductoDialog(producto),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: SubliriumColors.inputFocusedBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: SubliriumColors.cyan,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const TablaPreciosScreen()),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: SubliriumColors.naranja.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.attach_money,
                                    size: 14,
                                    color: SubliriumColors.naranja,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _deleteProducto(producto),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: SubliriumColors.stockLowBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.delete,
                                    size: 14,
                                    color: SubliriumColors.deleteText,
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
              }, childCount: _productosFiltrados.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: esVistaGlobal
          ? null
          : FloatingActionButton(
              onPressed: () => _showProductoDialog(),
              backgroundColor: SubliriumColors.stockLowText,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildFiltroChip(String label, FiltroStock filtro) {
    final bool activo = _filtroActual == filtro;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroActual = filtro;
          _aplicarFiltro();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: activo ? SubliriumColors.headerGradient : null,
          color: activo ? null : SubliriumColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activo ? Colors.transparent : SubliriumColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: activo ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(int cantidad) {
    if (cantidad == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: SubliriumColors.stockZeroBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '—',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: SubliriumColors.stockZeroText,
          ),
        ),
      );
    } else if (cantidad > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: SubliriumColors.stockOkBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Stock',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: SubliriumColors.stockOkText,
          ),
        ),
      );
    }
    return const SizedBox();
  }

  double _calcularTotalCategoria(List<Producto> productos) {
    return productos.fold(0.0, (sum, p) => sum + (p.cantidad * (p.precio ?? 0)));
  }

  String _getNombreCategoria(int categoriaId) {
    final cat = _categorias.where((c) => c.id == categoriaId).firstOrNull;
    return cat?.nombre ?? 'Sin categoría';
  }

  Future<void> _generarPdfProductos() async {
    await PdfHelper.loadLogo();
    final pdf = pw.Document();
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final productosAExportar = widget.categoria != null
        ? _productos
        : _productosFiltrados;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => PdfHelper.buildHeader(
          title: 'Inventario de Productos',
          subtitle: widget.categoria != null
              ? 'Categoría: ${widget.categoria!.nombre}'
              : 'Todos los productos',
        ),
        footer: (context) => PdfHelper.buildFooter(),
        build: (context) => [
          pw.SizedBox(height: 20),
          if (widget.categoria == null) ...[
            for (final categoria in _categorias.where((c) => productosAExportar.any((p) => p.categoriaId == c.id)))
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    color: PdfColors.cyan100,
                    child: pw.Text(
                      categoria.nombre,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.TableHelper.fromTextArray(
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.centerRight,
                      3: pw.Alignment.centerRight,
                    },
                    headers: ['Producto', 'Descripción', 'Cantidad', 'Precio c/u'],
                    data: productosAExportar
                        .where((p) => p.categoriaId == categoria.id)
                        .map((p) => [
                              p.nombre,
                              p.descripcion ?? '-',
                              p.cantidad.toString(),
                              '\$${p.precio?.toStringAsFixed(2) ?? '0.00'}',
                            ])
                        .toList(),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Total ${categoria.nombre}: \$${_calcularTotalCategoria(productosAExportar.where((p) => p.categoriaId == categoria.id).toList()).toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 16),
                ],
              ),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              color: PdfColors.cyan200,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'VALOR TOTAL DEL INVENTARIO',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '\$${_calcularTotalCategoria(productosAExportar).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              headers: ['Producto', 'Descripción', 'Cantidad', 'Precio c/u'],
              data: productosAExportar
                  .map((p) => [
                        p.nombre,
                        p.descripcion ?? '-',
                        p.cantidad.toString(),
                        '\$${p.precio?.toStringAsFixed(2) ?? '0.00'}',
                      ])
                  .toList(),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              color: PdfColors.cyan200,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'VALOR TOTAL',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '\$${_calcularTotalCategoria(productosAExportar).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'inventario_sublirium_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
