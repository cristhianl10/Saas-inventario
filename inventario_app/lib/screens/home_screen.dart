import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';
import 'productos_screen.dart';
import 'resumen_screen.dart';
import 'tabla_precios_screen.dart';
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
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Categoría eliminada')));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
              if (nombre.isEmpty) return;
              final nuevaCategoria = Categoria(
                id: categoria?.id,
                nombre: nombre,
              );
              try {
                if (isEditing) {
                  await _apiService.updateCategoria(nuevaCategoria);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categoría actualizada con éxito'), backgroundColor: SubliriumColors.stockOkText));
                } else {
                  await _apiService.createCategoria(nuevaCategoria);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categoría creada con éxito'), backgroundColor: SubliriumColors.stockOkText));
                }
                _loadCategorias();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showScrollToTop) ...[
            FloatingActionButton.small(
              heroTag: 'scroll_to_top_home_btn',
              onPressed: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
              backgroundColor: SubliriumColors.cyan.withValues(alpha: 0.8),
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            ),
            const SizedBox(height: 12),
          ],
          if (_currentIndex == 0)
            Container(
              decoration: BoxDecoration(
                gradient: SubliriumColors.fabGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: SubliriumColors.magenta.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'add_cat_home_btn',
                onPressed: () => _showCategoriaDialog(),
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(
                  Icons.add,
                  color: SubliriumColors.cardBackground,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorias() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          expandedHeight: 100,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              'Inventario Sublirium',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: SubliriumColors.headerGradient,
              ),
            ),
          ),
          actions: [
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
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SubliriumColors.cardBackground,
                  border: Border.all(
                    color: SubliriumColors.cyan,
                    width: 2,
                  ),
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
                    'assets/logos/logo sublirium.jpeg',
                    fit: BoxFit.cover,
                    width: 36,
                    height: 36,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.store,
                        color: SubliriumColors.cyan,
                        size: 20,
                      );
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
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 16,
                  color: Colors.black,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: SubliriumColors.cardBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: SubliriumColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: SubliriumColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(
                    color: SubliriumColors.cyan,
                    width: 2,
                  ),
                ),
              ),
              style: const TextStyle(fontSize: 12, color: Colors.black),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                Text(
                  '${_categoriasFiltradas.length} categorías',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.black),
                  const SizedBox(height: 8),
                  Text(
                    'Error de conexión',
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadCategorias,
                    child: const Text('Reintentar'),
                  ),
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
                  Icon(
                    _searchQuery.isEmpty ? Icons.folder_open : Icons.search_off,
                    size: 48,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No hay categorías'
                        : 'No se encontraron categorías',
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Toca + para crear una'
                        : 'Intenta con otro término de búsqueda',
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final categoria = _categoriasFiltradas[index];
              final count = _productosCount[categoria.id] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: SubliriumColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: SubliriumColors.cyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.folder,
                          size: 18,
                          color: SubliriumColors.cyan,
                        ),
                      ),
                    ),
                    title: Text(
                      categoria.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '$count productos',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: () => _showCategoriaDialog(categoria),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                size: 16,
                                color: Colors.red[300],
                              ),
                              onPressed: () => _deleteCategoria(categoria),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.black,
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductosScreen(categoria: categoria),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }, childCount: _categoriasFiltradas.length),
              ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildOtros() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _currentIndex == 1 ? Icons.inventory_2 : Icons.analytics,
            size: 64,
            color: Colors.black,
          ),
          const SizedBox(height: 16),
          Text(
            _currentIndex == 1 ? 'Productos' : 'Resumen',
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: SubliriumColors.cardBackground,
        border: Border(
          top: BorderSide(color: SubliriumColors.border, width: 1.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildNavItem(0, '🏠', 'Inicio', _currentIndex == 0, () {
              setState(() => _currentIndex = 0);
            }),
            _buildNavItem(1, '📦', 'Productos', _currentIndex == 1, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductosScreen()),
              );
            }),
            _buildNavItem(2, '📊', 'Resumen', _currentIndex == 2, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ResumenScreen()),
              );
            }),
            _buildNavItem(3, '💰', 'Precios', _currentIndex == 3, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TablaPreciosScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String icon,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: active
              ? BoxDecoration(
                  color: SubliriumColors.navActiveGreenLight,
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                icon,
                style: TextStyle(
                  fontSize: 18,
                  color: active ? SubliriumColors.navActiveGreen : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: active ? SubliriumColors.navActiveGreen : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
