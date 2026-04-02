import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';

class CombosScreen extends StatefulWidget {
  const CombosScreen({super.key});

  @override
  State<CombosScreen> createState() => _CombosScreenState();
}

class _CombosScreenState extends State<CombosScreen> {
  final ApiService _apiService = ApiService();
  List<Producto> _combos = [];
  List<Producto> _productos = [];
  Map<int, List<ComboItem>> _comboItems = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final combos = await _apiService.getCombos();
      final productos = await _apiService.getProductos();
      final itemsMap = <int, List<ComboItem>>{};

      for (final combo in combos) {
        if (combo.id != null) {
          final items = await _apiService.getComboItems(combo.id!);
          itemsMap[combo.id!] = items;
        }
      }

      setState(() {
        _combos = combos;
        _productos = productos;
        _comboItems = itemsMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCombo(Producto combo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar combo?'),
        content: Text('Se eliminará "${combo.nombre}" permanentemente.'),
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

    if (confirm == true && combo.id != null) {
      try {
        await _apiService.deleteCombo(combo.id!);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Combo eliminado')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  int _calcularStockCombo(Producto combo) {
    final items = _comboItems[combo.id] ?? [];
    if (items.isEmpty) return 0;

    int stockMinimo = double.maxFinite.toInt();
    bool sinStock = false;

    for (final item in items) {
      final producto = _productos
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

  List<MapEntry<MapEntry<int, String>, bool>> _getProductosConStock(
    Producto combo,
  ) {
    final items = _comboItems[combo.id] ?? [];
    return items.map((item) {
      final producto = _productos
          .where((p) => p.id == item.productoId)
          .firstOrNull;
      final tieneStock = producto != null && producto.cantidad >= item.cantidad;
      return MapEntry(
        MapEntry(
          item.productoId,
          producto?.nombre ?? 'Producto #${item.productoId}',
        ),
        tieneStock,
      );
    }).toList();
  }

  void _showComboDialog([Producto? combo]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComboEditorScreen(
          combo: combo,
          productos: _productos,
          comboItems: combo != null ? (_comboItems[combo.id] ?? []) : [],
          onSave: _loadData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Combos'),
        backgroundColor: AppConfig.secondaryColor,
        foregroundColor: AppConfig.secondaryContrastColor,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppConfig.secondaryColor, AppConfig.primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _loadData,
              tooltip: 'Actualizar',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 8),
                  Text(_error!),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : _combos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 64,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay combos creados',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu primer combo de productos',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _combos.length,
              itemBuilder: (context, index) {
                final combo = _combos[index];
                return _buildComboCard(combo, isDark, theme);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showComboDialog(),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: AppConfig.primaryContrastColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildComboCard(Producto combo, bool isDark, ThemeData theme) {
    final stockCombo = _calcularStockCombo(combo);
    final productosConStock = _getProductosConStock(combo);
    final productosSinStock = productosConStock.where((e) => !e.value).toList();
    final tieneProductosSinStock = productosSinStock.isNotEmpty;
    final stockColor = stockCombo == 0
        ? SubliriumColors.stockLowText
        : (stockCombo < 5 ? Colors.orange : SubliriumColors.stockOkText);
    final stockBg = stockCombo == 0
        ? SubliriumColors.stockLowBg
        : (stockCombo < 5 ? Colors.orange[50] : SubliriumColors.stockOkBg);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey[700]! : SubliriumColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showComboDialog(combo),
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
                        Text(
                          combo.nombre,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (combo.descripcion != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            combo.descripcion!,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppConfig.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\$${combo.precio?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppConfig.accentColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Warning de productos sin stock
              if (tieneProductosSinStock) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sin stock: ${productosSinStock.map((e) => e.key.value).join(", ")}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Stock del combo
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: stockBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      stockCombo == 0
                          ? Icons.error_outline
                          : Icons.inventory_2_outlined,
                      size: 16,
                      color: stockColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      stockCombo == 0 ? 'Sin stock' : 'Stock: $stockCombo',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: stockColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Lista de productos del combo
              if (productosConStock.isNotEmpty) ...[
                Text(
                  'Productos:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ...productosConStock.map((entry) {
                  final items = _comboItems[combo.id] ?? [];
                  final item = items
                      .where((i) => i.productoId == entry.key.key)
                      .firstOrNull;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Icon(
                          entry.value ? Icons.check_circle : Icons.cancel,
                          size: 14,
                          color: entry.value
                              ? SubliriumColors.stockOkText
                              : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${entry.key.value} x${item?.cantidad ?? 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: entry.value
                                ? (isDark ? Colors.white70 : Colors.black87)
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showComboDialog(combo),
                    color: SubliriumColors.cyan,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _deleteCombo(combo),
                    color: Colors.red[300],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComboEditorScreen extends StatefulWidget {
  final Producto? combo;
  final List<Producto> productos;
  final List<ComboItem> comboItems;
  final VoidCallback onSave;

  const ComboEditorScreen({
    super.key,
    this.combo,
    required this.productos,
    required this.comboItems,
    required this.onSave,
  });

  @override
  State<ComboEditorScreen> createState() => _ComboEditorScreenState();
}

class _ComboEditorScreenState extends State<ComboEditorScreen> {
  final ApiService _apiService = ApiService();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();

  List<ComboItem> _items = [];
  List<Producto> _productosFiltrados = [];
  bool _isLoading = false;
  String? _warningMessage;

  @override
  void initState() {
    super.initState();
    if (widget.combo != null) {
      _nombreController.text = widget.combo!.nombre;
      _descripcionController.text = widget.combo!.descripcion ?? '';
      _precioController.text =
          widget.combo!.precio?.toStringAsFixed(2) ?? '0.00';
      _items = List.from(widget.comboItems);
    }
    _productosFiltrados = widget.productos.where((p) => !p.esCombo).toList();
    _validarStock();
  }

  void _validarStock() {
    final sinStock = <String>[];
    for (final item in _items) {
      final producto = _productosFiltrados
          .where((p) => p.id == item.productoId)
          .firstOrNull;
      if (producto != null && producto.cantidad < item.cantidad) {
        sinStock.add(producto.nombre);
      }
    }
    setState(() {
      _warningMessage = sinStock.isNotEmpty
          ? 'Sin stock: ${sinStock.join(", ")}'
          : null;
    });
  }

  Future<void> _saveCombo() async {
    final nombre = _nombreController.text.trim();
    final precio = double.tryParse(_precioController.text) ?? 0;

    if (nombre.isEmpty || precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y precio son obligatorios')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto al combo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final combo = Producto(
        id: widget.combo?.id,
        categoriaId: 0,
        nombre: nombre,
        descripcion: _descripcionController.text.trim(),
        precio: precio,
        cantidad: 0,
        esCombo: true,
      );

      final savedCombo = widget.combo == null
          ? await _apiService.createCombo(combo)
          : await _apiService.updateCombo(combo);

      // Eliminar items existentes si es edición
      if (widget.combo != null) {
        await _apiService.deleteComboItems(widget.combo!.id!);
      }

      // Guardar items
      for (final item in _items) {
        await _apiService.addComboItem(
          ComboItem(
            comboId: savedCombo.id!,
            productoId: item.productoId,
            cantidad: item.cantidad,
          ),
        );
      }

      widget.onSave();
      if (mounted) Navigator.pop(context);

      if (_warningMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Combo guardado. $_warningMessage'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _ProductoSelectorDialog(
        productos: _productosFiltrados,
        onSelect: (producto) {
          setState(() {
            _items.add(
              ComboItem(
                comboId: widget.combo?.id ?? 0,
                productoId: producto.id!,
                cantidad: 1,
                nombreProducto: producto.nombre,
              ),
            );
          });
          _validarStock();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.combo == null ? 'Nuevo Combo' : 'Editar Combo'),
        backgroundColor: AppConfig.secondaryColor,
        foregroundColor: AppConfig.secondaryContrastColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del combo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _precioController,
                    decoration: const InputDecoration(
                      labelText: 'Precio del combo',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Warning de stock
                  if (_warningMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _warningMessage!,
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Productos incluidos',
                        style: theme.textTheme.titleMedium,
                      ),
                      ElevatedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.accentColor,
                          foregroundColor: AppConfig.accentContrastColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Agrega productos al combo',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _buildItemCard(item, index, isDark, theme);
                      },
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveCombo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        foregroundColor: AppConfig.primaryContrastColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Guardar Combo',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildItemCard(
    ComboItem item,
    int index,
    bool isDark,
    ThemeData theme,
  ) {
    final producto = _productosFiltrados
        .where((p) => p.id == item.productoId)
        .firstOrNull;
    final precioProducto = producto?.precio ?? 0;
    final tieneStock = producto != null && producto.cantidad >= item.cantidad;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? Colors.grey[850] : Colors.grey[50],
      child: ListTile(
        leading: Icon(
          tieneStock ? Icons.check_circle : Icons.warning,
          color: tieneStock ? SubliriumColors.stockOkText : Colors.orange,
        ),
        title: Text(
          item.nombreProducto ?? 'Producto #${item.productoId}',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Cantidad: ${item.cantidad}  •  Precio c/u: \$${precioProducto.toStringAsFixed(2)}',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onPressed: () => _editarCantidad(index, item),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              onPressed: () {
                setState(() => _items.removeAt(index));
                _validarStock();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editarCantidad(int index, ComboItem item) {
    final controller = TextEditingController(text: item.cantidad.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cantidad'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Cantidad',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final cantidad = int.tryParse(controller.text) ?? 1;
              if (cantidad > 0) {
                setState(() {
                  _items[index] = item.copyWith(cantidad: cantidad);
                });
                _validarStock();
              }
              Navigator.pop(context);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}

class _ProductoSelectorDialog extends StatelessWidget {
  final List<Producto> productos;
  final Function(Producto) onSelect;

  const _ProductoSelectorDialog({
    required this.productos,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar producto'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: productos.length,
          itemBuilder: (context, index) {
            final producto = productos[index];
            return ListTile(
              title: Text(producto.nombre),
              subtitle: Text(
                'Precio c/u: \$${producto.precio?.toStringAsFixed(2) ?? '0.00'} • Stock: ${producto.cantidad}',
              ),
              trailing: producto.cantidad == 0
                  ? const Icon(Icons.warning, color: Colors.orange)
                  : null,
              onTap: () {
                onSelect(producto);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
