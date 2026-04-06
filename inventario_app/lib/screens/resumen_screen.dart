import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/live_sync_service.dart';
import '../services/stock_alert_service.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../utils/pdf_helper.dart';

String _parsePrice(String value) {
  if (value.isEmpty) return value;
  String parsed = value.replaceAll(',', '.');
  final regex = RegExp(r'^\d*\.?\d*$');
  if (!regex.hasMatch(parsed)) {
    return '';
  }
  return parsed;
}

class ResumenScreen extends StatefulWidget {
  const ResumenScreen({super.key});

  @override
  State<ResumenScreen> createState() => _ResumenScreenState();
}

class _ResumenScreenState extends State<ResumenScreen> {
  final ApiService _apiService = ApiService();
  final LiveSyncService _liveSyncService = LiveSyncService();
  List<Producto> _productos = [];
  List<Categoria> _categorias = [];
  List<Venta> _ventas = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupLiveUpdates();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showScrollToTop) {
        setState(() => _showScrollToTop = show);
      }
    });
  }

  @override
  void dispose() {
    _liveSyncService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupLiveUpdates() {
    _liveSyncService.watchTables(
      tables: const ['productos', 'categorias', 'ventas', 'combo_items'],
      onChange: () {
        if (mounted) {
          _loadData(showLoader: false);
        }
      },
    );
  }

  Future<void> _loadData({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _isLoading = true);
    }
    try {
      final productos = await _apiService.getProductos();
      final categorias = await _apiService.getCategorias();
      final ventas = await _apiService.getVentas();
      if (!mounted) return;
      setState(() {
        _productos = productos;
        _categorias = categorias;
        _ventas = ventas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Producto> get _productosEnStock =>
      _productos.where((p) => p.cantidad > 0).toList();
  List<Producto> get _productosSinStock =>
      _productos.where((p) => p.cantidad == 0).toList();
  List<Producto> get _productosConStockBajo =>
      StockAlertService.getProductosConStockBajo(_productos);
  int get _totalUnidadesStock =>
      _productosEnStock.fold(0, (sum, p) => sum + p.cantidad);
  double get _totalAssetsValue => _productosEnStock.fold(
    0,
    (sum, p) => sum + (p.cantidad * (p.precio ?? 0)),
  );

  double get _totalVentas => _ventas.fold(0, (sum, v) => sum + v.total);
  int get _totalUnidadesVendidas =>
      _ventas.fold(0, (sum, v) => sum + v.cantidad);

  String _getNombreProducto(int productoId) {
    final prod = _productos.where((p) => p.id == productoId).firstOrNull;
    return prod?.nombre ?? 'Producto #${productoId}';
  }

  String _getNombreCategoria(int categoriaId) {
    final cat = _categorias.where((c) => c.id == categoriaId).firstOrNull;
    return cat?.nombre ?? 'Sin categoría';
  }

  int _getCategoriaId(int productoId) {
    final prod = _productos.where((p) => p.id == productoId).firstOrNull;
    return prod?.categoriaId ?? 1;
  }

  String? _getDescripcionProducto(int productoId) {
    final prod = _productos.where((p) => p.id == productoId).firstOrNull;
    return prod?.descripcion;
  }

  void _showAlertasDialog(BuildContext context) {
    final alertas = _productosConStockBajo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alertas de Stock',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${alertas.length} producto(s) con stock bajo',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: alertas.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 48,
                          ),
                          SizedBox(height: 8),
                          Text('¡Todo bien! No hay alertas.'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: alertas.length,
                      itemBuilder: (context, index) {
                        final producto = alertas[index];
                        final umbral = producto.umbralAlerta ?? 5;
                        final esAgotado = producto.cantidad == 0;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: esAgotado
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            child: Icon(
                              esAgotado ? Icons.error : Icons.warning_amber,
                              color: esAgotado ? Colors.red : Colors.orange,
                            ),
                          ),
                          title: Text(producto.nombre),
                          subtitle: Text(
                            esAgotado
                                ? 'AGOTADO (Umbral: $umbral)'
                                : '${producto.cantidad} unidades (Umbral: $umbral)',
                            style: TextStyle(
                              color: esAgotado
                                  ? Colors.red
                                  : Colors.orange[700],
                            ),
                          ),
                          trailing: producto.precio != null
                              ? Text(
                                  '\$${producto.precio!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteVenta(Venta venta) async {
    if (venta.id == null) return;

    // Verificar si es un combo
    final producto = _productos
        .where((p) => p.id == venta.productoId)
        .firstOrNull;
    final esCombo = producto?.esCombo ?? false;

    // Si es combo, cargar los items
    List<ComboItem> comboItems = [];
    if (esCombo && producto != null && producto.id != null) {
      comboItems = await _apiService.getComboItems(producto.id!);
    }

    // Step 1: Ask how many units to return (or just delete)
    final cantidadController = TextEditingController(
      text: venta.cantidad.toString(),
    );
    bool devolverStock = false;

    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cantidadDevolver =
              int.tryParse(cantidadController.text) ?? venta.cantidad;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  color: SubliriumColors.deleteText,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text('Eliminar venta'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey[800]
                          : const Color(0xFFF6F3EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          size: 18,
                          color: SubliriumColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getNombreProducto(venta.productoId),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : SubliriumColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${venta.cantidad} ud(s) · \$${venta.total.toStringAsFixed(2)}${esCombo ? ' (COMBO)' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : SubliriumColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Toggle: devolver stock?
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '¿Devolver productos al stock?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : SubliriumColors.textPrimary,
                          ),
                        ),
                      ),
                      Switch(
                        value: devolverStock,
                        activeColor: SubliriumColors.stockOkText,
                        onChanged: (v) =>
                            setDialogState(() => devolverStock = v),
                      ),
                    ],
                  ),
                  if (devolverStock) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Cantidad a devolver (máx. ${venta.cantidad}):',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white60
                            : SubliriumColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: cantidadController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        border: const OutlineInputBorder(),
                        suffixText: '/ ${venta.cantidad}',
                      ),
                      autofocus: true,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    // Mostrar detalle de productos a devolver si es combo
                    if (esCombo && comboItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[850]
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[700]!
                                : const Color(0xFF86EFAC),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 16,
                                  color: SubliriumColors.stockOkText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Stock a devolver:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white
                                        : SubliriumColors.stockOkText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...comboItems.map((item) {
                              final cantidadADevolver =
                                  item.cantidad * cantidadDevolver;
                              final productoItem = _productos
                                  .where((p) => p.id == item.productoId)
                                  .firstOrNull;
                              final nombreItem =
                                  productoItem?.nombre ??
                                  'Producto #${item.productoId}';
                              final stockActual = productoItem?.cantidad ?? 0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '• $nombreItem',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: SubliriumColors.stockOkBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '+$cantidadADevolver',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: SubliriumColors.stockOkText,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(stock: $stockActual)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.4)
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancelar'),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SubliriumColors.deleteText,
                  foregroundColor: Colors.white,
                ),
                onPressed: () =>
                    Navigator.pop(ctx, devolverStock ? 'regresar' : 'solo'),
                child: Text(
                  devolverStock ? 'Eliminar y devolver' : 'Solo eliminar',
                ),
              ),
            ],
          );
        },
      ),
    );

    if (resultado == null || resultado == 'cancelar') return;

    try {
      if (resultado == 'regresar') {
        final cantidadDevolver = int.tryParse(cantidadController.text) ?? 0;
        if (cantidadDevolver <= 0 || cantidadDevolver > venta.cantidad) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Cantidad inválida')));
          }
          return;
        }

        if (esCombo && producto != null && producto.id != null) {
          // Es un combo - restaurar stock de cada producto
          await _apiService.restaurarStockCombo(producto.id!, cantidadDevolver);
        } else {
          // Producto normal
          if (producto != null) {
            final productoActualizado = producto.copyWith(
              cantidad: producto.cantidad + cantidadDevolver,
              fechaActualizacion: DateTime.now(),
            );
            await _apiService.updateProducto(productoActualizado);
          }
        }
      }

      await _apiService.deleteVenta(venta.id!);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado == 'regresar'
                  ? 'Venta eliminada y stock actualizado'
                  : 'Venta eliminada',
            ),
            backgroundColor: resultado == 'regresar'
                ? SubliriumColors.stockOkText
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showEditarVentaDialog(Venta venta) {
    final cantidadController = TextEditingController(
      text: venta.cantidad.toString(),
    );
    final precioController = TextEditingController(
      text: venta.precioUnitario.toStringAsFixed(2),
    );
    final vendedorController = TextEditingController(
      text: venta.vendidoA ?? '',
    );
    final observacionesController = TextEditingController(
      text: venta.observaciones ?? '',
    );
    DateTime fechaSeleccionada = venta.fechaVenta;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cantidad = int.tryParse(cantidadController.text) ?? 1;
          final precio = double.tryParse(precioController.text) ?? 0;
          final total = cantidad * precio;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Editar Venta'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getNombreProducto(venta.productoId),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (_getDescripcionProducto(venta.productoId) != null)
                    Text(
                      _getDescripcionProducto(venta.productoId)!,
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

                  TextField(
                    controller: precioController,
                    decoration: const InputDecoration(
                      labelText: 'Precio unitario',
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
                            color: isDark ? Colors.white : Colors.black,
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

                  TextField(
                    controller: vendedorController,
                    decoration: const InputDecoration(
                      labelText: 'Cliente',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: observacionesController,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
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
                  color: SubliriumColors.cyan,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    final cantidadNueva =
                        int.tryParse(cantidadController.text) ?? 1;
                    final precioText = _parsePrice(precioController.text);
                    final precioNuevo = double.tryParse(precioText) ?? 0;

                    if (cantidadNueva <= 0 || precioNuevo <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Datos inválidos')),
                      );
                      return;
                    }

                    final ventaActualizada = venta.copyWith(
                      cantidad: cantidadNueva,
                      precioUnitario: precioNuevo,
                      total: cantidadNueva * precioNuevo,
                      fechaVenta: fechaSeleccionada,
                      vendidoA: vendedorController.text.trim().isEmpty
                          ? null
                          : vendedorController.text.trim(),
                      observaciones: observacionesController.text.trim().isEmpty
                          ? null
                          : observacionesController.text.trim(),
                    );

                    try {
                      await _apiService.updateVenta(ventaActualizada);
                      _loadData();
                      if (mounted) Navigator.pop(dialogContext);
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Venta actualizada')),
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
                    'Guardar',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            actions: [
              if (_productosSinStock.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Badge(
                    label: Text('${_productosSinStock.length}'),
                    child: IconButton(
                      icon: Icon(Icons.warning_amber, color: Colors.orange),
                      onPressed: () => _showAlertasDialog(context),
                      tooltip: 'Productos sin stock',
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: isDark ? Colors.white : SubliriumColors.textPrimary,
                ),
                onPressed: _loadData,
                tooltip: 'Actualizar',
              ),
              IconButton(
                icon: Icon(
                  Icons.picture_as_pdf,
                  color: isDark ? Colors.white : SubliriumColors.textPrimary,
                ),
                onPressed: _generarPdfVentas,
                tooltip: 'Descargar reporte',
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 24,
                bottom: 16,
                right: 24,
              ),
              title: Text(
                'Dashboard',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : SubliriumColors.textPrimary,
                ),
              ),
              background: Container(color: theme.scaffoldBackgroundColor),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            // Main Assets Value Board
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VALOR TOTAL INVENTARIO',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: isDark
                            ? Colors.white
                            : SubliriumColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_totalAssetsValue.toStringAsFixed(2)}',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Secondary Stats Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildStatCardGlass(
                      'Total Ventas',
                      '\$${_totalVentas.toStringAsFixed(2)}',
                      Icons.attach_money,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCardGlass(
                      'En Stock',
                      '$_totalUnidadesStock uds',
                      Icons.inventory_2_outlined,
                    ),
                  ],
                ),
              ),
            ),

            // Inventario Alerts (Low stock feature from Prompt)
            if (_productosSinStock.isNotEmpty ||
                _productosEnStock.any((p) => p.cantidad <= 5))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ALERTAS DE INVENTARIO',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: isDark
                              ? Colors.white
                              : SubliriumColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 140,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._productosSinStock.map(
                              (p) => _buildAlertCard(p, true),
                            ),
                            ..._productosEnStock
                                .where((p) => p.cantidad <= 5)
                                .map((p) => _buildAlertCard(p, false)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Registro de Ventas (List)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Text(
                  'VENTAS RECIENTES',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: isDark
                        ? Colors.white70
                        : SubliriumColors.textSecondary,
                  ),
                ),
              ),
            ),

            if (_ventas.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.only(bottom: 100),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey[900]
                          : const Color(0xFFF6F3EC),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        'No hay ventas registradas recientes.',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : SubliriumColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final isLast = index == _ventas.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: isLast
                          ? 100
                          : 12, // Ensure no cutoff by bottom nav bar
                    ),
                    child: _buildVentaCardGlass(_ventas[index]),
                  );
                }, childCount: _ventas.length),
              ),
          ],
        ],
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
              backgroundColor: AppConfig.primaryColor,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildStatCardGlass(String titulo, String valor, IconData icono) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : const Color(0xFFF6F3EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icono,
                color: isDark ? Colors.white70 : SubliriumColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: TextStyle(
                color: isDark ? Colors.white70 : SubliriumColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: isDark ? Colors.white : SubliriumColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(Producto p, bool outOfStock) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: outOfStock
            ? (isDark
                  ? Colors.red[900]!.withValues(alpha: 0.2)
                  : const Color(0xFFFFF0F2))
            : (isDark ? Colors.grey[850] : const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: outOfStock
                  ? const Color(0xFFD31842)
                  : AppConfig.accentColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              outOfStock ? 'CRÍTICO' : 'BAJO STOCK',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Text(
            p.nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Stock: ${p.cantidad}',
            style: TextStyle(
              color: isDark
                  ? Colors.white70
                  : SubliriumColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentaCardGlass(Venta venta) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppConfig.primaryColor.withValues(alpha: 0.35)
              : AppConfig.primaryColor.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showEditarVentaDialog(venta),
          onLongPress: () => _deleteVenta(venta),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : const Color(0xFFF6F3EC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.receipt_long,
                      color: isDark
                          ? Colors.white70
                          : SubliriumColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getNombreProducto(venta.productoId),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (venta.vendidoA != null)
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 12,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                venta.vendidoA!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      Text(
                        DateFormat('dd MMM, HH:mm').format(venta.fechaVenta),
                        style: TextStyle(
                          color: isDark
                              ? Colors.white54
                              : SubliriumColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${venta.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppConfig.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${venta.cantidad} uds',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white54
                            : SubliriumColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showEditarVentaDialog(venta),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: AppConfig.primaryColor,
                  tooltip: 'Editar venta',
                  style: IconButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteVenta(venta),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: SubliriumColors.deleteText,
                  tooltip: 'Eliminar venta',
                  style: IconButton.styleFrom(
                    backgroundColor: SubliriumColors.stockLowBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  Future<void> _generarPdfVentas() async {
    await PdfHelper.loadLogo();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => PdfHelper.buildHeader(
          title: 'Reporte de Ventas',
          subtitle: 'Historial de ventas registradas',
        ),
        footer: (context) => PdfHelper.buildFooter(),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            headers: ['Fecha', 'Producto', 'Cliente/Obs', 'Cant', 'Total'],
            data: _ventas.map((v) {
              final prodNombre = _getNombreProducto(v.productoId);
              final extras = [
                v.vendidoA,
                v.observaciones,
              ].where((s) => s != null && s.isNotEmpty).join(' - ');
              return [
                _formatFecha(v.fechaVenta),
                prodNombre,
                extras.isEmpty ? '-' : extras,
                v.cantidad.toString(),
                '\$${v.total.toStringAsFixed(2)}',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            color: PdfColors.cyan200,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL EN VENTAS',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '\$${_totalVentas.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final fechaArchivo = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final nombreArchivo = 'ventas_$fechaArchivo';

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '$nombreArchivo.pdf',
    );
  }
}
