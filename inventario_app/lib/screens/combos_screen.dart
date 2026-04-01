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
      setState(() {
        _combos = combos;
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Combo eliminado')),
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

  void _showComboDialog([Producto? combo]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComboEditorScreen(
          combo: combo,
          productos: _productos,
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Stock: ${combo.cantidad}',
                    style: theme.textTheme.bodySmall,
                  ),
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
  final VoidCallback onSave;

  const ComboEditorScreen({
    super.key,
    this.combo,
    required this.productos,
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
  final _cantidadController = TextEditingController(text: '1');
  
  List<ComboItem> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.combo != null) {
      _nombreController.text = widget.combo!.nombre;
      _descripcionController.text = widget.combo!.descripcion ?? '';
      _precioController.text = widget.combo!.precio?.toStringAsFixed(2) ?? '0.00';
      _cantidadController.text = widget.combo!.cantidad.toString();
      _loadComboItems();
    }
  }

  Future<void> _loadComboItems() async {
    if (widget.combo?.id == null) return;
    setState(() => _isLoading = true);
    try {
      final items = await _apiService.getComboItems(widget.combo!.id!);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCombo() async {
    final nombre = _nombreController.text.trim();
    final precio = double.tryParse(_precioController.text) ?? 0;
    final cantidad = int.tryParse(_cantidadController.text) ?? 1;

    if (nombre.isEmpty || precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y precio son obligatorios')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final combo = Producto(
        id: widget.combo?.id,
        categoriaId: 0, // Los combos no tienen categoría
        nombre: nombre,
        descripcion: _descripcionController.text.trim(),
        precio: precio,
        cantidad: cantidad,
        esCombo: true,
      );

      final savedCombo = widget.combo == null
          ? await _apiService.createCombo(combo)
          : await _apiService.updateCombo(combo);

      // Save items
      for (final item in _items) {
        if (item.id == null) {
          await _apiService.addComboItem(
            ComboItem(
              comboId: savedCombo.id!,
              productoId: item.productoId,
              cantidad: item.cantidad,
            ),
          );
        }
      }

      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _ProductoSelectorDialog(
        productos: widget.productos,
        onSelect: (producto) {
          setState(() {
            _items.add(ComboItem(
              comboId: widget.combo?.id ?? 0,
              productoId: producto.id!,
              cantidad: 1,
              nombreProducto: producto.nombre,
            ));
          });
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _precioController,
                          decoration: const InputDecoration(
                            labelText: 'Precio del combo',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _cantidadController,
                          decoration: const InputDecoration(
                            labelText: 'Stock inicial',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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

  Widget _buildItemCard(ComboItem item, int index, bool isDark, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? Colors.grey[850] : Colors.grey[50],
      child: ListTile(
        title: Text(item.nombreProducto ?? 'Producto #${item.productoId}'),
        subtitle: Text('Cantidad: ${item.cantidad}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () {
                // Editar cantidad
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cantidad'),
                    content: TextField(
                      controller: TextEditingController(text: item.cantidad.toString()),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final cantidad = int.tryParse(value) ?? 1;
                        if (cantidad > 0) {
                          setState(() {
                            _items[index] = item.copyWith(cantidad: cantidad);
                          });
                        }
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Aceptar'),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: () {
                setState(() {
                  _items.removeAt(index);
                });
              },
            ),
          ],
        ),
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
              subtitle: Text('\$${producto.precio?.toStringAsFixed(2) ?? '0.00'}'),
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
