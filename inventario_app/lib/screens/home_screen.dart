import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../providers/data_providers.dart';
import 'productos_screen.dart';
import 'resumen_screen.dart';
import 'tabla_precios_screen.dart';
import 'combos_screen.dart';
import 'configuracion_screen.dart';
import 'clientes_screen.dart';
import 'proveedores_screen.dart';
import 'reportes_screen.dart';
import '../main.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _showWelcomeMessage();
  }

  void _showWelcomeMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Bienvenido ${AppConfig.brandName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: SubliriumColors.stockOkText,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppConfig.configNotifier,
      builder: (context, _, __) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildInicio(), // 0 - Inicio
              const ProductosScreen(), // 1 - Inventario
              const ResumenScreen(), // 2 - Ventas
              _buildMasMenu(), // 3 - Más
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    final stockAlertCount = ref.watch(stockAlertCountProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(index: 0, icon: Icons.home, label: 'Inicio'),
              _buildNavItem(
                index: 1,
                icon: Icons.inventory_2,
                label: 'Inventario',
                badge: stockAlertCount > 0 ? stockAlertCount : null,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.point_of_sale,
                label: 'Ventas',
              ),
              _buildNavItem(index: 3, icon: Icons.more_horiz, label: 'Más'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int? badge,
  }) {
    final isActive = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppConfig.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isActive
                        ? AppConfig.primaryColor
                        : (isDark ? Colors.white54 : Colors.grey),
                  ),
                  if (badge != null)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : badge.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive
                      ? AppConfig.primaryColor
                      : (isDark ? Colors.white54 : Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInicio() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productosAsync = ref.watch(productosStreamProvider);
    final ventasAsync = ref.watch(recientesVentasProvider);
    final clientesAsync = ref.watch(clientesStreamProvider);
    final stockAlertCount = ref.watch(stockAlertCountProvider);
    final lowStockCount = ref.watch(lowStockCountProvider);
    final totalVentas = ref.watch(totalVentasProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppConfig.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppConfig.primaryColor, AppConfig.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  AppConfig.brandName.isNotEmpty
                                      ? AppConfig.brandName[0].toUpperCase()
                                      : 'S',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppConfig.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppConfig.brandName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'StockFlow',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
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
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    icon: Icons.inventory_2,
                    value: productosAsync.when(
                      data: (p) => p.length.toString(),
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                    label: 'Productos',
                    color: AppConfig.primaryColor,
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    icon: Icons.point_of_sale,
                    value: '\$${totalVentas.toStringAsFixed(0)}',
                    label: 'Ventas del mes',
                    color: Colors.green,
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    icon: Icons.warning,
                    value: stockAlertCount.toString(),
                    label: 'Stock bajo',
                    color: Colors.orange,
                    isDark: isDark,
                    showWarning: stockAlertCount > 0,
                  ),
                  _buildStatCard(
                    icon: Icons.people,
                    value: clientesAsync.when(
                      data: (c) => c.length.toString(),
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                    label: 'Clientes',
                    color: AppConfig.secondaryColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ventas Recientes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 2),
                    child: const Text('Ver todas'),
                  ),
                ],
              ),
            ),
          ),
          ventasAsync.when(
            data: (ventas) {
              if (ventas.isEmpty) {
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sin ventas aún',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final venta = ventas[index];
                    return _buildVentaCard(venta, isDark);
                  }, childCount: ventas.length.clamp(0, 5)),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
    bool showWarning = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    if (showWarning)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 14,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVentaCard(Venta venta, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppConfig.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(Icons.receipt, color: AppConfig.primaryColor),
          ),
        ),
        title: Text(
          'Producto #${venta.productoId}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          venta.vendidoA ?? 'Sin cliente',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${venta.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${venta.cantidad} uds',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Más opciones'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildMenuItem(
                icon: Icons.attach_money,
                label: 'Precios',
                color: Colors.green,
                onTap: () => _navigateTo(const TablaPreciosScreen()),
              ),
              _buildMenuItem(
                icon: Icons.inventory,
                label: 'Combos',
                color: Colors.purple,
                onTap: () => _navigateTo(const CombosScreen()),
              ),
              _buildMenuItem(
                icon: Icons.analytics,
                label: 'Reportes',
                color: Colors.orange,
                onTap: () => _navigateTo(const ReportesScreen()),
              ),
              _buildMenuItem(
                icon: Icons.local_shipping,
                label: 'Proveedores',
                color: AppConfig.secondaryColor,
                onTap: () => _navigateTo(const ProveedoresScreen()),
              ),
              _buildMenuItem(
                icon: Icons.people,
                label: 'Clientes',
                color: Colors.pink,
                onTap: () => _navigateTo(const ClientesScreen()),
              ),
              _buildMenuItem(
                icon: Icons.settings,
                label: 'Config',
                color: Colors.grey,
                onTap: () => _navigateTo(const ConfiguracionScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
