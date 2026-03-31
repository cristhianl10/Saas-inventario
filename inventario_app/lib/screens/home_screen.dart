import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import 'productos_screen.dart';
import 'resumen_screen.dart';
import 'tabla_precios_screen.dart';
import 'configuracion_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
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

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Categoria> get _categoriasFiltradas {
    if (_searchQuery.isEmpty) {
      return _categorias;
    }
    return _categorias.where((categoria) {
      return categoria.nombre.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _loadCategorias() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final categorias = await _apiService.getCategorias();
      final counts = await _apiService.getProductosCountPorCategoria();
      setState(() {
        _categorias = categorias;
        _productosCount = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCategoria(Categoria categoria) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar categoría?'),
        content: Text('Se eliminarán todos los productos en "${categoria.nombre}".'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categoría eliminada')),
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

  void _showCategoriaDialog([Categoria? categoria]) {
    final nombreController = TextEditingController(text: categoria?.nombre ?? '');
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
              final existe = _categorias.any((c) =>
                c.nombre.toLowerCase() == nombre.toLowerCase() &&
                c.id != categoria?.id
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
              final nuevaCategoria = Categoria(id: categoria?.id, nombre: nombre);
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
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
    return Scaffold(
      body: _currentIndex == 0 ? _buildCategorias() : _buildOtros(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    if (_currentIndex != 0) return null;
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppConfig.secondaryColor, AppConfig.primaryColor, AppConfig.accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
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
                    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                  },
                );
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) async {
                if (value == 'config') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfiguracionScreen()));
                } else if (value == 'logout') {
                  await Supabase.instance.client.auth.signOut();
                }
              },
              itemBuilder: (context) => [
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
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SubliriumColors.cardBackground,
                  border: Border.all(color: SubliriumColors.cyan, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    AppConfig.logoPath,
                    fit: BoxFit.cover,
                    width: 36,
                    height: 36,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.store, color: SubliriumColors.cyan, size: 20);
                    },
                  ),
                ),
              ),
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
                hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey),
                prefixIcon: Icon(Icons.search, size: 16, color: textColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 16, color: textColor),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: bgColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: AppConfig.primaryColor, width: 2),
                ),
              ),
              style: TextStyle(fontSize: 12, color: textColor),
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
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: textColor),
                ),
                Text(
                  '${_categoriasFiltradas.length} categorías',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 48, color: textColor),
                  const SizedBox(height: 8),
                  Text('Error de conexión', style: TextStyle(color: textColor)),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _loadCategorias, child: const Text('Reintentar')),
                ],
              ),
            ),
          )
        else if (_categoriasFiltradas.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_searchQuery.isEmpty ? Icons.folder_open : Icons.search_off, size: 48, color: textColor),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isEmpty ? 'No hay categorías' : 'No se encontraron categorías',
                    style: TextStyle(color: textColor),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Toca + para crear una', style: TextStyle(fontSize: 12, color: textColor)),
                  ],
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final categoria = _categoriasFiltradas[index];
                final count = _productosCount[categoria.id] ?? 0;
                return _buildCategoriaItem(categoria, count);
              },
              childCount: _categoriasFiltradas.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildCategoriaItem(Categoria categoria, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : SubliriumColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey[700]! : SubliriumColors.border),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SubliriumColors.cyan.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(child: Icon(Icons.folder, size: 18, color: SubliriumColors.cyan)),
          ),
          title: Text(categoria.nombre, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: textColor)),
          subtitle: Text('$count productos', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor.withValues(alpha: 0.7))),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: Icon(Icons.edit, size: 16, color: textColor), onPressed: () => _showCategoriaDialog(categoria)),
              IconButton(icon: Icon(Icons.delete, size: 16, color: Colors.red[300]), onPressed: () => _deleteCategoria(categoria)),
              Icon(Icons.chevron_right, color: textColor),
            ],
          ),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProductosScreen(categoria: categoria)));
          },
        ),
      ),
    );
  }

  Widget _buildOtros() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_currentIndex == 1 ? Icons.inventory_2 : Icons.analytics, size: 64),
          const SizedBox(height: 16),
          Text(_currentIndex == 1 ? 'Productos' : 'Resumen'),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: SubliriumColors.cardBackground,
        border: Border(top: BorderSide(color: SubliriumColors.border, width: 1.5)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildNavItem(0, '🏠', 'Inicio', _currentIndex == 0, () => setState(() => _currentIndex = 0)),
            _buildNavItem(1, '📦', 'Productos', false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductosScreen()))),
            _buildNavItem(2, '📊', 'Resumen', false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResumenScreen()))),
            _buildNavItem(3, '💰', 'Precios', false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TablaPreciosScreen()))),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String icon, String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: active
              ? BoxDecoration(color: SubliriumColors.navActiveGreenLight, borderRadius: BorderRadius.circular(12))
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: TextStyle(fontSize: 18, color: active ? SubliriumColors.navActiveGreen : Colors.black)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: active ? SubliriumColors.navActiveGreen : Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
