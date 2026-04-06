import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final ApiService _apiService = ApiService();
  final _dateFormat = DateFormat('dd/MM/yyyy');
  List<Cliente> _clientes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    setState(() => _isLoading = true);
    try {
      final clientes = await _apiService.getClientes();
      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showClienteDialog([Cliente? cliente]) async {
    final nombreController = TextEditingController(text: cliente?.nombre ?? '');
    final telefonoController = TextEditingController(
      text: cliente?.telefono ?? '',
    );
    final emailController = TextEditingController(text: cliente?.email ?? '');
    final direccionController = TextEditingController(
      text: cliente?.direccion ?? '',
    );
    final notasController = TextEditingController(text: cliente?.notas ?? '');
    final isEditing = cliente != null;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente'),
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
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notasController,
                decoration: const InputDecoration(labelText: 'Notas'),
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
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreController.text.trim();
              if (nombre.isEmpty) return;

              try {
                if (isEditing) {
                  await _apiService.updateCliente(
                    cliente.copyWith(
                      nombre: nombre,
                      telefono: telefonoController.text.trim().isEmpty
                          ? null
                          : telefonoController.text.trim(),
                      email: emailController.text.trim().isEmpty
                          ? null
                          : emailController.text.trim(),
                      direccion: direccionController.text.trim().isEmpty
                          ? null
                          : direccionController.text.trim(),
                      notas: notasController.text.trim().isEmpty
                          ? null
                          : notasController.text.trim(),
                    ),
                  );
                } else {
                  await _apiService.createCliente(
                    Cliente(
                      nombre: nombre,
                      telefono: telefonoController.text.trim().isEmpty
                          ? null
                          : telefonoController.text.trim(),
                      email: emailController.text.trim().isEmpty
                          ? null
                          : emailController.text.trim(),
                      direccion: direccionController.text.trim().isEmpty
                          ? null
                          : direccionController.text.trim(),
                      notas: notasController.text.trim().isEmpty
                          ? null
                          : notasController.text.trim(),
                    ),
                  );
                }
                if (!mounted) return;
                Navigator.pop(dialogContext);
                _loadClientes();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(isEditing ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCliente(Cliente cliente) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar cliente?'),
        content: Text('${cliente.nombre} será eliminado.'),
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
      await _apiService.deleteCliente(cliente.id!);
      _loadClientes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clientes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay clientes registrados',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los clientes se agregan al registrar una venta',
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
              itemCount: _clientes.length,
              itemBuilder: (context, index) {
                final cliente = _clientes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _HistorialClienteScreen(
                          cliente: cliente,
                          apiService: _apiService,
                          dateFormat: _dateFormat,
                        ),
                      ),
                    ),
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
                              cliente.nombre.isNotEmpty
                                  ? cliente.nombre[0].toUpperCase()
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
                                  cliente.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (cliente.telefono != null)
                                  Text(
                                    cliente.telefono!,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                  ),
                                Text(
                                  'Ver historial de compras',
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
                                _showClienteDialog(cliente);
                              } else if (value == 'delete') {
                                _deleteCliente(cliente);
                              }
                            },
                            itemBuilder: (context) => [
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
        onPressed: () => _showClienteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HistorialClienteScreen extends StatefulWidget {
  final Cliente cliente;
  final ApiService apiService;
  final DateFormat dateFormat;

  const _HistorialClienteScreen({
    required this.cliente,
    required this.apiService,
    required this.dateFormat,
  });

  @override
  State<_HistorialClienteScreen> createState() =>
      _HistorialClienteScreenState();
}

class _HistorialClienteScreenState extends State<_HistorialClienteScreen> {
  List<Venta> _ventas = [];
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
      final ventas = await widget.apiService.getVentasPorCliente(
        widget.cliente.id!,
      );
      final stats = await widget.apiService.getClienteStats(widget.cliente.id!);
      if (!mounted) return;
      setState(() {
        _ventas = ventas;
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
        title: Text(widget.cliente.nombre),
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
                  if (widget.cliente.telefono != null ||
                      widget.cliente.email != null) ...[
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.cliente.telefono != null)
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 18),
                                  const SizedBox(width: 8),
                                  Text(widget.cliente.telefono!),
                                ],
                              ),
                            if (widget.cliente.email != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.email, size: 18),
                                  const SizedBox(width: 8),
                                  Text(widget.cliente.email!),
                                ],
                              ),
                            ],
                            if (widget.cliente.direccion != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(widget.cliente.direccion!),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_stats != null) _buildStatsCard(),
                  const SizedBox(height: 24),
                  const Text(
                    'Historial de Compras',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_ventas.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Text(
                        'Sin compras registradas',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  else
                    ..._ventas.map((v) => _buildVentaCard(v)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total Compras',
                '${_stats!['total_compras'] ?? 0}',
                Icons.shopping_cart,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Total Gastado',
                '\$${((_stats!['total_gastado'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                Icons.attach_money,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Productos',
                '${_stats!['total_productos'] ?? 0}',
                Icons.inventory_2,
              ),
            ),
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildVentaCard(Venta venta) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          child: const Icon(Icons.receipt, color: Colors.green),
        ),
        title: Text(widget.dateFormat.format(venta.fechaVenta)),
        subtitle: Text('${venta.cantidad} unidad(es)'),
        trailing: Text(
          '\$${venta.total.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
