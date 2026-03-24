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

class TablaPreciosScreen extends StatefulWidget {
  const TablaPreciosScreen({super.key});

  @override
  State<TablaPreciosScreen> createState() => _TablaPreciosScreenState();
}

class _TablaPreciosScreenState extends State<TablaPreciosScreen> {
  final ApiService _apiService = ApiService();
  List<Categoria> _categorias = [];
  List<Producto> _productos = [];
  Map<int, List<PrecioTarifa>> _tarifasPorProducto = {};
  Categoria? _categoriaSeleccionada;
  Producto? _productoSeleccionado;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categorias = await _apiService.getCategorias();
      final productos = await _apiService.getProductos();
      final todasTarifas = await _apiService.getTodasTarifas();

      final tarifasMap = <int, List<PrecioTarifa>>{};
      for (final tarifa in todasTarifas) {
        tarifasMap.putIfAbsent(tarifa.productoId, () => []);
        tarifasMap[tarifa.productoId]!.add(tarifa);
      }

      // Buscar objetos seleccionados por ID (ya que son nuevas instancias)
      Categoria? categoriaSeleccionadaTemp;
      Producto? productoSeleccionadoTemp;
      
      if (_categoriaSeleccionada != null) {
        categoriaSeleccionadaTemp = categorias.where((c) => c.id == _categoriaSeleccionada!.id).firstOrNull;
      }
      
      if (_productoSeleccionado != null) {
        productoSeleccionadoTemp = productos.where((p) => p.id == _productoSeleccionado!.id).firstOrNull;
      }

