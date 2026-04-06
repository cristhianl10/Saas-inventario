import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/subscription_service.dart';
import '../utils/plan_upgrade_helper.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final proveedores = await widget.apiService.getProveedores();
    if (!mounted) return;
    setState(() {
      _proveedores = proveedores;
      _isLoading = false;
    });
  }

  Future<void> _showProveedorDialog([Proveedor? proveedor]) async {
    final hasAccess = await SubscriptionService.hasFeature('suppliers');
    if (!hasAccess) {
      PlanUpgradeHelper.showUpgradeDialog(
        context,
        'Gestionar Proveedores',
        planRequired: 'Básico',
      );
      return;
    }

    final nombreController = TextEditingController(
      text: proveedor?.nombre ?? '',
    );
    final telefonoController = TextEditingController(
      text: proveedor?.telefono ?? '',
    );
    final notasController = TextEditingController();
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
              const SizedBox(height: 12),
              TextField(
                controller: notasController,
                decoration: const InputDecoration(labelText: 'Notas'),
                maxLines: 3,
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
              if (nombre.isEmpty) return;

              if (isEditing) {
                await widget.apiService.updateProveedor(
                  proveedor.copyWith(
                    nombre: nombre,
                    telefono: telefonoController.text.trim().isEmpty
                        ? null
                        : telefonoController.text.trim(),
                  ),
                );
              } else {
                await widget.apiService.createProveedor(
                  Proveedor(
                    nombre: nombre,
                    telefono: telefonoController.text.trim().isEmpty
                        ? null
                        : telefonoController.text.trim(),
                  ),
                );
              }

              if (!mounted) return;
              Navigator.pop(dialogContext);
              await _loadData();
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
      await _loadData();
    }
  }

  Future<void> _showOrdenDialog(Proveedor proveedor) async {
    final titleController = TextEditingController(text: 'Orden de compra');
    final detailsController = TextEditingController();
    final unitsController = TextEditingController(text: '1');
    final amountController = TextEditingController(text: '0');
    final items = <Map<String, dynamic>>[];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart),
                    const SizedBox(width: 8),
                    Text(
                      'Nueva orden para ${proveedor.nombre}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Referencia/Pedido',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: unitsController,
                        decoration: const InputDecoration(
                          labelText: 'Unidades',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Monto estimado',
                          prefixText: '\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Detalles (opcional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final title = titleController.text.trim().isEmpty
                          ? 'Orden de compra'
                          : titleController.text.trim();
                      final units = int.tryParse(unitsController.text) ?? 0;
                      final amount =
                          double.tryParse(amountController.text) ?? 0;

                      try {
                        await widget.apiService.createPurchaseOrder({
                          'provider_id': proveedor.id,
                          'title': title,
                          'details': detailsController.text.trim().isEmpty
                              ? null
                              : detailsController.text.trim(),
                          'units': units,
                          'amount': amount,
                          'status': 'requested',
                        });

                        if (!mounted) return;
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Orden creada')),
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
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Orden'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
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
                              if (value == 'edit') {
                                _showProveedorDialog(proveedor);
                              } else if (value == 'order') {
                                _showOrdenDialog(proveedor);
                              } else if (value == 'history') {
                                _showHistorialProveedor(proveedor);
                              } else if (value == 'delete') {
                                _deleteProveedor(proveedor);
                              }
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
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Eliminar',
                                      style: TextStyle(color: Colors.red),
                                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  if (_stats != null) ...[
                    _buildStatsCard(),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'Órdenes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_ordenes.isEmpty)
                    _buildEmptyState('Sin órdenes registradas')
                  else
                    ..._ordenes.map((o) => _buildOrdenCard(o)),
                  const SizedBox(height: 24),
                  const Text(
                    'Historial de Recepciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_historial.isEmpty)
                    _buildEmptyState('Sin recepciones registradas')
                  else
                    ..._historial.map((h) => _buildHistorialCard(h)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Comprado',
                    '\$${((_stats!['total_comprado'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Unidades',
                    '${_stats!['total_unidades'] ?? 0}',
                    Icons.inventory_2,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Órdenes',
                    '${_stats!['ordenes_completadas'] ?? 0}',
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            if (_stats!['ultima_compra'] != null) ...[
              const Divider(),
              Text(
                'Última compra: ${_dateFormat.format(DateTime.parse(_stats!['ultima_compra']))}',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppConfig.primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildOrdenCard(Map<String, dynamic> orden) {
    final status = orden['status'] as String? ?? 'draft';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'requested':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'received':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.edit_note;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(orden['title'] ?? 'Orden'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_dateFormat.format(DateTime.parse(orden['created_at']))),
            if (orden['details'] != null)
              Text(
                orden['details'],
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${(orden['amount'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${orden['units'] ?? 0} uds',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorialCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          child: const Icon(Icons.inventory, color: Colors.green),
        ),
        title: Text(item['product_name'] ?? 'Producto'),
        subtitle: Text(_dateFormat.format(DateTime.parse(item['received_at']))),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${(item['total_cost'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${item['quantity']} uds',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Text(message, style: TextStyle(color: Colors.grey[600])),
    );
  }

  DateFormat get _dateFormat => DateFormat('dd/MM/yyyy');
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historial.isEmpty) {
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
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
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
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${(item['total_cost'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${item['quantity']} uds',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
