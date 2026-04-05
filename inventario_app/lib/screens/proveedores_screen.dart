import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/role_service.dart';
import '../services/supplier_insights_service.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final ApiService _apiService = ApiService();
  List<Proveedor> _proveedores = [];
  bool _isLoading = true;

  bool get _canEdit => RoleService.canManageCatalog;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final proveedores = await _apiService.getProveedores();
    if (!mounted) return;
    setState(() {
      _proveedores = proveedores;
      _isLoading = false;
    });
  }

  Future<void> _showProveedorDialog([Proveedor? proveedor]) async {
    final nombreController = TextEditingController(text: proveedor?.nombre ?? '');
    final telefonoController = TextEditingController(text: proveedor?.telefono ?? '');
    final profile = proveedor?.id != null
        ? SupplierInsightsService.getProfileFor(proveedor!.id!)
        : null;
    final contactoController = TextEditingController(text: profile?.contactName ?? '');
    final emailController = TextEditingController(text: profile?.email ?? '');
    final direccionController = TextEditingController(text: profile?.address ?? '');
    final notasController = TextEditingController(text: profile?.notes ?? '');
    final isEditing = proveedor != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEditing ? 'Editar proveedor' : 'Nuevo proveedor'),
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
                decoration: const InputDecoration(labelText: 'Telefono'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactoController,
                decoration: const InputDecoration(labelText: 'Contacto'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: direccionController,
                decoration: const InputDecoration(labelText: 'Direccion'),
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

              Proveedor savedProvider;
              if (isEditing) {
                savedProvider = await _apiService.updateProveedor(
                  proveedor.copyWith(
                    nombre: nombre,
                    telefono: telefonoController.text.trim().isEmpty
                        ? null
                        : telefonoController.text.trim(),
                  ),
                );
              } else {
                savedProvider = await _apiService.createProveedor(
                  Proveedor(
                    nombre: nombre,
                    telefono: telefonoController.text.trim().isEmpty
                        ? null
                        : telefonoController.text.trim(),
                  ),
                );
              }

              await SupplierInsightsService.saveProfile(
                SupplierProfile(
                  providerId: savedProvider.id ?? 0,
                  contactName: contactoController.text.trim().isEmpty
                      ? null
                      : contactoController.text.trim(),
                  email: emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                  address: direccionController.text.trim().isEmpty
                      ? null
                      : direccionController.text.trim(),
                  notes: notasController.text.trim().isEmpty
                      ? null
                      : notasController.text.trim(),
                ),
              );

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

  Future<void> _showOrderDialog(Proveedor proveedor) async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    final unitsController = TextEditingController(text: '0');
    final amountController = TextEditingController(text: '0');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Nueva orden para ${proveedor.nombre}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Pedido o referencia'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitsController,
                decoration: const InputDecoration(labelText: 'Unidades'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Monto estimado'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'Detalle'),
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
              await SupplierInsightsService.saveOrder(
                PurchaseOrder(
                  id: '${proveedor.id}-${DateTime.now().millisecondsSinceEpoch}',
                  providerId: proveedor.id ?? 0,
                  title: titleController.text.trim().isEmpty
                      ? 'Orden de compra'
                      : titleController.text.trim(),
                  details: detailsController.text.trim().isEmpty
                      ? null
                      : detailsController.text.trim(),
                  units: int.tryParse(unitsController.text.trim()) ?? 0,
                  amount: double.tryParse(amountController.text.trim()) ?? 0,
                  status: PurchaseOrderStatus.requested,
                  createdAt: DateTime.now(),
                ),
              );
              if (!mounted) return;
              Navigator.pop(dialogContext);
              setState(() {});
            },
            child: const Text('Guardar orden'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProveedor(Proveedor proveedor) async {
    await _apiService.deleteProveedor(proveedor.id!);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: _canEdit
          ? FloatingActionButton(
              onPressed: _showProveedorDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _proveedores.isEmpty
              ? const Center(child: Text('Aun no hay proveedores registrados.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final proveedor = _proveedores[index];
                    final profile = proveedor.id != null
                        ? SupplierInsightsService.getProfileFor(proveedor.id!)
                        : null;
                    final orders = proveedor.id != null
                        ? SupplierInsightsService.getOrdersFor(proveedor.id!)
                        : <PurchaseOrder>[];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white12 : SubliriumColors.border,
                        ),
                      ),
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
                                      proveedor.nombre,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      proveedor.telefono ?? 'Sin telefono',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (_canEdit) ...[
                                IconButton(
                                  onPressed: () => _showProveedorDialog(proveedor),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () => _deleteProveedor(proveedor),
                                  icon: const Icon(Icons.delete_outline),
                                  color: SubliriumColors.deleteText,
                                ),
                              ],
                            ],
                          ),
                          if ((profile?.contactName ?? '').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('Contacto: ${profile!.contactName}'),
                          ],
                          if ((profile?.email ?? '').isNotEmpty)
                            Text('Correo: ${profile!.email}'),
                          if ((profile?.address ?? '').isNotEmpty)
                            Text('Direccion: ${profile!.address}'),
                          if ((profile?.notes ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              profile!.notes!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Ordenes e historial',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const Spacer(),
                              if (_canEdit)
                                TextButton.icon(
                                  onPressed: () => _showOrderDialog(proveedor),
                                  icon: const Icon(Icons.add_circle_outline, size: 18),
                                  label: const Text('Nueva orden'),
                                ),
                            ],
                          ),
                          if (orders.isEmpty)
                            Text(
                              'Sin ordenes registradas todavia.',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          else
                            ...orders.take(4).map((order) {
                              final statusColor = switch (order.status) {
                                PurchaseOrderStatus.received => SubliriumColors.stockOkText,
                                PurchaseOrderStatus.cancelled => SubliriumColors.deleteText,
                                _ => AppConfig.secondaryColor,
                              };
                              return Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black26 : const Color(0xFFF7F4ED),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(order.title)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            order.status.label,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${order.units} uds · \$${order.amount.toStringAsFixed(2)} · ${DateFormat('dd/MM/yyyy').format(order.createdAt)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    if ((order.details ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        order.details!,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                    if (_canEdit && order.status == PurchaseOrderStatus.requested)
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          TextButton(
                                            onPressed: () async {
                                              await SupplierInsightsService.updateOrderStatus(
                                                order.id,
                                                PurchaseOrderStatus.received,
                                              );
                                              setState(() {});
                                            },
                                            child: const Text('Marcar recibida'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              await SupplierInsightsService.updateOrderStatus(
                                                order.id,
                                                PurchaseOrderStatus.cancelled,
                                              );
                                              setState(() {});
                                            },
                                            child: const Text('Cancelar'),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemCount: _proveedores.length,
                ),
    );
  }
}
