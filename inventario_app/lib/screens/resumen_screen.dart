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
  List<Producto> _productos = [];
  List<Categoria> _categorias = [];
  List<Venta> _ventas = [];
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
      final ventas = await _apiService.getVentas();
      setState(() {
        _productos = productos;
        _categorias = categorias;
        _ventas = ventas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Producto> get _productosEnStock =>
      _productos.where((p) => p.cantidad > 0).toList();
  List<Producto> get _productosSinStock =>
      _productos.where((p) => p.cantidad == 0).toList();
  int get _totalUnidadesStock =>
      _productosEnStock.fold(0, (sum, p) => sum + p.cantidad);

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

  Future<void> _deleteVenta(Venta venta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar venta?'),
        content: Text(
          'Eliminar venta de ${venta.cantidad} unidad(es) por \$${venta.total.toStringAsFixed(2)}',
        ),
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

    if (confirm == true && venta.id != null) {
      try {
        // Devolver stock al producto
        final producto = _productos
            .where((p) => p.id == venta.productoId)
            .firstOrNull;
        if (producto != null) {
          final productoActualizado = producto.copyWith(
            cantidad: producto.cantidad + venta.cantidad,
            fechaActualizacion: DateTime.now(),
          );
          await _apiService.updateProducto(productoActualizado);
        }

        await _apiService.deleteVenta(venta.id!);
        _loadData();
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Venta eliminada')));
      } catch (e) {
        if (mounted)
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  if (_getDescripcionProducto(venta.productoId) != null)
                    Text(
                      _getDescripcionProducto(venta.productoId)!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withValues(alpha: 0.7),
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
                          selection: TextSelection.collapsed(offset: parsed.length),
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
                        const Text(
                          'Total:',
                          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            actions: [
              IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.white), onPressed: _generarPdfVentas, tooltip: 'Descargar reporte'),
            ],
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
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            // Stats principales
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTADÍSTICAS GENERALES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onBackground,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatCard(
                          'Total Ventas',
                          '\$${_totalVentas.toStringAsFixed(2)}',
                          Icons.attach_money,
                          SubliriumColors.stockOkText,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'Unidades Vendidas',
                          '$_totalUnidadesVendidas',
                          Icons.shopping_bag,
                          SubliriumColors.cyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatCard(
                          'En Stock',
                          '${_productosEnStock.length} productos',
                          Icons.inventory,
                          SubliriumColors.purple,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'Total Unidades',
                          '$_totalUnidadesStock',
                          Icons.all_inbox,
                          SubliriumColors.logoOrange,
                        ),
                      ],
                    ),
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
                    Text(
                      'REGISTRO DE VENTAS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onBackground,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_ventas.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: SubliriumColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SubliriumColors.border),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 40,
                                color: Colors.black,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No hay ventas registradas',
                                style: TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...(_ventas.map((v) => _buildVentaCard(v))),
                  ],
                ),
              ),
            ),
            // Inventario
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESUMEN DE INVENTARIO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onBackground,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildResumenCard(
                      'En Stock',
                      _productosEnStock.length,
                      _totalUnidadesStock,
                      SubliriumColors.stockOkText,
                    ),
                    const SizedBox(height: 8),
                    _buildResumenCard(
                      'Sin Stock',
                      _productosSinStock.length,
                      0,
                      SubliriumColors.stockLowText,
                    ),
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

  Widget _buildStatCard(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
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
            Text(
              valor,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              style: const TextStyle(fontSize: 10, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVentaCard(Venta venta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SubliriumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SubliriumColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SubliriumColors.cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.folder,
                    size: 20,
                    color: SubliriumColors.cyan,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getNombreProducto(venta.productoId),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 12, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          venta.vendidoA ?? 'Cliente',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${venta.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: SubliriumColors.stockOkText,
                    ),
                  ),
                  Text(
                    '${venta.cantidad} x \$${venta.precioUnitario.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 9, color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 12, color: Colors.black),
              const SizedBox(width: 4),
              Text(
                _formatFecha(venta.fechaVenta),
                style: const TextStyle(fontSize: 10, color: Colors.black),
              ),
              if (venta.observaciones != null &&
                  venta.observaciones!.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Icon(Icons.note, size: 12, color: Colors.black),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    venta.observaciones!,
                    style: const TextStyle(fontSize: 10, color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () => _showEditarVentaDialog(venta),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: SubliriumColors.inputFocusedBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 12, color: SubliriumColors.cyan),
                      SizedBox(width: 4),
                      Text(
                        'Editar',
                        style: TextStyle(
                          fontSize: 10,
                          color: SubliriumColors.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _deleteVenta(venta),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: SubliriumColors.stockLowBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.delete,
                        size: 12,
                        color: SubliriumColors.deleteText,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Eliminar',
                        style: TextStyle(
                          fontSize: 10,
                          color: SubliriumColors.deleteText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard(
    String titulo,
    int cantidad,
    int unidades,
    Color color,
  ) {
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              cantidad > 0 ? Icons.check_circle : Icons.warning,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '$cantidad productos',
                  style: const TextStyle(fontSize: 11, color: Colors.black),
                ),
              ],
            ),
          ),
          if (unidades > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$unidades uds',
                style: TextStyle(fontWeight: FontWeight.w900, color: color),
              ),
            ),
        ],
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
        header: (context) => PdfHelper.buildHeader(title: 'Reporte de Ventas', subtitle: 'Historial de ventas registradas'),
        footer: (context) => PdfHelper.buildFooter(),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft, 2: pw.Alignment.centerLeft, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight},
            headers: ['Fecha', 'Producto', 'Cliente/Obs', 'Cant', 'Total'],
            data: _ventas.map((v) {
              final prodNombre = _getNombreProducto(v.productoId);
              final extras = [v.vendidoA, v.observaciones].where((s) => s != null && s.isNotEmpty).join(' - ');
              return [
                _formatFecha(v.fechaVenta),
                prodNombre,
                extras.isEmpty ? '-' : extras,
                v.cantidad.toString(),
                '\$${v.total.toStringAsFixed(2)}'
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            color: PdfColors.cyan200,
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('TOTAL EN VENTAS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('\$${_totalVentas.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'reporte_ventas_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }
}
