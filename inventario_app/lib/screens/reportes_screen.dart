import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/subscription_service.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../utils/plan_upgrade_helper.dart';

enum TipoReporte { ventas, productosMasVendidos, utilidad }

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final ApiService _apiService = ApiService();

  List<Venta> _ventas = [];
  List<Producto> _productos = [];
  bool _isLoading = true;
  String? _error;

  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();
  TipoReporte _tipoReporte = TipoReporte.ventas;
  bool _isProUser = false;

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
  }

  Future<void> _checkAccessAndLoad() async {
    final isPro = await SubscriptionService.hasFeature('historical_reports');
    if (!isPro) {
      setState(() {
        _isProUser = false;
        _isLoading = false;
      });
      return;
    }
    setState(() => _isProUser = true);
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final ventas = await _apiService.getVentas();
      final productos = await _apiService.getProductos();
      setState(() {
        _ventas = ventas;
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

  List<Venta> get _ventasFiltradas {
    return _ventas.where((v) {
      return v.fechaVenta.isAfter(
            _fechaInicio.subtract(const Duration(days: 1)),
          ) &&
          v.fechaVenta.isBefore(_fechaFin.add(const Duration(days: 1)));
    }).toList();
  }

  Map<int, dynamic> get _productosMasVendidos {
    final Map<int, dynamic> ventasPorProducto = {};
    for (final venta in _ventasFiltradas) {
      if (!ventasPorProducto.containsKey(venta.productoId)) {
        final producto = _productos.firstWhere(
          (p) => p.id == venta.productoId,
          orElse: () =>
              Producto(categoriaId: 0, nombre: 'Desconocido', cantidad: 0),
        );
        ventasPorProducto[venta.productoId] = {
          'producto': producto,
          'cantidadTotal': 0,
          'ventasTotales': 0.0,
        };
      }
      ventasPorProducto[venta.productoId]['cantidadTotal'] += venta.cantidad;
      ventasPorProducto[venta.productoId]['ventasTotales'] += venta.total;
    }
    return Map.fromEntries(
      ventasPorProducto.entries.toList()..sort(
        (a, b) => b.value['cantidadTotal'].compareTo(a.value['cantidadTotal']),
      ),
    );
  }

  Map<int, dynamic> get _utilidadPorProducto {
    final Map<int, dynamic> utilidadPorProducto = {};
    for (final producto in _productos) {
      if (producto.costo != null && producto.precio != null) {
        final ventasProducto = _ventasFiltradas.where(
          (v) => v.productoId == producto.id,
        );
        final cantidadVendida = ventasProducto.fold<int>(
          0,
          (sum, v) => sum + v.cantidad,
        );
        final ingresoTotal = ventasProducto.fold<double>(
          0,
          (sum, v) => sum + v.total,
        );
        final costoTotal = cantidadVendida * producto.costo!;
        final utilidad = ingresoTotal - costoTotal;

        if (cantidadVendida > 0) {
          utilidadPorProducto[producto.id!] = {
            'producto': producto,
            'cantidadVendida': cantidadVendida,
            'ingresoTotal': ingresoTotal,
            'costoTotal': costoTotal,
            'utilidad': utilidad,
          };
        }
      }
    }
    return Map.fromEntries(
      utilidadPorProducto.entries.toList()
        ..sort((a, b) => b.value['utilidad'].compareTo(a.value['utilidad'])),
    );
  }

  double get _totalVentas {
    return _ventasFiltradas.fold(0, (sum, v) => sum + v.total);
  }

  int get _totalUnidadesVendidas {
    return _ventasFiltradas.fold(0, (sum, v) => sum + v.cantidad);
  }

  double get _totalUtilidad {
    return _utilidadPorProducto.values.fold(
      0,
      (sum, v) => sum + (v['utilidad'] as double),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fechaInicio, end: _fechaFin),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppConfig.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fechaInicio = picked.start;
        _fechaFin = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isProUser) {
      return _buildAccessDenied();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: AppConfig.secondaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar',
            onSelected: _exportToExcel,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'ventas',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, size: 20),
                    SizedBox(width: 8),
                    Text('Exportar Ventas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mas_vendidos',
                child: Row(
                  children: [
                    Icon(Icons.trending_up, size: 20),
                    SizedBox(width: 8),
                    Text('Exportar Ranking'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'utilidad',
                child: Row(
                  children: [
                    Icon(Icons.attach_money, size: 20),
                    SizedBox(width: 8),
                    Text('Exportar Utilidad'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateRangeSelector(),
          _buildReportTypeSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildError()
                : _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToExcel(String tipo) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando archivo Excel...')),
      );

      final excel = Excel.createExcel();
      final dateFormat = DateFormat('yyyy-MM-dd');
      final fechaStr = dateFormat.format(DateTime.now());
      String fileName = '';
      final Sheet sheet = excel['Datos'];

      switch (tipo) {
        case 'ventas':
          final sheet = excel['Ventas'];
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
              .value = TextCellValue(
            'Reporte de Ventas',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
              .value = TextCellValue(
            'Período: ${_dateFormat.format(_fechaInicio)} - ${_dateFormat.format(_fechaFin)}',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
              .value = TextCellValue(
            'Fecha',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
              .value = TextCellValue(
            'Producto',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 2))
              .value = TextCellValue(
            'Cantidad',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 2))
              .value = TextCellValue(
            'Precio Unit.',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 2))
              .value = TextCellValue(
            'Total',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 2))
              .value = TextCellValue(
            'Cliente',
          );

          int row = 3;
          double total = 0;
          for (final venta in _ventasFiltradas) {
            final producto = _productos.firstWhere(
              (p) => p.id == venta.productoId,
              orElse: () =>
                  Producto(categoriaId: 0, nombre: 'Desconocido', cantidad: 0),
            );
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
                .value = TextCellValue(
              _dateFormat.format(venta.fechaVenta),
            );
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
                .value = TextCellValue(
              producto.nombre,
            );
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
                .value = IntCellValue(
              venta.cantidad,
            );
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
                .value = DoubleCellValue(
              venta.precioUnitario,
            );
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
                .value = DoubleCellValue(
              venta.total,
            );
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
                .value = TextCellValue(
              venta.vendidoA ?? '-',
            );
            total += venta.total;
            row++;
          }
          row++;
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
              .value = TextCellValue(
            'TOTAL',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
              .value = DoubleCellValue(
            total,
          );
          fileName = 'ventas_${fechaStr}';
          break;

        case 'mas_vendidos':
          final sheet = excel['Ranking'];
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
              .value = TextCellValue(
            'Ranking de Productos Más Vendidos',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
              .value = TextCellValue(
            'Período: ${_dateFormat.format(_fechaInicio)} - ${_dateFormat.format(_fechaFin)}',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
              .value = TextCellValue(
            '#',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
              .value = TextCellValue(
            'Producto',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 2))
              .value = TextCellValue(
            'Cant. Vendida',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 2))
              .value = TextCellValue(
            'Ingresos',
          );

          int row = 3;
          int posicion = 1;
          for (final entry in _productosMasVendidos.entries) {
            final data = entry.value;
            final producto = data['producto'] as Producto;
            final cantidad = data['cantidadTotal'] as int;
            final ingresos = data['ventasTotales'] as double;

            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
                .value = IntCellValue(
              posicion,
            );
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
                .value = TextCellValue(
              producto.nombre,
            );
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
                .value = IntCellValue(
              cantidad,
            );
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
                .value = DoubleCellValue(
              ingresos,
            );
            row++;
            posicion++;
          }
          fileName = 'ranking_${fechaStr}';
          break;

        case 'utilidad':
          final sheet = excel['Utilidad'];
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
              .value = TextCellValue(
            'Reporte de Utilidad por Producto',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
              .value = TextCellValue(
            'Período: ${_dateFormat.format(_fechaInicio)} - ${_dateFormat.format(_fechaFin)}',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
              .value = TextCellValue(
            'Producto',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
              .value = TextCellValue(
            'Cant. Vendida',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 2))
              .value = TextCellValue(
            'Ingresos',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 2))
              .value = TextCellValue(
            'Costos',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 2))
              .value = TextCellValue(
            'Utilidad',
          );

          int row = 3;
          double utilidadTotal = 0;
          for (final entry in _utilidadPorProducto.entries) {
            final data = entry.value;
            final producto = data['producto'] as Producto;
            final cantidad = data['cantidadVendida'] as int;
            final ingresos = data['ingresoTotal'] as double;
            final costos = data['costoTotal'] as double;
            final utilidad = data['utilidad'] as double;

            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
                .value = TextCellValue(
              producto.nombre,
            );
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
                .value = IntCellValue(
              cantidad,
            );
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
                .value = DoubleCellValue(
              ingresos,
            );
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
                .value = DoubleCellValue(
              costos,
            );
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
                .value = DoubleCellValue(
              utilidad,
            );
            utilidadTotal += utilidad;
            row++;
          }
          row++;
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
              .value = TextCellValue(
            'UTILIDAD TOTAL',
          );
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
              .value = DoubleCellValue(
            utilidadTotal,
          );
          fileName = 'utilidad_${fechaStr}';
          break;
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
          final file = File('${dir.path}/$fileName.xlsx');
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

  DateFormat get _dateFormat => DateFormat('dd/MM/yyyy');

  Widget _buildAccessDenied() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PlanUpgradeHelper.showUpgradeDialog(
          context,
          'Reportes Avanzados',
          planRequired: 'Pro',
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: AppConfig.secondaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 80,
                color: AppConfig.primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'Reportes Avanzados',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Accede a reportes históricos de ventas,\nproductos más vendidos y utilidad.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConfig.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: AppConfig.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Disponible en plan Pro',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const _PlanesScreen()),
                  );
                },
                icon: const Icon(Icons.upgrade),
                label: const Text('Ver Planes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      child: InkWell(
        onTap: _selectDateRange,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: SubliriumColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.date_range, color: AppConfig.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dateFormat.format(_fechaInicio)} - ${dateFormat.format(_fechaFin)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_ventasFiltradas.length} ventas en este período',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_drop_down, color: AppConfig.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildReportChip('Ventas', TipoReporte.ventas, Icons.attach_money),
          const SizedBox(width: 8),
          _buildReportChip(
            'Más Vendidos',
            TipoReporte.productosMasVendidos,
            Icons.trending_up,
          ),
          const SizedBox(width: 8),
          _buildReportChip('Utilidad', TipoReporte.utilidad, Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildReportChip(String label, TipoReporte tipo, IconData icon) {
    final isActive = _tipoReporte == tipo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipoReporte = tipo),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppConfig.primaryColor : Colors.transparent,
            border: Border.all(
              color: isActive ? AppConfig.primaryColor : SubliriumColors.border,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : AppConfig.primaryColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : AppConfig.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_tipoReporte) {
      case TipoReporte.ventas:
        return _buildVentasReport();
      case TipoReporte.productosMasVendidos:
        return _buildProductosMasVendidosReport();
      case TipoReporte.utilidad:
        return _buildUtilidadReport();
    }
  }

  Widget _buildVentasReport() {
    return Column(
      children: [
        _buildSummaryCards(),
        Expanded(
          child: _ventasFiltradas.isEmpty
              ? _buildEmptyState('No hay ventas en este período')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _ventasFiltradas.length,
                  itemBuilder: (context, index) {
                    final venta = _ventasFiltradas[index];
                    final producto = _productos.firstWhere(
                      (p) => p.id == venta.productoId,
                      orElse: () => Producto(
                        categoriaId: 0,
                        nombre: 'Desconocido',
                        cantidad: 0,
                      ),
                    );
                    return _buildVentaCard(venta, producto);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Ventas',
              '\$${_totalVentas.toStringAsFixed(2)}',
              Icons.attach_money,
              SubliriumColors.stockOkText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Unidades',
              _totalUnidadesVendidas.toString(),
              Icons.inventory_2,
              AppConfig.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Transacciones',
              _ventasFiltradas.length.toString(),
              Icons.receipt_long,
              SubliriumColors.naranja,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SubliriumColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVentaCard(Venta venta, Producto producto) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(venta.fechaVenta),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  if (venta.vendidoA != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Cliente: ${venta.vendidoA}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${venta.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SubliriumColors.stockOkText,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: SubliriumColors.stockOkBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'x${venta.cantidad}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductosMasVendidosReport() {
    final productos = _productosMasVendidos;

    if (productos.isEmpty) {
      return _buildEmptyState('No hay ventas en este período');
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Vendido',
                  '${_totalUnidadesVendidas} unidades',
                  Icons.inventory_2,
                  AppConfig.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Ingresos',
                  '\$${_totalVentas.toStringAsFixed(2)}',
                  Icons.attach_money,
                  SubliriumColors.stockOkText,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final entry = productos.entries.elementAt(index);
              final data = entry.value;
              final producto = data['producto'] as Producto;
              final cantidadTotal = data['cantidadTotal'] as int;
              final ventasTotales = data['ventasTotales'] as double;

              return _buildRankingCard(
                position: index + 1,
                producto: producto,
                cantidad: cantidadTotal,
                ventasTotales: ventasTotales,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRankingCard({
    required int position,
    required Producto producto,
    required int cantidad,
    required double ventasTotales,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color positionColor;
    IconData? positionIcon;

    switch (position) {
      case 1:
        positionColor = const Color(0xFFFFD700);
        positionIcon = Icons.emoji_events;
        break;
      case 2:
        positionColor = const Color(0xFFC0C0C0);
        positionIcon = Icons.emoji_events;
        break;
      case 3:
        positionColor = const Color(0xFFCD7F32);
        positionIcon = Icons.emoji_events;
        break;
      default:
        positionColor = AppConfig.primaryColor;
        positionIcon = null;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: positionColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: positionIcon != null
                    ? Icon(positionIcon, color: positionColor, size: 28)
                    : Text(
                        '#$position',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: positionColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${producto.precio?.toStringAsFixed(2) ?? '0.00'} c/u',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${ventasTotales.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SubliriumColors.stockOkText,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$cantidad vendidos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppConfig.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilidadReport() {
    final utilidad = _utilidadPorProducto;

    if (utilidad.isEmpty) {
      return _buildEmptyState(
        'No hay datos de utilidad.\nAsegúrate de tener productos con costo y precio registrados.',
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: _buildSummaryCard(
            'Utilidad Total',
            '\$${_totalUtilidad.toStringAsFixed(2)}',
            Icons.trending_up,
            _totalUtilidad >= 0
                ? SubliriumColors.stockOkText
                : SubliriumColors.deleteText,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: utilidad.length,
            itemBuilder: (context, index) {
              final entry = utilidad.entries.elementAt(index);
              final data = entry.value;
              final producto = data['producto'] as Producto;
              final cantidadVendida = data['cantidadVendida'] as int;
              final ingresoTotal = data['ingresoTotal'] as double;
              final costoTotal = data['costoTotal'] as double;
              final utilidadItem = data['utilidad'] as double;

              return _buildUtilidadCard(
                producto: producto,
                cantidadVendida: cantidadVendida,
                ingresoTotal: ingresoTotal,
                costoTotal: costoTotal,
                utilidad: utilidadItem,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUtilidadCard({
    required Producto producto,
    required int cantidadVendida,
    required double ingresoTotal,
    required double costoTotal,
    required double utilidad,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final esRentable = utilidad >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    producto.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: esRentable
                        ? SubliriumColors.stockOkBg
                        : SubliriumColors.stockLowBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${esRentable ? '+' : ''}\$${utilidad.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: esRentable
                          ? SubliriumColors.stockOkText
                          : SubliriumColors.deleteText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildUtilidadDetail(
                    'Ventas',
                    '$cantidadVendida',
                    Icons.shopping_cart,
                  ),
                ),
                Expanded(
                  child: _buildUtilidadDetail(
                    'Ingresos',
                    '\$${ingresoTotal.toStringAsFixed(2)}',
                    Icons.arrow_upward,
                  ),
                ),
                Expanded(
                  child: _buildUtilidadDetail(
                    'Costos',
                    '\$${costoTotal.toStringAsFixed(2)}',
                    Icons.arrow_downward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilidadDetail(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white70 : Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _PlanesScreen extends StatelessWidget {
  const _PlanesScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planes')),
      body: const Center(child: Text('Ve a Plans desde el menú principal')),
    );
  }
}
