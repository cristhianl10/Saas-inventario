import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';
import 'productos_screen.dart';
import 'resumen_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Categoria> _categorias = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  Future<void> _loadCategorias() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final categorias = await _apiService.getCategorias();
      setState(() {
        _categorias = categorias;
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
    final emojiController = TextEditingController(
      text: categoria?.emoji ?? '📦',
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
            const SizedBox(height: 12),
            TextField(
              controller: emojiController,
              decoration: const InputDecoration(
                labelText: 'Emoji',
                border: OutlineInputBorder(),
              ),
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
                emoji: emojiController.text.trim(),
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
      floatingActionButton: _currentIndex == 0
          ? Container(
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
                onPressed: () => _showCategoriaDialog(),
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(
                  Icons.add,
                  color: SubliriumColors.cardBackground,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCategorias() {
    return CustomScrollView(
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
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SubliriumColors.logoCircleBg,
                  border: Border.all(
                    color: SubliriumColors.logoCircleBorder,
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // S
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          SubliriumColors.logoSGradient.createShader(bounds),
                      child: const Text(
                        'S',
                        style: TextStyle(
                          color: SubliriumColors.cardBackground,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // R (aparece a la derecha del S)
                    Positioned(
                      left: 18,
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            SubliriumColors.logoRGradient.createShader(bounds),
                        child: const Text(
                          'R',
                          style: TextStyle(
                            color: SubliriumColors.cardBackground,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: SubliriumColors.cardBackground,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: SubliriumColors.border),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, size: 16, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    'Buscar categoría...',
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Categorías',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${_categorias.length} categorías',
                  style: const TextStyle(
                    color: Colors.black,
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
        else if (_categorias.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 48, color: Colors.black),
                  const SizedBox(height: 8),
                  Text(
                    'No hay categorías',
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toca + para crear una',
                    style: TextStyle(color: Colors.black, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final categoria = _categorias[index];
              return FutureBuilder<int>(
                future: _apiService
                    .getProductosPorCategoria(categoria.id!)
                    .then((p) => p.length),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
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
                            color: _getCategoryColor(categoria.emoji),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              categoria.emoji,
                              style: const TextStyle(fontSize: 18),
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
                },
              );
            }, childCount: _categorias.length),
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
        border: Border(top: BorderSide(color: SubliriumColors.border, width: 1.5)),
      ),
      child: SafeArea(
        child: Row(children: [
          _buildNavItem(0, '🏠', 'Inicio', _currentIndex == 0, () {
            setState(() => _currentIndex = 0);
          }),
          _buildNavItem(1, '📦', 'Productos', _currentIndex == 1, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductosScreen()));
          }),
          _buildNavItem(2, '📊', 'Resumen', _currentIndex == 2, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ResumenScreen()));
          }),
        ]),
      ),
    );
  }

  Widget _buildNavItem(int index, String icon, String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(icon, style: TextStyle(fontSize: 18, color: active ? SubliriumColors.cyan : SubliriumColors.textSecondary)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: active ? SubliriumColors.cyan : SubliriumColors.textSecondary)),
          ]),
        ),
      ),
    );
  }

  Color _getCategoryColor(String emoji) {
    final colors = {
      '☕': const Color(0xFFFFF8F0),
      '🧊': const Color(0xFFF0FBFF),
      '🥤': const Color(0xFFF0FFF8),
      '🚰': const Color(0xFFFFFBF0),
      '👕': const Color(0xFFFDF4FF),
      '🧢': const Color(0xFFF0F8FF),
      '🖱️': const Color(0xFFF5F0FF),
      '🪨': const Color(0xFFF0FFF8),
      '👜': const Color(0xFFFFF8F0),
      '⏰': const Color(0xFFF0F8FF),
      '🖼️': const Color(0xFFFDF4FF),
      '📓': const Color(0xFFFFFBF0),
      '🔑': const Color(0xFFF0FFF8),
      '🪵': const Color(0xFFF5F0FF),
      '🛏️': const Color(0xFFFFF0F8),
    };
    return colors[emoji] ?? SubliriumColors.cardBackground;
  }
}
