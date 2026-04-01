import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const AuthScreen({super.key, required this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (_isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        widget.onAuthSuccess();
      } else {
        await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {
            'brand_name': _businessNameController.text.trim().isEmpty
                ? 'Mi Negocio'
                : _businessNameController.text.trim(),
          },
        );

        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await _createTenantConfig(user.id);
          widget.onAuthSuccess();
        } else {
          setState(() {
            _successMessage =
                '✓ Cuenta creada. Revisa tu correo y confirma tu cuenta para iniciar sesión.';
          });
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _mapAuthError(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = _mapConnectionError(e);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('email rate limit exceeded')) {
      return 'Demasiados intentos. Espera unos minutos.';
    }

    if (msg.contains('user already registered')) {
      return 'Este correo ya está registrado.';
    }

    if (msg.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }

    if (msg.contains('email not confirmed')) {
      return 'Confirma tu correo para iniciar sesión.';
    }

    return e.message;
  }

  String _mapConnectionError(dynamic e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('timeout') ||
        msg.contains('internet')) {
      return 'No se puede conectar al servidor. Verifica tu conexión a internet.';
    }

    if (msg.contains('host') ||
        msg.contains('dns') ||
        msg.contains('resolve')) {
      return 'No se encontró el servidor. Intenta más tarde.';
    }

    if (msg.contains('ssl') || msg.contains('certificate')) {
      return 'Error de seguridad. Intenta más tarde.';
    }

    return 'Error de conexión. Verifica tu internet e intenta nuevamente.';
  }

  Future<void> _createTenantConfig(String userId) async {
    final brandName = _businessNameController.text.trim().isEmpty
        ? 'Mi Negocio'
        : _businessNameController.text.trim();

    final config = {
      'app_name': 'StockFlow',
      'brand_name': brandName,
      'logo_path': 'assets/logos/logo_default.png',
      'primary_color': '#C1356F',
      'secondary_color': '#597FA9',
      'accent_color': '#E57836',
      'background_color': '#FBF8F1',
    };

    try {
      await Supabase.instance.client.from('tenant_config').insert({
        'user_id': userId,
        'config': config,
      });
    } catch (e) {
      debugPrint('Error creando tenant_config: $e');
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();
    bool isResetLoading = false;
    String? resetMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Colors.grey),
              SizedBox(width: 8),
              Text('Recuperar contraseña'),
            ],
          ),
          content: Form(
            key: resetFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: resetEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu correo';
                    }
                    if (!value.contains('@')) {
                      return 'Correo inválido';
                    }
                    return null;
                  },
                ),
                if (resetMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: resetMessage!.contains('revis')
                          ? Colors.green[50]
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      resetMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: resetMessage!.contains('revis')
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isResetLoading
                  ? null
                  : () async {
                      if (!resetFormKey.currentState!.validate()) return;

                      setDialogState(() {
                        isResetLoading = true;
                        resetMessage = null;
                      });

                      try {
                        await Supabase.instance.client.auth
                            .resetPasswordForEmail(
                              resetEmailController.text.trim(),
                            );

                        setDialogState(() {
                          resetMessage =
                              '✓ Revisa tu correo para restablecer la contraseña.';
                        });
                      } on AuthException catch (e) {
                        setDialogState(() {
                          if (e.message.toLowerCase().contains(
                            'user not found',
                          )) {
                            resetMessage =
                                'No existe una cuenta con ese correo.';
                          } else {
                            resetMessage = e.message;
                          }
                        });
                      } catch (e) {
                        setDialogState(() {
                          resetMessage = 'Error. Verifica tu conexión.';
                        });
                      } finally {
                        setDialogState(() {
                          isResetLoading = false;
                        });
                      }
                    },
              child: isResetLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor, // Uses designated brand background
      body: Stack(
        children: [
          // Background blobs for Glassmorphism
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConfig.primaryColor.withValues(
                  alpha: isDark ? 0.3 : 0.15,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConfig.secondaryColor.withValues(
                  alpha: isDark ? 0.3 : 0.15,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey[900]!.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 100,
                          ), // center manually via margin or parent constraints
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF597FA9), Color(0xFFC1356F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFC1356F,
                                ).withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppConfig.appName,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin
                              ? 'Inicia sesión para continuar'
                              : 'Crea tu cuenta gratis',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _businessNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de tu negocio',
                              prefixIcon: Icon(Icons.store_outlined, size: 20),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                        ],

                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu correo';
                            }
                            if (!value.contains('@')) {
                              return 'Correo inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(
                              Icons.lock_outlined,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            if (!_isLogin && value.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),

                        if (_isLogin) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF597FA9),
                              ),
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                          ),
                        ],

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red[100]!),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        if (_successMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Text(
                              _successMessage!,
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFC1356F), Color(0xFF597FA9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFC1356F,
                                ).withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isLogin
                                        ? 'Iniciar Sesión'
                                        : 'Crear Cuenta',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = null;
                              _successMessage = null;
                              _obscurePassword = true;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.grey[800],
                          ),
                          child: Text(
                            _isLogin
                                ? '¿No tienes cuenta? Regístrate gratis'
                                : '¿Ya tienes cuenta? Inicia sesión',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
