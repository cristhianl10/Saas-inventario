import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../utils/pdf_helper.dart';
import 'tabla_precios_screen.dart';

String _parsePrice(String value) {
  if (value.isEmpty) return value;
  String parsed = value.replaceAll(',', '.');
  final regex = RegExp(r'^\d*\.?\d*$');
  if (!regex.hasMatch(parsed)) return '';
  return parsed;
}

enum FiltroStock { todos, enStock, sinStock, stockBajo }

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
  List<Producto> _allProductos = []; // Para validación de duplicados global
  List<Categoria> _categorias = [];
  List<Proveedor> _proveedores = [];
  List<PrecioTarifa> _tarifas = [];
  List<ComboItem> _comboItems = []; // Agregar carga de combo items
  Map<int, List<ComboItem>> _comboItemsMap =
      {}; // Mapa para almacenar los items de cada combo (comboId -> items)
  bool _isLoading = true;
  String? _error;
  FiltroStock _filtroActual = FiltroStock.todos;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  Proveedor? _proveedorSeleccionadoFiltro;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _loadProductos();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showScrollToTop) {
        setState(() => _showScrollToTop = show);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProductos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final allProductos = await _apiService.getProductos();
      List<Producto> productos;
      if (widget.categoria != null) {
        productos = allProductos
            .where((p) => p.categoriaId == widget.categoria!.id)
            .toList();
      } else {
        productos = allProductos;
      }
      final categorias = await _apiService.getCategorias();
      final proveedores = await _apiService.getProveedores();
      final tarifas = await _apiService.getTodasTarifas();

      // Cargar items de los combos para calcular stock dinámico
      final combos = productos.where((p) => p.esCombo).toList();
      final itemsMap = <int, List<ComboItem>>{};
      for (final combo in combos) {
        if (combo.id != null) {
          final items = await _apiService.getComboItems(combo.id!);
          itemsMap[combo.id!] = items;
        }
      }

      setState(() {
        _productos = productos;
        _allProductos = allProductos;
        _categorias = categorias;
        _proveedores = proveedores;
        _tarifas = tarifas;
        _comboItemsMap = itemsMap;
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
        break;
      case FiltroStock.enStock:
        productosFiltrados = _productos
            .where((p) => _getStockProducto(p) > 0)
            .toList();
        break;
      case FiltroStock.sinStock:
        productosFiltrados = _productos
            .where((p) => _getStockProducto(p) == 0)
            .toList();
        break;
      case FiltroStock.stockBajo:
        productosFiltrados = _productos.where((p) {
          final umbral = p.umbralAlerta ?? 5;
          return _getStockProducto(p) > 0 && _getStockProducto(p) <= umbral;
        }).toList();
        break;
    }

    if (_searchQuery.isNotEmpty) {
      productosFiltrados = productosFiltrados
          .where(
            (p) =>
                p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (p.descripcion?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    if (_proveedorSeleccionadoFiltro != null) {
      productosFiltrados = productosFiltrados
          .where((p) => p.proveedorId == _proveedorSeleccionadoFiltro!.id)
          .toList();
    }

    // Ordenar por nombre de categoría
    productosFiltrados.sort((a, b) {
      final catA =
          _categorias.where((c) => c.id == a.categoriaId).firstOrNull?.nombre ??
          '';
      final catB =
          _categorias.where((c) => c.id == b.categoriaId).firstOrNull?.nombre ??
          '';
      return catA.compareTo(catB);
    });

    _productosFiltrados = productosFiltrados;
  }

  /// Obtiene el stock de un producto. Para combos, calcula el stock dinámico.
  int _getStockProducto(Producto producto) {
    if (!producto.esCombo) {
      return producto.cantidad;
    }
    return _calcularStockCombo(producto);
  }

  /// Calcula el stock disponible de un combo basado en sus productos
  int _calcularStockCombo(Producto combo) {
    final items = _comboItemsMap[combo.id] ?? [];
    if (items.isEmpty) return 0;

    int stockMinimo = double.maxFinite.toInt();
    bool sinStock = false;

    for (final item in items) {
      final producto = _allProductos
          .where((p) => p.id == item.productoId)
          .firstOrNull;
      if (producto != null) {
        if (producto.cantidad == 0) {
          sinStock = true;
          break;
        }
        final combosPosibles = (producto.cantidad / item.cantidad).floor();
        if (combosPosibles < stockMinimo) {
          stockMinimo = combosPosibles;
        }
      }
    }

    if (sinStock) return 0;
    return stockMinimo == double.maxFinite.toInt() ? 0 : stockMinimo;
  }

  Future<void> _deleteProducto(Producto producto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar producto?'),
        content: Text('${producto.nombre} será eliminado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteProducto(producto.id!);
        await _apiService.deleteTarifasPorProducto(producto.id!);
        _loadProductos();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto eliminado'),
              backgroundColor: SubliriumColors.stockOkText,
            ),
          );
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
      await _apiService.updateProducto(
        producto.copyWith(cantidad: nuevaCantidad),
      );
      _loadProductos();
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
    final observacionesController = TextEditingController();
    DateTime fechaSeleccionada = DateTime.now();
    bool precioPorUnidad = true;

    List<Cliente> _clientes = [];
    Cliente? _clienteSeleccionado;
    bool _loadingClientes = true;
    bool _mostrarCrearCliente = false;
    final _nombreClienteController = TextEditingController();
    final _telefonoClienteController = TextEditingController();

    Future<void> _cargarClientes() async {
      try {
        final clientes = await _apiService.getClientes();
        if (mounted) {
          setState(() {
            _clientes = clientes;
            _loadingClientes = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _loadingClientes = false);
        }
      }
    }

    Future<Cliente?> _crearCliente(String nombre, String? telefono) async {
      try {
        final cliente = await _apiService.createCliente(
          Cliente(nombre: nombre, telefono: telefono),
        );
        await _cargarClientes();
        return cliente;
      } catch (e) {
        return null;
      }
    }

    _cargarClientes();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (producto.descripcion != null)
                    Text(
                      producto.descripcion!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  const SizedBox(height: 16),
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
                  Row(
                    children: [
                      Text(
                        'Precio por unidad',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white : Colors.black,
                        ),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                          selection: TextSelection.collapsed(
                            offset: parsed.length,
                          ),
                        );
                      }
                      setDialogState(() {});
                    },
                  ),
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
                        Text(
                          'Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.black : Colors.black,
                          ),
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
                  if (_loadingClientes)
                    const Center(child: CircularProgressIndicator())
                  else if (_mostrarCrearCliente)
                    Column(
                      children: [
                        TextField(
                          controller: _nombreClienteController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del cliente',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _telefonoClienteController,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono (opcional)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  _mostrarCrearCliente = false;
                                  _nombreClienteController.clear();
                                  _telefonoClienteController.clear();
                                });
                              },
                              child: const Text('Cancelar'),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () async {
                                final nombre = _nombreClienteController.text
                                    .trim();
                                if (nombre.isEmpty) return;
                                final telefono = _telefonoClienteController.text
                                    .trim();
                                final nuevoCliente = await _crearCliente(
                                  nombre,
                                  telefono.isEmpty ? null : telefono,
                                );
                                if (nuevoCliente != null && mounted) {
                                  setDialogState(() {
                                    _clienteSeleccionado = nuevoCliente;
                                    _mostrarCrearCliente = false;
                                    _nombreClienteController.clear();
                                    _telefonoClienteController.clear();
                                  });
                                }
                              },
                              child: const Text('Crear'),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Cliente>(
                            value: _clienteSeleccionado,
                            decoration: const InputDecoration(
                              labelText: 'Cliente',
                              border: OutlineInputBorder(),
                            ),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<Cliente>(
                                value: null,
                                child: Text('Sin cliente'),
                              ),
                              ..._clientes.map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.nombre),
                                ),
                              ),
                            ],
                            onChanged: (cliente) {
                              setDialogState(
                                () => _clienteSeleccionado = cliente,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Nuevo cliente',
                          onPressed: () {
                            setDialogState(() => _mostrarCrearCliente = true);
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
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
                child: ElevatedButton(
                  onPressed: () async {
                    final cantidadVenta =
                        int.tryParse(cantidadController.text) ?? 1;
                    final precioText = _parsePrice(precioController.text);
                    final precioUnit = double.tryParse(precioText) ?? 0;

                    // Validar stock para productos normales
                    if (!producto.esCombo &&
                        (cantidadVenta <= 0 ||
                            cantidadVenta > producto.cantidad)) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Cantidad inválida. Máximo disponible: ${producto.cantidad}',
                          ),
                        ),
                      );
                      return;
                    }

                    // Validar stock para combos usando stock calculado
                    if (producto.esCombo) {
                      final stockCalculado = _getStockProducto(producto);
                      if (cantidadVenta <= 0 ||
                          cantidadVenta > stockCalculado) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cantidad inválida. Máximo disponible: $stockCalculado',
                            ),
                          ),
                        );
                        return;
                      }
                    }
                    if (precioUnit <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Ingrese un precio válido'),
                        ),
                      );
                      return;
                    }

                    // Validar stock de productos del combo
                    if (producto.esCombo) {
                      final comboItems = await _apiService.getComboItems(
                        producto.id!,
                      );
                      for (final item in comboItems) {
                        final prod = _productos
                            .where((p) => p.id == item.productoId)
                            .firstOrNull;
                        if (prod == null) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'El producto #${item.productoId} del combo no está disponible en inventario',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        final requerido = item.cantidad * cantidadVenta;
                        if (prod.cantidad < requerido) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Stock insuficiente de "${prod.nombre}". Necesitas $requerido, tienes ${prod.cantidad}',
                              ),
                            ),
                          );
                          return;
                        }
                      }
                    }

                    final venta = Venta(
                      productoId: producto.id!,
                      cantidad: cantidadVenta,
                      precioUnitario: precioUnit,
                      total: total,
                      fechaVenta: fechaSeleccionada,
                      clienteId: _clienteSeleccionado?.id,
                      vendidoA: _clienteSeleccionado?.nombre,
                      observaciones: observacionesController.text.trim().isEmpty
                          ? null
                          : observacionesController.text.trim(),
                    );

                    try {
                      await _apiService.createVenta(venta);

                      // Descontar stock
                      if (producto.esCombo) {
                        await _apiService.descontarStockCombo(
                          producto.id!,
                          cantidadVenta,
                        );
                      } else {
                        final productoActualizado = producto.copyWith(
                          cantidad: producto.cantidad - cantidadVenta,
                          fechaActualizacion: DateTime.now(),
                        );
                        await _apiService.updateProducto(productoActualizado);
                      }

                      _loadProductos();
                      if (mounted) Navigator.pop(dialogContext);
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              producto.esCombo
                                  ? 'Combo vendido: $cantidadVenta por \$${total.toStringAsFixed(2)}'
                                  : 'Vendido: $cantidadVenta unidad(es) por \$${total.toStringAsFixed(2)}',
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
      text: (producto?.cantidad ?? 0).toString(),
    );
    final precioController = TextEditingController(
      text: producto?.precio?.toStringAsFixed(2) ?? '',
    );
    final costoController = TextEditingController(
      text: producto?.costo?.toStringAsFixed(2) ?? '',
    );
    final umbralController = TextEditingController(
      text: (producto?.umbralAlerta ?? 5).toString(),
    );
    final isEditing = producto != null;
    Proveedor? proveedorSeleccionado;

    if (producto?.proveedorId != null) {
      proveedorSeleccionado = _proveedores
          .where((p) => p.id == producto!.proveedorId)
          .firstOrNull;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Proveedor?>(
                            value: proveedorSeleccionado,
                            decoration: const InputDecoration(
                              labelText: 'Proveedor',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<Proveedor?>(
                                value: null,
                                child: Text('Sin proveedor'),
                              ),
                              ..._proveedores.map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.nombre),
                                ),
                              ),
                            ],
                            onChanged: (value) => setDialogState(
                              () => proveedorSeleccionado = value,
                            ),
                          ),
                        ),
                        if (proveedorSeleccionado != null)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: SubliriumColors.deleteText,
                            ),
                            tooltip: 'Eliminar proveedor',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: dialogContext,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('¿Eliminar proveedor?'),
                                  content: Text(
                                    'Se eliminará "${proveedorSeleccionado!.nombre}".',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            SubliriumColors.deleteText,
                                      ),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await _apiService.deleteProveedor(
                                    proveedorSeleccionado!.id!,
                                  );
                                  await _loadProductos();
                                  setDialogState(
                                    () => proveedorSeleccionado = null,
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: SubliriumColors.cyan,
                          ),
                          tooltip: 'Agregar proveedor',
                          onPressed: () async {
                            final nuevoProv =
                                await _mostrarDialogoAgregarProveedor(
                                  dialogContext,
                                );
                            if (nuevoProv != null) {
                              try {
                                final np = await _apiService.createProveedor(
                                  nuevoProv,
                                );
                                await _loadProductos();
                                setDialogState(
                                  () => proveedorSeleccionado = np,
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: costoController,
                      decoration: const InputDecoration(
                        labelText: 'Costo',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: umbralController,
                      decoration: const InputDecoration(
                        labelText: 'Alerta stock bajo (umbral)',
                        border: OutlineInputBorder(),
                        helperText: 'Cantidad mínima antes de alertar',
                        prefixIcon: Icon(
                          Icons.warning_amber_outlined,
                          size: 20,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final nombre = nombreController.text.trim();
                    if (nombre.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('El nombre es obligatorio'),
                        ),
                      );
                      return;
                    }

                    // Verificar si ya existe un producto con ese nombre (globalmente)
                    final existe = _allProductos.any(
                      (p) =>
                          p.nombre.toLowerCase() == nombre.toLowerCase() &&
                          p.id != producto?.id,
                    );

                    if (existe) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('El producto "$nombre" ya existe'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    final cantidad =
                        int.tryParse(cantidadController.text.trim()) ?? 0;
                    final precio =
                        double.tryParse(
                          _parsePrice(precioController.text.trim()),
                        ) ??
                        0.0;
                    final costo =
                        double.tryParse(
                          _parsePrice(costoController.text.trim()),
                        ) ??
                        0.0;
                    final umbralAlerta =
                        int.tryParse(umbralController.text.trim()) ?? 5;
                    final nuevoProducto = Producto(
                      id: producto?.id,
                      categoriaId:
                          widget.categoria?.id ?? producto?.categoriaId ?? 1,
                      nombre: nombre,
                      descripcion: descripcionController.text.trim().isEmpty
                          ? null
                          : descripcionController.text.trim(),
                      cantidad: cantidad,
                      precio: precio,
                      proveedorId: proveedorSeleccionado?.id,
                      costo: costo,
                      umbralAlerta: umbralAlerta,
                      fechaActualizacion: DateTime.now(),
                    );
                    try {
                      if (isEditing) {
                        await _apiService.updateProducto(nuevoProducto);
                      } else {
                        await _apiService.createProducto(nuevoProducto);
                      }
                      _loadProductos();
                      Navigator.pop(dialogContext);
                    } catch (e) {
                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: Text(isEditing ? 'Actualizar' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Proveedor?> _mostrarDialogoAgregarProveedor(
    BuildContext context,
  ) async {
    final nombreController = TextEditingController();
    final telefonoController = TextEditingController();

    return showDialog<Proveedor>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Proveedor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nombre = nombreController.text.trim();
              if (nombre.isEmpty) return;

              // Verificar si ya existe un proveedor con ese nombre
              final existe = _proveedores.any(
                (p) => p.nombre.toLowerCase() == nombre.toLowerCase(),
              );

              if (existe) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('El proveedor "$nombre" ya existe'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(
                context,
                Proveedor(
                  nombre: nombre,
                  telefono: telefonoController.text.trim().isEmpty
                      ? null
                      : telefonoController.text.trim(),
                ),
              );
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  int get _totalInventario => _productos.fold(0, (sum, p) => sum + p.cantidad);

  @override
  Widget build(BuildContext context) {
    final bool esVistaGlobal = widget.categoria == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 90,
            floating: false,
            pinned: true,
            centerTitle: true,
            automaticallyImplyLeading: !esVistaGlobal,
            leading: !esVistaGlobal
                ? Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                esVistaGlobal
                    ? 'Todos los Productos'
                    : (widget.categoria?.nombre ?? 'Productos'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppConfig.secondaryColor, AppConfig.primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadProductos,
                tooltip: 'Actualizar',
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                onPressed: _generarPdfProductos,
                tooltip: 'Descargar PDF',
              ),
              IconButton(
                icon: const Icon(Icons.table_chart, color: Colors.white),
                onPressed: _exportarExcelProductos,
                tooltip: 'Exportar Excel',
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
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '$_totalInventario unidades',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  if (esVistaGlobal) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {
                        _searchQuery = value;
                        _aplicarFiltro();
                      }),
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Buscar producto...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.white70 : SubliriumColors.cyan,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF3A3A3A)
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.grey[600]!
                                : SubliriumColors.border,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.grey[600]!
                                : SubliriumColors.border,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: SubliriumColors.cyan,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
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
                        const SizedBox(width: 8),
                        _buildFiltroChip('Stock bajo', FiltroStock.stockBajo),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Proveedor?>(
                      value: _proveedorSeleccionadoFiltro,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      dropdownColor: isDark
                          ? const Color(0xFF1A1A1A)
                          : Theme.of(context).cardColor,
                      iconEnabledColor: isDark ? Colors.white : Colors.black54,
                      decoration: InputDecoration(
                        labelText: 'Filtrar por proveedor',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.grey[600]!
                                : Colors.grey[400]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.grey[600]!
                                : Colors.grey[400]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white : SubliriumColors.cyan,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1A1A1A)
                            : Colors.white,
                      ),
                      items: [
                        DropdownMenuItem<Proveedor?>(
                          value: null,
                          child: Text(
                            'Todos los proveedores',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        ..._proveedores.map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p.nombre,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        _proveedorSeleccionadoFiltro = value;
                        _aplicarFiltro();
                      }),
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
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No hay productos',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _buildProductosAgrupados();
                }, childCount: 1),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showScrollToTop) ...[
            FloatingActionButton.small(
              onPressed: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
              backgroundColor: SubliriumColors.cyan.withValues(alpha: 0.8),
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            heroTag: 'add_product_btn',
            onPressed: () => _showProductoDialog(),
            backgroundColor: SubliriumColors.cyan,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProductosAgrupados() {
    final Map<int, List<Producto>> productosPorCategoria = {};
    for (final producto in _productosFiltrados) {
      productosPorCategoria
          .putIfAbsent(producto.categoriaId, () => [])
          .add(producto);
    }

    final categoriasOrdenadas = _categorias
        .where((c) => productosPorCategoria.containsKey(c.id))
        .toList();

    // Include products with unknown categories
    final categoriaIdsConocidos = categoriasOrdenadas.map((c) => c.id).toSet();
    final sinCategoria = _productosFiltrados
        .where((p) => !categoriaIdsConocidos.contains(p.categoriaId))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...categoriasOrdenadas.map((categoria) {
          final productos = productosPorCategoria[categoria.id]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: SubliriumColors.headerGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  categoria.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...productos.map((p) => _buildProductoCard(p)),
              const SizedBox(height: 8),
            ],
          );
        }),
        if (sinCategoria.isNotEmpty)
          ...sinCategoria.map((p) => _buildProductoCard(p)),
      ],
    );
  }

  Widget _buildProductoCard(Producto producto) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Usar stock calculado para combos (dinámico) o cantidad directa para productos normales
    final stockReal = _getStockProducto(producto);
    final bool esCombo = producto.esCombo;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey[700]! : SubliriumColors.border,
          width: 1.5,
        ),
      ),
      elevation: isDark ? 4 : 2,
      shadowColor: isDark ? Colors.black : Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(producto.nombre, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      if (producto.descripcion != null)
                        Text(
                          producto.descripcion!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (producto.precio != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: SubliriumColors.inputFocusedBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${producto.precio!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppConfig.secondaryColor,
                          ),
                        ),
                      ),
                    if (producto.costo != null)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: SubliriumColors.naranja.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Costo: \$${producto.costo!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppConfig.accentColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (producto.proveedorId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 14,
                    color: theme.iconTheme.color?.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getNombreProveedor(producto.proveedorId),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStockBadge(
                  stockReal,
                  umbralAlerta: producto.umbralAlerta,
                ),
                const SizedBox(width: 8),
                // Para combos: mostrar solo el número de stock calculado (sin botones +/-)
                // Para productos normales: mostrar controles de cantidad
                if (esCombo)
                  Container(
                    decoration: BoxDecoration(
                      color: stockReal > 0
                          ? SubliriumColors.stockOkBg
                          : SubliriumColors.stockZeroBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      stockReal > 0 ? 'Stock: $stockReal' : 'Sin stock',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: stockReal > 0
                            ? SubliriumColors.stockOkText
                            : SubliriumColors.stockZeroText,
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: producto.cantidad > 0
                          ? SubliriumColors.stockOkBg
                          : SubliriumColors.stockZeroBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: producto.cantidad > 0
                              ? () => _updateCantidad(producto, -1)
                              : null,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.remove,
                              size: 14,
                              color: producto.cantidad > 0
                                  ? SubliriumColors.stockOkText
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '${producto.cantidad}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: producto.cantidad > 0
                                  ? SubliriumColors.stockOkText
                                  : SubliriumColors.stockZeroText,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _updateCantidad(producto, 1),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 14,
                              color: SubliriumColors.stockOkText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // Botones de acción más compactos
                Wrap(
                  spacing: 4,
                  children: [
                    _buildActionButton(
                      icon: Icons.point_of_sale_outlined,
                      color: AppConfig.secondaryColor,
                      bgColor: AppConfig.secondaryColor.withValues(alpha: 0.1),
                      onTap: () => _showVendidoDialog(producto),
                      tooltip: 'Venta',
                    ),
                    if (!producto.esCombo)
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        color: AppConfig.secondaryColor,
                        bgColor: SubliriumColors.inputFocusedBg,
                        onTap: () => _showProductoDialog(producto),
                        tooltip: 'Editar',
                      ),
                    _buildActionButton(
                      icon: Icons.attach_money,
                      color: AppConfig.accentColor,
                      bgColor: SubliriumColors.naranja.withValues(alpha: 0.15),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TablaPreciosScreen(
                              productoIdInicial: producto.id,
                              categoriaIdInicial: producto.categoriaId,
                            ),
                          ),
                        );
                      },
                      tooltip: 'Tarifas',
                    ),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      color: SubliriumColors.stockLowText,
                      bgColor: SubliriumColors.stockLowBg,
                      onTap: () => _deleteProducto(producto),
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockBadge(int cantidad, {int? umbralAlerta}) {
    final bool hayStock = cantidad > 0;
    final umbral = umbralAlerta ?? 5;
    final bool stockBajo = hayStock && cantidad <= umbral;

    String texto;
    Color bgColor;
    Color textColor;

    if (!hayStock) {
      texto = 'Sin stock';
      bgColor = SubliriumColors.stockLowBg;
      textColor = SubliriumColors.deleteText;
    } else if (stockBajo) {
      texto = 'Stock bajo';
      bgColor = SubliriumColors.naranja.withValues(alpha: 0.2);
      textColor = SubliriumColors.naranja;
    } else {
      texto = 'En stock';
      bgColor = SubliriumColors.stockOkBg;
      textColor = SubliriumColors.stockOkText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stockBajo) ...[
            Icon(Icons.warning_amber, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String label, FiltroStock filtro) {
    final bool activo = _filtroActual == filtro;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() {
        _filtroActual = filtro;
        _aplicarFiltro();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? SubliriumColors.cyan : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activo ? SubliriumColors.cyan : SubliriumColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: activo ? Colors.white : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  String _getNombreCategoria(int categoriaId) {
    final cat = _categorias.where((c) => c.id == categoriaId).firstOrNull;
    return cat?.nombre ?? 'Sin categoría';
  }

  String _getNombreProveedor(int? proveedorId) {
    if (proveedorId == null) return 'Sin proveedor';
    final prov = _proveedores.where((p) => p.id == proveedorId).firstOrNull;
    return prov?.nombre ?? 'Sin proveedor';
  }

  double _getPrecioBaseProducto(int productoId) {
    final tarifa = _tarifas
        .where((t) => t.productoId == productoId && t.cantidadMin == 1)
        .firstOrNull;
    return tarifa?.precioUnitario ?? 0;
  }

  Future<void> _exportarExcelProductos() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando archivo Excel...')),
      );

      final excel = Excel.createExcel();
      final sheet = excel['Inventario'];
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final productosAExportar = widget.categoria != null
          ? _productos
          : _productosFiltrados;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = TextCellValue(
        'Inventario de Productos',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
          .value = TextCellValue(
        'Generado: ${dateStr}',
      );

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
          .value = TextCellValue(
        'Producto',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
          .value = TextCellValue(
        'Categoría',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 3))
          .value = TextCellValue(
        'Stock',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 3))
          .value = TextCellValue(
        'Precio',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 3))
          .value = TextCellValue(
        'Costo',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 3))
          .value = TextCellValue(
        'Proveedor',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 3))
          .value = TextCellValue(
        'Umbral Alerta',
      );

      int row = 4;
      for (final producto in productosAExportar) {
        final categoria = _categorias
            .where((c) => c.id == producto.categoriaId)
            .firstOrNull;
        final proveedor = _proveedores
            .where((p) => p.id == producto.proveedorId)
            .firstOrNull;
        final precioBase = _getPrecioBaseProducto(producto.id!);

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(
          producto.nombre,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(
          categoria?.nombre ?? 'Sin categoría',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = IntCellValue(
          producto.cantidad,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = DoubleCellValue(
          precioBase,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = DoubleCellValue(
          producto.costo ?? 0.0,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = TextCellValue(
          proveedor?.nombre ?? '-',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
            .value = IntCellValue(
          producto.umbralAlerta ?? 5,
        );
        row++;
      }

      final bytes = excel.encode();
      if (bytes != null) {
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Excel generado (usa la función de compartir para guardarlo)',
              ),
            ),
          );
        } else {
          final dir = Directory.systemTemp;
          final file = File('${dir.path}/inventario_$dateStr.xlsx');
          await file.writeAsBytes(bytes);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Guardado: ${file.path}')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generarPdfProductos() async {
    await PdfHelper.loadLogo();
    final pdf = pw.Document();
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final productosAExportar = widget.categoria != null
        ? _productos
        : _productosFiltrados;

    final subtitleContext = <String>[];
    if (widget.categoria != null)
      subtitleContext.add('Categoría: ${widget.categoria!.nombre}');
    if (_filtroActual == FiltroStock.enStock)
      subtitleContext.add('Filtro: En stock');
    if (_filtroActual == FiltroStock.sinStock)
      subtitleContext.add('Filtro: Sin stock');
    if (_proveedorSeleccionadoFiltro != null)
      subtitleContext.add('Proveedor: ${_proveedorSeleccionadoFiltro!.nombre}');
    final subtitleInfo = subtitleContext.isEmpty
        ? 'Todos los productos'
        : subtitleContext.join(' | ');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => PdfHelper.buildHeader(
          title: 'Inventario de Productos',
          subtitle: subtitleInfo,
        ),
        footer: (context) => PdfHelper.buildFooter(),
        build: (context) => [
          pw.SizedBox(height: 20),
          if (widget.categoria == null) ...[
            for (final categoria in _categorias.where(
              (c) => productosAExportar.any((p) => p.categoriaId == c.id),
            ))
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.cyan100,
                    ),
                    child: pw.Text(
                      categoria.nombre,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _buildProductosTable(
                    productosAExportar
                        .where((p) => p.categoriaId == categoria.id)
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
            _buildProductosTable(productosAExportar),
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

    final filtros = <String>[];
    if (widget.categoria != null)
      filtros.add(widget.categoria!.nombre.replaceAll(' ', '_'));
    if (_filtroActual == FiltroStock.enStock) filtros.add('en_stock');
    if (_filtroActual == FiltroStock.sinStock) filtros.add('sin_stock');
    if (_proveedorSeleccionadoFiltro != null)
      filtros.add(
        'prov_${_proveedorSeleccionadoFiltro!.nombre.replaceAll(' ', '_')}',
      );
    if (_searchQuery.isNotEmpty)
      filtros.add('busq_${_searchQuery.replaceAll(' ', '_')}');

    final fechaArchivo = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final sufijo = filtros.isEmpty ? '' : '_${filtros.join('_')}';
    final nombreArchivo = 'inventario$sufijo\_$fechaArchivo';

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '$nombreArchivo.pdf',
    );
  }

  double _calcularTotalCategoria(List<Producto> productos) {
    return productos.fold(
      0.0,
      (sum, p) => sum + _getPrecioBaseProducto(p.id!) * p.cantidad,
    );
  }

  pw.Widget _buildProductosTable(List<Producto> productos) {
    const flexPro = 3.0;
    const flexCos = 2.0;
    const flexPrv = 3.0;
    const flexCant = 2.0; // Increased to avoid wrapping
    const flexPre = 2.0;

    pw.Widget buildCell(
      String text,
      double flex, {
      bool isHeader = false,
      bool isRight = false,
    }) {
      return pw.Expanded(
        flex: (flex * 10).toInt(),
        child: pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            text,
            textAlign: isRight ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: isHeader ? 10 : 9,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return pw.Column(
      children: [
        // Header Row - Full Bordered
        pw.Container(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300),
              left: pw.BorderSide(color: PdfColors.grey300),
              right: pw.BorderSide(color: PdfColors.grey300),
              bottom: pw.BorderSide(color: PdfColors.grey300),
            ),
          ),
          child: pw.Row(
            children: [
              buildCell('Producto', flexPro, isHeader: true),
              buildCell('Costo', flexCos, isHeader: true, isRight: true),
              buildCell('Proveedor', flexPrv, isHeader: true),
              buildCell('Cantidad', flexCant, isHeader: true, isRight: true),
              buildCell('Precio Base', flexPre, isHeader: true, isRight: true),
            ],
          ),
        ),
        // Data Rows
        ...productos.map((p) {
          final precioBase = _getPrecioBaseProducto(p.id!);
          return pw.Column(
            children: [
              // Main Data Row - Side and Bottom Border
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.grey300),
                    right: pw.BorderSide(color: PdfColors.grey300),
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                child: pw.Row(
                  children: [
                    buildCell(p.nombre, flexPro),
                    buildCell(
                      '\$${p.costo?.toStringAsFixed(2) ?? "0.00"}',
                      flexCos,
                      isRight: true,
                    ),
                    buildCell(_getNombreProveedor(p.proveedorId), flexPrv),
                    buildCell(p.cantidad.toString(), flexCant, isRight: true),
                    buildCell(
                      '\$${precioBase.toStringAsFixed(2)}',
                      flexPre,
                      isRight: true,
                    ),
                  ],
                ),
              ),
              // Description Row - Side and Bottom Border
              if (p.descripcion != null && p.descripcion!.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey50,
                    border: pw.Border(
                      left: pw.BorderSide(color: PdfColors.grey300),
                      right: pw.BorderSide(color: PdfColors.grey300),
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'Descripción: ',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.TextSpan(
                          text: p.descripcion!,
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}
