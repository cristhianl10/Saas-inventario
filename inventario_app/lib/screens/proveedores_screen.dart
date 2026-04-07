import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final _dateFormat = DateFormat('dd/MM/yyyy');
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Proveedores', icon: Icon(Icons.business)),
            Tab(text: 'Historial', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProveedoresTab(apiService: _apiService),
          _HistorialTab(apiService: _apiService, dateFormat: _dateFormat),
        ],
      ),
    );
  }
}

class _ProveedoresTab extends StatefulWidget {
  final ApiService apiService;
  const _ProveedoresTab({required this.apiService});

  @override
  State<_ProveedoresTab> createState() => _ProveedoresTabState();
}

class _ProveedoresTabState extends State<_ProveedoresTab> {
  List<Proveedor> _proveedores = [];
  List<Producto> _productos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final proveedores = await widget.apiService.getProveedores();
    final productos = await widget.apiService.getProductos();
    if (!mounted) return;
    setState(() {
      _proveedores = proveedores;
      _productos = productos;
      _isLoading = false;
    });
  }

  Future<void> _showProveedorDialog([Proveedor? proveedor]) async {
    final nombreController = TextEditingController(
      text: proveedor?.nombre ?? '',
    );
    final telefonoController = TextEditingController(
      text: proveedor?.telefono ?? '',
    );
    final isEditing = proveedor != null;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
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
              if (nombreController.text.trim().isEmpty) return;
              if (isEditing) {
                await widget.apiService.updateProveedor(
                  proveedor!.copyWith(
                    nombre: nombreController.text.trim(),
                    telefono: telefonoController.text.trim().isEmpty
                        ? null
                        : telefonoController.text.trim(),
                  ),
                );
              } else {
                await widget.apiService.createProveedor(
                  Proveedor(
                    nombre: nombreController.text.trim(),
                    telefono: telefonoController.text.trim().isEmpty
                        ? null
                        : telefonoController.text.trim(),
                  ),
                );
              }
              if (!mounted) return;
              Navigator.pop(dialogContext);
              _loadData();
            },
            child: Text(isEditing ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProveedor(Proveedor proveedor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar proveedor?'),
        content: Text('${proveedor.nombre} será eliminado.'),
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
      await widget.apiService.deleteProveedor(proveedor.id!);
      _loadData();
    }
  }

  Future<void> _showOrdenDialog(Proveedor proveedor) async {
    final productos = await widget.apiService.getProductos();
    final categorias = await widget.apiService.getCategorias();
    if (!mounted) return;

    // Filtrar categorías excluyendo "Combo"
    final categoriasFiltradas = categorias
        .where((c) => c.nombre.toLowerCase() != 'combo')
        .toList();

    // Filtrar productos excluyendo combos
    final productosFiltrados = productos
        .where((p) => !p.esCombo)
        .toList();

    Categoria? categoriaSeleccionada;
    Producto? productoSeleccionado;
    final cantidadController = TextEditingController(text: '1');
    final costoController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final productosDropdown = categoriaSeleccionada == null
              ? productosFiltrados
              : productosFiltrados
                    .where((p) => p.categoriaId == categoriaSeleccionada!.id)
                    .toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.shopping_cart),
                const SizedBox(width: 8),
                Expanded(child: Text('Orden a ${proveedor.nombre}')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categoría:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Categoria?>(
                    value: categoriaSeleccionada,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Todas',
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todas las categorías'),
                      ),
                      ...categoriasFiltradas.map(
                        (c) =>
                            DropdownMenuItem(value: c, child: Text(c.nombre)),
                      ),
                    ],
                    onChanged: (c) => setDialogState(() {
                      categoriaSeleccionada = c;
                      productoSeleccionado = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Producto:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Producto?>(
                    value: productoSeleccionado,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Seleccionar',
                    ),
                    isExpanded: true,
                    items: productosDropdown.isEmpty
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Sin productos'),
                            ),
                          ]
                        : productosDropdown
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    '${p.nombre} (Stock: ${p.cantidad})',
                                  ),
                                ),
                              )
                              .toList(),
                    onChanged: (p) => setDialogState(() {
                      productoSeleccionado = p;
                      if (p?.costo != null)
                        costoController.text = p!.costo!.toStringAsFixed(2);
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cantidadController,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: costoController,
                          decoration: const InputDecoration(
                            labelText: 'Costo unit.',
                            prefixText: '\$ ',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
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
                onPressed: productoSeleccionado == null
                    ? null
                    : () async {
                        final cantidad =
                            int.tryParse(cantidadController.text) ?? 0;
                        final costo =
                            double.tryParse(costoController.text) ?? 0;
                        if (cantidad <= 0) return;
                        try {
                          await widget.apiService.createPurchaseOrder({
                            'provider_id': proveedor.id,
                            'title': 'Compra a ${proveedor.nombre}',
                            'details': productoSeleccionado!.nombre,
                            'units': cantidad,
                            'amount': cantidad * costo,
                            'status': 'requested',
                          });
                          if (!mounted) return;
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Orden creada: $cantidad x ${productoSeleccionado!.nombre}',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: const Text('Crear Orden'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showReceiveDialog(Proveedor proveedor) async {
    final ordenes = await widget.apiService.getPurchaseOrders(
      providerId: proveedor.id,
    );
    if (!mounted) return;

    final pendientes = ordenes
        .where((o) => o['status'] == 'requested')
        .toList();
    if (pendientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay órdenes pendientes')),
      );
      return;
    }

    Map<String, dynamic>? ordenSeleccionada;
    Producto? productoSeleccionado;
    bool actualizarStock = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(child: Text('Recibir de ${proveedor.nombre}')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona la orden:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: ordenSeleccionada,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: pendientes
                      .map(
                        (o) => DropdownMenuItem(
                          value: o,
                          child: Text(
                            '${o['title']} - ${o['units']} uds - \$${((o['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (o) => setDialogState(() {
                    ordenSeleccionada = o;
                    productoSeleccionado = null;
                  }),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selecciona el producto a actualizar:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Producto>(
                  value: productoSeleccionado,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ninguno (solo registrar)',
                  ),
                  isExpanded: true,
                  items: _productos
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.nombre} (Stock: ${p.cantidad})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (p) =>
                      setDialogState(() => productoSeleccionado = p),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Actualizar stock'),
                  subtitle: const Text('Añadir cantidad al inventario'),
                  value: actualizarStock,
                  onChanged: (v) => setDialogState(() => actualizarStock = v),
                  contentPadding: EdgeInsets.zero,
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
              onPressed: ordenSeleccionada == null
                  ? null
                  : () async {
                      try {
                        final cantidad =
                            (ordenSeleccionada!['units'] as num?)?.toInt() ?? 0;
                        final amount =
                            (ordenSeleccionada!['amount'] as num?)
                                ?.toDouble() ??
                            0;
                        await widget.apiService.receivePurchaseOrderSimple(
                          orderId: ordenSeleccionada!['id'],
                          providerId: proveedor.id!,
                          productId: productoSeleccionado?.id ?? 0,
                          productName:
                              productoSeleccionado?.nombre ??
                              ordenSeleccionada!['details'] ??
                              'Orden',
                          quantity: cantidad,
                          unitCost: cantidad > 0 ? amount / cantidad : 0,
                          updateStock:
                              actualizarStock && productoSeleccionado != null,
                        );
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              actualizarStock && productoSeleccionado != null
                                  ? 'Pedido recibido y stock actualizado'
                                  : 'Pedido recibido',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHistorialProveedor(Proveedor proveedor) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _HistorialProveedorScreen(
          proveedor: proveedor,
          apiService: widget.apiService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _proveedores.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: isDark ? Colors.white38 : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay proveedores',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca + para agregar',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _proveedores.length,
              itemBuilder: (context, index) {
                final proveedor = _proveedores[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _showHistorialProveedor(proveedor),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppConfig.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              proveedor.nombre.isNotEmpty
                                  ? proveedor.nombre[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: AppConfig.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  proveedor.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (proveedor.telefono != null)
                                  Text(
                                    proveedor.telefono!,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                  ),
                                Text(
                                  'Ver historial',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppConfig.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'order')
                                _showOrdenDialog(proveedor);
                              else if (value == 'receive')
                                _showReceiveDialog(proveedor);
                              else if (value == 'history')
                                _showHistorialProveedor(proveedor);
                              else if (value == 'edit')
                                _showProveedorDialog(proveedor);
                              else if (value == 'delete')
                                _deleteProveedor(proveedor);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'order',
                                child: Row(
                                  children: [
                                    Icon(Icons.add_shopping_cart, size: 20),
                                    SizedBox(width: 8),
                                    Text('Nueva orden'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'receive',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Recibir pedido'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'history',
                                child: Row(
                                  children: [
                                    Icon(Icons.history, size: 20),
                                    SizedBox(width: 8),
                                    Text('Ver historial'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Eliminar'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProveedorDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HistorialProveedorScreen extends StatefulWidget {
  final Proveedor proveedor;
  final ApiService apiService;
  const _HistorialProveedorScreen({
    required this.proveedor,
    required this.apiService,
  });

  @override
  State<_HistorialProveedorScreen> createState() =>
      _HistorialProveedorScreenState();
}

class _HistorialProveedorScreenState extends State<_HistorialProveedorScreen> {
  List<Map<String, dynamic>> _ordenes = [];
  List<Map<String, dynamic>> _historial = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final ordenes = await widget.apiService.getPurchaseOrders(
        providerId: widget.proveedor.id,
      );
      final historial = await widget.apiService.getPurchaseHistory(
        providerId: widget.proveedor.id,
      );
      final stats = await widget.apiService.getProviderStats(
        widget.proveedor.id!,
      );
      if (!mounted) return;
      setState(() {
        _ordenes = ordenes;
        _historial = historial;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.proveedor.nombre),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_stats != null)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _statItem(
                              'Total',
                              '\$${((_stats!['total_comprado'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                              Icons.attach_money,
                            ),
                            _statItem(
                              'Unidades',
                              '${_stats!['total_unidades'] ?? 0}',
                              Icons.inventory_2,
                            ),
                            _statItem(
                              'Órdenes',
                              '${_stats!['ordenes_completadas'] ?? 0}',
                              Icons.check_circle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Órdenes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_ordenes.isEmpty)
                    _emptyState('Sin órdenes registradas')
                  else
                    ..._ordenes.map((o) => _ordenCard(o)),
                  const SizedBox(height: 24),
                  const Text(
                    'Historial de Recepciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_historial.isEmpty)
                    _emptyState('Sin recepciones')
                  else
                    ..._historial.map((h) => _historialCard(h)),
                ],
              ),
            ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: AppConfig.primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    ),
  );

  Widget _ordenCard(Map<String, dynamic> orden) {
    final status = orden['status'] as String? ?? 'draft';
    final isPending = status == 'draft' || status == 'requested';
    final color = status == 'requested'
        ? Colors.orange
        : status == 'received'
        ? Colors.green
        : Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(Icons.pending, color: color),
        title: Text(orden['title'] ?? 'Orden'),
        subtitle: Text(_dateFormat.format(DateTime.parse(orden['created_at']))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${((orden['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editOrdenDialog(orden),
              tooltip: 'Editar',
            ),
            if (isPending)
              IconButton(
                icon: const Icon(Icons.cancel, size: 20, color: Colors.red),
                onPressed: () => _cancelOrdenDialog(orden),
                tooltip: 'Cancelar',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editOrdenDialog(Map<String, dynamic> orden) async {
    final titleController = TextEditingController(text: orden['title'] ?? '');
    final detailsController = TextEditingController(
      text: orden['details'] ?? '',
    );
    final unitsController = TextEditingController(
      text: (orden['units'] as num?)?.toString() ?? '0',
    );
    final amountController = TextEditingController(
      text: ((orden['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Orden'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'Detalles'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: unitsController,
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Monto'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
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
              try {
                await widget.apiService.updatePurchaseOrder(orden['id'], {
                  'title': titleController.text.trim(),
                  'details': detailsController.text.trim(),
                  'units': int.tryParse(unitsController.text) ?? 0,
                  'amount': double.tryParse(amountController.text) ?? 0,
                });
                if (!mounted) return;
                Navigator.pop(dialogContext);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Orden actualizada'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrdenDialog(Map<String, dynamic> orden) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Cancelar Orden'),
          ],
        ),
        content: Text('¿Cancelar la orden "${orden['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.apiService.updatePurchaseOrder(orden['id'], {
          'status': 'cancelled',
        });
        _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden cancelada'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _historialCard(Map<String, dynamic> item) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        child: const Icon(Icons.inventory, color: Colors.green),
      ),
      title: Text(item['product_name'] ?? 'Producto'),
      subtitle: Text(_dateFormat.format(DateTime.parse(item['received_at']))),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${((item['total_cost'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${item['quantity']} uds',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _editHistorialDialog(item),
            tooltip: 'Editar',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () => _deleteHistorialDialog(item),
            tooltip: 'Eliminar',
          ),
        ],
      ),
    ),
  );

  Future<void> _editHistorialDialog(Map<String, dynamic> item) async {
    final cantidadController = TextEditingController(
      text: (item['quantity'] as num?)?.toString() ?? '1',
    );
    final costoController = TextEditingController(
      text: ((item['unit_cost'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Recepción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cantidadController,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costoController,
              decoration: const InputDecoration(labelText: 'Costo unitario'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Nota: Para editar recepciones se necesitaría agregar un método en ApiService
              // Por ahora solo se puede eliminar y crear nueva
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Para cambiar datos, elimina y crea una nueva recepción'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHistorialDialog(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Recepción'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Eliminar la recepción de "${item['product_name']}"?'),
            const SizedBox(height: 16),
            const Text(
              '¿Deseas restar la cantidad del stock?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Solo eliminar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Quitar del stock'),
          ),
        ],
      ),
    );

    if (confirmed != null) {
      try {
        await widget.apiService.deletePurchaseHistory(
          item['id'],
          removeFromStock: confirmed,
        );
        _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              confirmed ? 'Eliminado y stock actualizado' : 'Eliminado',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _emptyState(String msg) => Container(
    padding: const EdgeInsets.all(32),
    alignment: Alignment.center,
    child: Text(msg, style: TextStyle(color: Colors.grey[600])),
  );
}

class _HistorialTab extends StatefulWidget {
  final ApiService apiService;
  final DateFormat dateFormat;
  const _HistorialTab({required this.apiService, required this.dateFormat});

  @override
  State<_HistorialTab> createState() => _HistorialTabState();
}

class _HistorialTabState extends State<_HistorialTab> {
  List<Map<String, dynamic>> _historial = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final historial = await widget.apiService.getPurchaseHistory();
      if (!mounted) return;
      setState(() {
        _historial = historial;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteHistorialItem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Recepción'),
          ],
        ),
        content: Text('¿Eliminar la recepción de "${item['product_name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.apiService.deletePurchaseHistory(
          item['id'],
          removeFromStock: false,
        );
        _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recepción eliminada')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_historial.isEmpty)
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Sin historial de compras',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historial.length,
      itemBuilder: (context, index) {
        final item = _historial[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              child: const Icon(Icons.inventory, color: Colors.green),
            ),
            title: Text(item['product_name'] ?? 'Producto'),
            subtitle: Text(
              widget.dateFormat.format(
                DateTime.parse(
                  item['received_at'] ?? DateTime.now().toIso8601String(),
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${((item['total_cost'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${item['quantity']} uds',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _deleteHistorialItem(item),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