      setState(() {
        _categorias = categorias;
        _productos = productos;
        _tarifasPorProducto = tarifasMap;
        _categoriaSeleccionada = categoriaSeleccionadaTemp;
        _productoSeleccionado = productoSeleccionadoTemp;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  List<Producto> get _productosFiltrados {
    var productos = _productos;
    
    if (_categoriaSeleccionada != null) {
      productos = productos.where((p) => p.categoriaId == _categoriaSeleccionada!.id).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      productos = productos.where((p) => 
        p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (p.descripcion?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    
    return productos;
  }

  List<Producto> get _productosAgrupados {
    if (_productoSeleccionado != null) {
      return [_productoSeleccionado!];
    }
    
    var productos = _productosFiltrados;
    
    if (_categoriaSeleccionada != null) {
      productos = productos.where((p) => p.categoriaId == _categoriaSeleccionada!.id).toList();
    }
    
    productos.sort((a, b) {
      final catA = _categorias.where((c) => c.id == a.categoriaId).firstOrNull?.nombre ?? '';
      final catB = _categorias.where((c) => c.id == b.categoriaId).firstOrNull?.nombre ?? '';
      return catA.compareTo(catB);
    });
    
    return productos;
  }

  List<PrecioTarifa> get _tarifasDelProducto {
    if (_productoSeleccionado == null) return [];
    return _tarifasPorProducto[_productoSeleccionado!.id] ?? [];
  }

  double get _precioBase {
    if (_productoSeleccionado == null) return 0;
    return _productoSeleccionado!.precio ?? 0;
  }

  int? get _ultimaCantidadMax {
    if (_tarifasDelProducto.isEmpty) return 0;
    int max = 0;
    for (final tarifa in _tarifasDelProducto) {
      if (tarifa.cantidadMax != null && tarifa.cantidadMax! > max) {
        max = tarifa.cantidadMax!;
      } else if (tarifa.esIlimitado && tarifa.cantidadMin > max) {
        max = tarifa.cantidadMin - 1;
      }
    }
    return max == 0 ? null : max;
  }

  String _validarNuevaTarifa(int cantidadMin, int? cantidadMax, double precio, {int? tarifaIdExcluir}) {
    if (cantidadMin < 1) {
      return 'La cantidad mínima debe ser al menos 1';
    }

    if (cantidadMax != null && cantidadMax <= cantidadMin) {
      return 'La cantidad máxima debe ser mayor que la mínima';
    }

    if (precio <= 0) {
      return 'El precio debe ser mayor a 0';
    }

    // Solo validar rango al AGREGAR (no al editar)
    if (tarifaIdExcluir == null && _tarifasDelProducto.isNotEmpty) {
      if (cantidadMin <= _ultimaCantidadMax!) {
        return 'La cantidad mínima debe ser mayor a ${_ultimaCantidadMax}';
      }

      for (final tarifa in _tarifasDelProducto) {
        final existingMin = tarifa.cantidadMin;
        final existingMax = tarifa.cantidadMax ?? 999999;
        
        if (cantidadMax != null) {
          if (!(cantidadMax < existingMin || cantidadMin > existingMax)) {
            return 'Este rango se cruza con uno existente';
          }
        } else {
          if (cantidadMin <= existingMax) {
            return 'Este rango se cruza con uno existente';
          }
        }
      }
    }

    return '';
  }

  void _showAgregarTarifaDialog({PrecioTarifa? tarifaEditar}) {
    // Verificar si ya tiene precio ilimitado (solo al crear nuevo)
    final esIlimitado = _tarifasDelProducto.isEmpty 
        ? false 
        : (_ultimaCantidadMax != null && _tarifasDelProducto.last.esIlimitado);
    
    if (tarifaEditar == null && esIlimitado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este producto ya tiene precio ilimitado. Elimínalo primero para agregar más.')),
      );
      return;
    }

    final cantidadMinController = TextEditingController(
      text: tarifaEditar != null 
          ? tarifaEditar.cantidadMin.toString()
          : ((_ultimaCantidadMax ?? 0) + 1).toString(),
    );
    final cantidadMaxController = TextEditingController(
      text: tarifaEditar?.cantidadMax?.toString() ?? '',
    );
    final precioController = TextEditingController(
      text: tarifaEditar != null 
          ? tarifaEditar.precioUnitario.toStringAsFixed(2)
          : '',
    );
    bool esIlimitadoActual = tarifaEditar?.esIlimitado ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(tarifaEditar != null ? 'Editar precio' : 'Agregar precio'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SubliriumColors.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: SubliriumColors.cyan),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tarifaEditar != null
                                ? 'Editando rango: ${tarifaEditar.rangoCantidad}'
                                : 'Rango: ${(_ultimaCantidadMax ?? 0) + 1}+ unidades',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: cantidadMinController,
                    decoration: InputDecoration(
                      labelText: 'Cantidad mínima',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[100],
                      helperText: 'Cantidad predefinida por el sistema',
                    ),
                    keyboardType: TextInputType.number,
                    enabled: false,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Último rango'),
                      Switch(
                        value: esIlimitadoActual,
                        onChanged: (value) {
                          setDialogState(() {
                            esIlimitadoActual = value;
                            if (value) {
                              cantidadMaxController.clear();
                            }
                          });
                        },
                        activeColor: SubliriumColors.cyan,
                      ),
                    ],
                  ),
                  if (!esIlimitadoActual) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: cantidadMaxController,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad máxima',
                        border: OutlineInputBorder(),
                        hintText: 'Dejar vacío = sin límite',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: precioController,
                    decoration: const InputDecoration(
                      labelText: 'Precio por unidad',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  final cantidadMin = int.tryParse(cantidadMinController.text) ?? 0;
                  final cantidadMax = cantidadMaxController.text.isEmpty
                      ? null
                      : int.tryParse(cantidadMaxController.text);
                  final precio = double.tryParse(precioController.text) ?? 0;

                  if (precio <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El precio debe ser mayor a 0')),
                    );
                    return;
                  }

                  try {
                    if (tarifaEditar != null) {
                      final actualizada = tarifaEditar.copyWith(
                        cantidadMax: esIlimitadoActual ? null : cantidadMax,
                        precioUnitario: precio,
                      );
                      await _apiService.updateTarifa(actualizada);

                      // Si edita precio con cantidad minima = 1, actualizar el precio del producto
                      if (tarifaEditar.cantidadMin == 1) {
                        final productoActualizado = _productoSeleccionado!.copyWith(
                          precio: precio,
                        );
                        await _apiService.updateProducto(productoActualizado);
                      }
                    } else {
                      final nuevaTarifa = PrecioTarifa(
                        productoId: _productoSeleccionado!.id!,
                        cantidadMin: cantidadMin,
                        cantidadMax: esIlimitadoActual ? null : cantidadMax,
                        precioUnitario: precio,
                      );
                      await _apiService.createTarifa(nuevaTarifa);

                      // Si crea precio con cantidad minima = 1, actualizar el precio del producto
                      if (cantidadMin == 1) {
                        final productoActualizado = _productoSeleccionado!.copyWith(
                          precio: precio,
                        );
                        await _apiService.updateProducto(productoActualizado);
                      }
                    }
                    
                    Navigator.pop(context);
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tarifaEditar != null ? 'Precio actualizado' : 'Precio agregado'),
                          backgroundColor: SubliriumColors.stockOkText,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: Text(tarifaEditar != null ? 'Actualizar' : 'Agregar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _eliminarTarifa(PrecioTarifa tarifa) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar precio?'),
        content: Text(
          'Eliminar precio para ${tarifa.rangoCantidad} unidades',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && tarifa.id != null) {
      try {
        await _apiService.deleteTarifa(tarifa.id!);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Precio eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabla de Precios'),
        backgroundColor: SubliriumColors.cyan,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: SubliriumColors.headerGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generarPdf,
            tooltip: 'Descargar PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SubliriumColors.cardBackground,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value),
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
                      const SizedBox(height: 8),
                      const Text(
                        'Filtros',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<Categoria>(
                              value: _categoriaSeleccionada,
                              dropdownColor: SubliriumColors.cardBackground,
                              decoration: const InputDecoration(
                                labelText: 'Categoría',
                                labelStyle: TextStyle(color: Colors.black),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Todas', style: TextStyle(color: Colors.black)),
                                ),
                                ..._categorias.map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.nombre, style: const TextStyle(color: Colors.black)),
                                    )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _categoriaSeleccionada = value;
                                  _productoSeleccionado = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<Producto>(
                              value: _productoSeleccionado,
                              dropdownColor: SubliriumColors.cardBackground,
                              decoration: const InputDecoration(
                                labelText: 'Producto',
                                labelStyle: TextStyle(color: Colors.black),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Todos', style: TextStyle(color: Colors.black)),
                                ),
                                ..._productosFiltrados.map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(
                                        p.nombre,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.black),
                                      ),
                                    )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _productoSeleccionado = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _productosAgrupados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Sin resultados',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _productoSeleccionado == null
                          ? _buildTodosLosProductos()
                          : ListView(
                              padding: const EdgeInsets.all(12),
                              children: [
                                _buildProductoCard(_productoSeleccionado!),
                                const SizedBox(height: 12),
                                _buildTablaPrecios(),
                              ],
                            ),
                ),
              ],
            ),
      floatingActionButton: _productoSeleccionado != null
          ? FloatingActionButton(
              onPressed: () => _showAgregarTarifaDialog(),
              backgroundColor: SubliriumColors.cyan,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildProductoCard(Producto producto) {
    final tieneTarifaIlimitada = _tarifasDelProducto.any((t) => t.esIlimitado);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: SubliriumColors.headerGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                if (producto.descripcion != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    producto.descripcion!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${_tarifasDelProducto.length} rango(s) de precio',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'Precio base',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: SubliriumColors.cyan,
                  ),
                ),
                Text(
                  '\$${_precioBase.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: SubliriumColors.cyan,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaPrecios() {
    final precioBase = _precioBase;
    final tarifasAdicionales = _tarifasDelProducto;

    return Container(
      decoration: BoxDecoration(
        color: SubliriumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SubliriumColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: SubliriumColors.cyan,
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Rango de cantidad',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Precio c/u',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(width: 80),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: SubliriumColors.cyan.withValues(alpha: 0.08),
              border: const Border(
                bottom: BorderSide(color: SubliriumColors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                        Text(
                          '1',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BASE',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '\$${precioBase.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 80,
                  child: Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
          ...tarifasAdicionales.asMap().entries.map((entry) {
            final index = entry.key;
            final tarifa = entry.value;
            final isLast = index == tarifasAdicionales.length - 1;
            final precio = tarifa.precioUnitario;
            final descuento = precioBase > 0 ? ((precioBase - precio) / precioBase * 100).round() : 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: index.isEven
                    ? SubliriumColors.cardBackground
                    : SubliriumColors.background,
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: SubliriumColors.border, width: 0.5),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Text(
                          tarifa.rangoCantidad,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                        if (descuento > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SubliriumColors.stockOkBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-$descuento%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: SubliriumColors.stockOkText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '\$${precio.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: SubliriumColors.cyan,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: SubliriumColors.cyan),
                          onPressed: () => _showAgregarTarifaDialog(tarifaEditar: tarifa),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => _eliminarTarifa(tarifa),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (tarifasAdicionales.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.arrow_downward, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Toca + para agregar precios por cantidad',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _generarPdf() async {
    await PdfHelper.loadLogo();
    final pdf = pw.Document();
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => PdfHelper.buildHeader(
          title: 'Tabla de Precios',
          subtitle: 'Fecha: $fecha',
        ),
        footer: (context) => PdfHelper.buildFooter(),
        build: (context) => [
          pw.SizedBox(height: 20),
          for (final categoria in _categorias.where((c) => _productos.any((p) => p.categoriaId == c.id)))
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
                pw.SizedBox(height: 8),
                for (final producto in _productos.where((p) => p.categoriaId == categoria.id))
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          producto.nombre,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Row(
                                children: [
                                  pw.Expanded(
                                    child: pw.Text(
                                      'Rango de cantidad',
                                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      'Precio c/u',
                                      textAlign: pw.TextAlign.right,
                                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                              pw.Divider(color: PdfColors.grey300),
                              pw.Row(
                                children: [
                                  pw.Expanded(
                                    child: pw.Text(
                                      _getRangoBaseProducto(producto),
                                      style: const pw.TextStyle(fontSize: 9),
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      '\$${(producto.precio ?? 0).toStringAsFixed(2)}',
                                      textAlign: pw.TextAlign.right,
                                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              for (final tarifa in _tarifasPorProducto[producto.id] ?? [])
                                if (tarifa.cantidadMin > 1)
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 4),
                                    child: pw.Row(
                                      children: [
                                        pw.Expanded(
                                          child: pw.Text(tarifa.rangoCantidad, style: const pw.TextStyle(fontSize: 9)),
                                        ),
                                        pw.Expanded(
                                          child: pw.Text(
                                            '\$${tarifa.precioUnitario.toStringAsFixed(2)}',
                                            textAlign: pw.TextAlign.right,
                                            style: const pw.TextStyle(fontSize: 9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              pw.SizedBox(height: 8),
                              pw.Container(
                                padding: const pw.EdgeInsets.all(6),
                                color: PdfColors.cyan50,
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(
                                      'VALOR TOTAL INVENTARIO',
                                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                    ),
                                    pw.Text(
                                      '\$${_calcularTotalProducto(producto).toStringAsFixed(2)}',
                                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.cyan700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                pw.SizedBox(height: 12),
              ],
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'tabla_precios_sublirium_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  double _calcularTotalProducto(Producto producto) {
    double total = (producto.precio ?? 0) * producto.cantidad;
    for (final tarifa in _tarifasPorProducto[producto.id] ?? []) {
      if (tarifa.cantidadMin > 1) {
        final cantidadEnRango = producto.cantidad;
        if (cantidadEnRango >= tarifa.cantidadMin) {
          total = (tarifa.precioUnitario * cantidadEnRango);
        }
      }
    }
    return total;
  }

  String _getRangoBaseProducto(Producto producto) {
    final tarifas = _tarifasPorProducto[producto.id];
    if (tarifas == null || tarifas.isEmpty) {
      return '1';
    }
    tarifas.sort((a, b) => a.cantidadMin.compareTo(b.cantidadMin));
    int? maximoBase;
    for (final tarifa in tarifas) {
      if (tarifa.cantidadMin > 1) {
        maximoBase = tarifa.cantidadMin - 1;
        break;
      }
    }
    if (maximoBase != null) {
      return '1 - $maximoBase';
    }
    return '1';
  }

  Widget _buildTodosLosProductos() {
    final Map<int, List<Producto>> productosPorCategoria = {};
    
    for (final producto in _productosAgrupados) {
      productosPorCategoria.putIfAbsent(producto.categoriaId, () => []).add(producto);
    }
    
    final categoriasOrdenadas = _categorias
        .where((c) => productosPorCategoria.containsKey(c.id))
        .toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: categoriasOrdenadas.length,
      itemBuilder: (context, index) {
        final categoria = categoriasOrdenadas[index];
        final productos = productosPorCategoria[categoria.id]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            ...productos.map((producto) => _buildProductoItem(producto)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildProductoItem(Producto producto) {
    final precioBase = producto.precio ?? 0;
    final tarifas = _tarifasPorProducto[producto.id] ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: SubliriumColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SubliriumColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            producto.nombre,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.black,
            ),
          ),
          subtitle: Text(
            'Base: \$${precioBase.toStringAsFixed(2)} | ${tarifas.length} rango(s)',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          trailing: Icon(Icons.expand_more, color: Colors.grey[600]),
          children: [
            if (tarifas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sin tarifas configuradas',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              )
            else
              ...tarifas.map((tarifa) {
                final descuento = precioBase > 0
                    ? ((precioBase - tarifa.precioUnitario) / precioBase * 100).round()
                    : 0;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tarifa.rangoCantidad,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        '\$${tarifa.precioUnitario.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: SubliriumColors.cyan,
                        ),
                      ),
                      if (descuento > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: SubliriumColors.stockOkBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-$descuento%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: SubliriumColors.stockOkText,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
