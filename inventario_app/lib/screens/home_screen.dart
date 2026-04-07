import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/live_sync_service.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import 'productos_screen.dart';
import 'reportes_screen.dart';
import 'resumen_screen.dart';
import 'tabla_precios_screen.dart';
import 'combos_screen.dart';
import 'configuracion_screen.dart';
import 'clientes_screen.dart';
import 'proveedores_screen.dart';
import 'auth_screen.dart';
import 'planes_screen.dart';
import 'suscripcion_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final LiveSyncService _liveSyncService = LiveSyncService();
  final TextEditingController _searchController = TextEditingController();
  List<Categoria> _categorias = [];
  Map<int, int> _productosCount = {};
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
    _setupLiveUpdates();
    _showWelcomeMessage();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showScrollToTop) {
        setState(() => _showScrollToTop = show);
      }
    });
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
            duration: const Duration(seconds: 3),
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
    _liveSyncService.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupLiveUpdates() {
    _liveSyncService.watchTables(
      tables: const ['categorias', 'productos'],
      onChange: () {
        if (mounted) {
          _loadCategorias(showLoader: false);
        }
      },
    );
  }

  List<Categoria> get _categoriasFiltradas {
    if (_searchQuery.isEmpty) {
      return _categorias;
    }
    return _categorias.where((categoria) {
      return categoria.nombre.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _loadCategorias({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final categorias = await _apiService.getCategorias();
      final counts = await _apiService.getProductosCountPorCategoria();
      if (!mounted) return;
      setState(() {
        _categorias = categorias;
        _productosCount = counts;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _isNetworkError(String error) {
    final msg = error.toLowerCase();
    return msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('timeout') ||
        msg.contains('internet') ||
        msg.contains('wifi') ||
        msg.contains('host') ||
        msg.contains('dns');
  }

  Future<void> _deleteCategoria(Categoria categoria) async {
    if (categoria.nombre.toLowerCase() == 'combo') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La categoría "Combo" no puede eliminarse'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar categoría?'),
        content: Text(
          'Se eliminarán todos los productos en "${categoria.nombre}".',
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
    if (confirm == true && categoria.id != null) {
      try {
        await _apiService.deleteCategoria(categoria.id!);
        _loadCategorias();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Categoría eliminada')));
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

  void _showCategoriaDialog([Categoria? categoria]) {
    final nombreController = TextEditingController(
      text: categoria?.nombre ?? '',
    );
    final isEditing = categoria != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreController.text.trim();
              if (nombre.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El nombre es obligatorio')),
                );
                return;
              }
              final existe = _categorias.any(
                (c) =>
                    c.nombre.toLowerCase() == nombre.toLowerCase() &&
                    c.id != categoria?.id,
              );
              if (existe) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('La categoría "$nombre" ya existe'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              final nuevaCategoria = Categoria(
                id: categoria?.id,
                nombre: nombre,
              );
              try {
                if (isEditing) {
                  await _apiService.updateCategoria(nuevaCategoria);
                } else {
                  await _apiService.createCategoria(nuevaCategoria);
                }
                _loadCategorias();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(isEditing ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
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
              _buildCategorias(),
              const ProductosScreen(),
              const ResumenScreen(),
              _buildMasMenu(),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
          floatingActionButton: _currentIndex == 0 ? _buildFab() : null,
        );
      },
    );
  }

  Widget? _buildFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showScrollToTop)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FloatingActionButton.small(
              heroTag: 'scroll_to_top_home_btn',
              onPressed: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
              backgroundColor: SubliriumColors.cyan.withValues(alpha: 0.8),
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            ),
          ),
        FloatingActionButton(
          heroTag: 'add_cat_home_btn',
          onPressed: () => _showCategoriaDialog(),
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildCategorias() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? Colors.grey[900] : SubliriumColors.cardBackground;
    final borderColor = isDark ? Colors.grey[700]! : SubliriumColors.border;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          expandedHeight: 100,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              AppConfig.appName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 20,
                color: AppConfig.secondaryContrastColor,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppConfig.secondaryColor, AppConfig.primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: AppConfig.secondaryContrastColor,
              ),
              onPressed: _loadCategorias,
              tooltip: 'Actualizar',
            ),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (_, mode, __) {
                return Switch(
                  value: mode == ThemeMode.dark,
                  activeColor: SubliriumColors.cyan,
                  onChanged: (value) {
                    themeNotifier.value = value
                        ? ThemeMode.dark
                        : ThemeMode.light;
                  },
                );
              },
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: AppConfig.secondaryContrastColor,
              ),
              onSelected: (value) async {
                if (value == 'config') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConfiguracionScreen(),
                    ),
                  );
                  AppConfig.configNotifier.value++;
                } else if (value == 'planes') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlanesScreen()),
                  );
                } else if (value == 'suscripcion') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SuscripcionScreen(),
                    ),
                  );
                } else if (value == 'clientes') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientesScreen()),
                  );
                } else if (value == 'logout') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Cerrando sesión...'),
                        ],
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  try {
                    await Future.delayed(const Duration(milliseconds: 500));
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => AuthScreen(
                            onAuthSuccess: () {},
                            onEmailVerified: (_) {},
                          ),
                        ),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al cerrar sesión: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'planes',
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium, size: 20),
                      SizedBox(width: 8),
                      Text('Cambiar Plan'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'suscripcion',
                  child: Row(
                    children: [
                      Icon(Icons.card_membership, size: 20),
                      SizedBox(width: 8),
                      Text('Mi Plan'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'config',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 20),
                      SizedBox(width: 8),
                      Text('Configurar marca'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clientes',
                  child: Row(
                    children: [
                      Icon(Icons.people, size: 20),
                      SizedBox(width: 8),
                      Text('Clientes'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Cerrar sesión'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar categoría...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey,
                ),
                prefixIcon: Icon(Icons.search, size: 16, color: textColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 16, color: textColor),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: bgColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppConfig.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categorías',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_categoriasFiltradas.length} categorías',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 64,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No se pudo conectar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isNetworkError(_error!)
                          ? 'Verifica tu conexión a internet'
                          : 'Error del servidor',
                      style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadCategorias,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_categoriasFiltradas.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isEmpty ? Icons.folder_open : Icons.search_off,
                    size: 48,
                    color: textColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No hay categorías'
                        : 'No se encontraron categorías',
                    style: TextStyle(color: textColor),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Toca + para crear una',
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final categoria = _categoriasFiltradas[index];
              final count = _productosCount[categoria.id] ?? 0;
              return _buildCategoriaItem(categoria, count);
            }, childCount: _categoriasFiltradas.length),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildCategoriaItem(Categoria categoria, int count) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.grey[800]! : SubliriumColors.border,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductosScreen(categoria: categoria),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: SubliriumColors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.folder_outlined,
                      size: 24,
                      color: SubliriumColors.cyan,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria.nombre,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count productos',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: theme.iconTheme.color,
                      ),
                      onPressed: () => _showCategoriaDialog(categoria),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red[300],
                      ),
                      onPressed: () => _deleteCategoria(categoria),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: theme.iconTheme.color?.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF141414) : Colors.white;
    final navBorder = isDark ? Colors.white10 : const Color(0xFFE5E2DB);

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: navBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildNavItem(
              index: 0,
              iconPath: 'assets/icons/home.svg',
              label: 'Inicio',
              isActive: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            _buildNavItem(
              index: 1,
              iconPath: 'assets/icons/inventory.svg',
              label: 'Inventario',
              isActive: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            _buildNavItem(
              index: 2,
              iconPath: 'assets/icons/stats.svg',
              label: 'Ventas',
              isActive: _currentIndex == 2,
              onTap: () => setState(() => _currentIndex = 2),
            ),
            _buildNavItem(
              index: 3,
              iconPath: 'assets/icons/settings.svg',
              label: 'Más',
              isActive: _currentIndex == 3,
              onTap: () => setState(() => _currentIndex = 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasMenu() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Más opciones'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuCard(
            icon: Icons.table_chart,
            title: 'Tabla de Precios',
            subtitle: 'Precios por cantidad',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TablaPreciosScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            icon: Icons.inventory_2,
            title: 'Combos',
            subtitle: 'Crear paquetes de productos',
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CombosScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            icon: Icons.analytics,
            title: 'Reportes',
            subtitle: 'Ventas, ranking y utilidad',
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportesScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            icon: Icons.business,
            title: 'Proveedores',
            subtitle: 'Gestionar proveedores',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProveedoresScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            icon: Icons.people,
            title: 'Clientes',
            subtitle: 'Historial de clientes',
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClientesScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            icon: Icons.settings,
            title: 'Configuración',
            subtitle: 'Marca y cuenta',
            color: Colors.grey,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfiguracionScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String iconPath,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppConfig.primaryColor;
    final inactiveColor = isDark ? Colors.white38 : const Color(0xFF9E9E9E);

    final bool needsHighContrast =
        isDark && AppConfig.isDarkColor(AppConfig.primaryColor);
    final Color effectiveActiveColor = needsHighContrast
        ? Colors.white
        : activeColor;
    final Color effectiveActiveTextColor = needsHighContrast
        ? Colors.white
        : activeColor;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (needsHighContrast
                      ? Colors.white.withValues(alpha: 0.15)
                      : activeColor.withValues(alpha: isDark ? 0.2 : 0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive && needsHighContrast
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!needsHighContrast)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: isActive ? 32 : 0,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: effectiveActiveColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(height: 3),
              SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isActive ? effectiveActiveColor : inactiveColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? effectiveActiveTextColor : inactiveColor,
                  letterSpacing: isActive ? 0.3 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
