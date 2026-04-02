import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../config/tenant_service.dart';
import '../services/user_status_service.dart';
import '../utils/dialog_utils.dart';
import '../screens/auth_screen.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appNameController = TextEditingController();
  final _brandNameController = TextEditingController();
  
  String _primaryColor = '#C1356F';
  String _secondaryColor = '#597FA9';
  String _accentColor = '#E57836';
  String _backgroundColor = '#FBF8F1';
  
  bool _isLoading = true;
  bool _isSaving = false;

  final List<Map<String, String>> _colorPresets = [
    {'primary': '#C1356F', 'secondary': '#597FA9', 'accent': '#E57836', 'name': 'Rosa/Púrpura'},
    {'primary': '#2563EB', 'secondary': '#3B82F6', 'accent': '#F59E0B', 'name': 'Azul/Naranja'},
    {'primary': '#059669', 'secondary': '#10B981', 'accent': '#FCD34D', 'name': 'Verde/Amarillo'},
    {'primary': '#7C3AED', 'secondary': '#8B5CF6', 'accent': '#EC4899', 'name': 'Violeta/Rosa'},
    {'primary': '#DC2626', 'secondary': '#EF4444', 'accent': '#FCD34D', 'name': 'Rojo/Amarillo'},
    {'primary': '#0F172A', 'secondary': '#1E293B', 'accent': '#F97316', 'name': 'Gris Oscuro/Naranja'},
  ];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await TenantService.loadTenantConfig(user.id);
      }
      
      setState(() {
        _appNameController.text = AppConfig.appName;
        _brandNameController.text = AppConfig.brandName;
        _primaryColor = AppConfig.primaryColorHex;
        _secondaryColor = AppConfig.secondaryColorHex;
        _accentColor = AppConfig.accentColorHex;
        _backgroundColor = AppConfig.backgroundColorHex;
      });
    } catch (e) {
      // Si hay error, usar valores por defecto
      setState(() {
        _appNameController.text = 'StockFlow';
        _brandNameController.text = 'Mi Negocio';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    final config = {
      'app_name': _appNameController.text.trim(),
      'brand_name': _brandNameController.text.trim(),
      'logo_path': AppConfig.logoPath,
      'primary_color': _primaryColor,
      'secondary_color': _secondaryColor,
      'accent_color': _accentColor,
      'background_color': _backgroundColor,
    };

    await TenantService.saveTenantConfig(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }

    setState(() => _isSaving = false);
  }

  void _applyPreset(Map<String, String> preset) {
    setState(() {
      _primaryColor = preset['primary']!;
      _secondaryColor = preset['secondary']!;
      _accentColor = preset['accent']!;
    });
  }

  Widget _colorPicker(String label, String currentColor, Function(String) onColorChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showColorPickerDialog(currentColor, onColorChanged),
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: _hexToColor(currentColor),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Text(
                currentColor,
                style: TextStyle(
                  color: _hexToColor(currentColor).computeLuminance() > 0.5 
                      ? Colors.black 
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPickerDialog(String currentColor, Function(String) onColorChanged) {
    final controller = TextEditingController(text: currentColor);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Color Hex'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Código hex',
                hintText: '#FF0000',
                prefixText: '#',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                '#FF0000', '#00FF00', '#0000FF', '#FFFF00',
                '#FF00FF', '#00FFFF', '#FFA500', '#800080',
                '#C1356F', '#597FA9', '#E57836', '#F9C706',
              ].map((color) => GestureDetector(
                onTap: () {
                  controller.text = color;
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _hexToColor(color),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              String color = controller.text.trim();
              if (!color.startsWith('#')) color = '#$color';
              onColorChanged(color.toUpperCase());
              Navigator.pop(context);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuración'),
          backgroundColor: _hexToColor(_primaryColor),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: _hexToColor(_primaryColor),
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveConfig,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información del Negocio'),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _appNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la App',
                  hintText: 'Ej: StockFlow',
                  prefixIcon: Icon(Icons.apps),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _brandNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de tu Negocio',
                  hintText: 'Ej: Mi Tienda',
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre del negocio es obligatorio';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Colores de Marca'),
              const SizedBox(height: 16),
              
              const Text(
                'Preajustes',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorPresets.map((preset) {
                  return GestureDetector(
                    onTap: () => _applyPreset(preset),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _hexToColor(preset['primary']!),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(preset['name']!),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              _colorPicker('Color Primario', _primaryColor, (color) {
                setState(() => _primaryColor = color);
              }),
              const SizedBox(height: 16),
              
              _colorPicker('Color Secundario', _secondaryColor, (color) {
                setState(() => _secondaryColor = color);
              }),
              const SizedBox(height: 16),
              
              _colorPicker('Color Acento', _accentColor, (color) {
                setState(() => _accentColor = color);
              }),
              const SizedBox(height: 16),
              
              _colorPicker('Color de Fondo', _backgroundColor, (color) {
                setState(() => _backgroundColor = color);
              }),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Vista Previa'),
              const SizedBox(height: 16),
              _buildPreview(),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveConfig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hexToColor(_primaryColor),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Guardar Configuración',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Sección de gestión de cuenta
              _buildSectionTitle('Cuenta de Usuario'),
              const SizedBox(height: 16),
              
              Card(
                color: Colors.red[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Zona de Peligro',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Al desactivar tu cuenta, no podrás iniciar sesión hasta que sea reactivada por un administrador. Tus datos no se eliminarán.',
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showDeactivateAccountDialog,
                          icon: const Icon(Icons.block),
                          label: const Text('Desactivar Mi Cuenta'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _hexToColor(_backgroundColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _hexToColor(_secondaryColor),
                  _hexToColor(_primaryColor),
                  _hexToColor(_accentColor),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _appNameController.text.isEmpty ? 'StockFlow' : _appNameController.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Text(
                  _brandNameController.text.isEmpty ? 'Mi Negocio' : _brandNameController.text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _hexToColor(_primaryColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPreviewButton('Aceptar', _hexToColor(_primaryColor)),
                    const SizedBox(width: 8),
                    _buildPreviewButton('Cancelar', Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewButton(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _brandNameController.dispose();
    super.dispose();
  }

  void _showDeactivateAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(Icons.block, color: Colors.red, size: 48),
        title: const Text(
          '¿Desactivar tu cuenta?',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Esta acción cerrará tu sesión y no podrás volver a iniciar sesión hasta que un administrador reactive tu cuenta.\n\n¿Estás seguro?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deactivateAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, desactivar'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  Future<void> _deactivateAccount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await UserStatusService.deactivateAccount(user.id);
      await Supabase.instance.client.auth.signOut();
      
      if (mounted) {
        await showMessageDialog(
          context: context,
          title: 'Cuenta Desactivada',
          message: 'Tu cuenta ha sido desactivada. Contacta al administrador si deseas reactivarla.',
          type: MessageType.warning,
        );
        
        // Navegar a pantalla de login
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
        await showMessageDialog(
          context: context,
          title: 'Error',
          message: 'No se pudo desactivar la cuenta: $e',
          type: MessageType.error,
        );
      }
    }
  }
}
