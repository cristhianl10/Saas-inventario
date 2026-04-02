import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'auth_screen.dart';

class TermsAcceptanceScreen extends StatefulWidget {
  const TermsAcceptanceScreen({super.key});

  @override
  State<TermsAcceptanceScreen> createState() => _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends State<TermsAcceptanceScreen> {
  bool _hasAccepted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAcceptance();
  }

  Future<void> _checkAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('terms_accepted') ?? false;
    setState(() {
      _hasAccepted = accepted;
      _isLoading = false;
    });
  }

  Future<void> _acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', true);
    await prefs.setString(
      'terms_accepted_date',
      DateTime.now().toIso8601String(),
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              AuthScreen(onAuthSuccess: () {}, onEmailVerified: (_) {}),
        ),
      );
    }
  }

  void _showTermsDialog(bool isPrivacy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isPrivacy ? 'Política de Privacidad' : 'Términos y Condiciones',
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              isPrivacy ? _privacyPolicyText : _termsText,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  static const String _termsText = '''
TÉRMINOS Y CONDICIONES - StockFlow

1. ACEPTACIÓN
Al descargar, instalar o usar StockFlow, aceptas estos términos.

2. DESCRIPCIÓN DEL SERVICIO
StockFlow permite gestionar inventario, registrar ventas, crear combos y generar reportes PDF.

3. CUENTA DE USUARIO
Debes proporcionar información precisa y mantener tu contraseña segura.

4. SUSCRIPCIONES Y PAGOS
Los precios se muestran en la app. La suscripción se renueva automáticamente.

5. CIERRE DE CUENTA
Puedes desactivar tu cuenta en cualquier momento desde la configuración.

6. USO ACEPTABLE
No uses la app para fines ilegales o no autorizados.

7. PROPIEDAD INTELECTUAL
StockFlow está protegido por derechos de autor.

8. LIMITACIÓN DE RESPONSABILIDAD
La app se proporciona "tal cual".

9. CONTACTO
cristhian.loor05@outlook.com
''';

  static const String _privacyPolicyText = '''
POLÍTICA DE PRIVACIDAD - StockFlow

1. INFORMACIÓN QUE RECOPILAMOS
- Datos de cuenta (email, contraseña)
- Datos del negocio (productos, ventas)
- Datos técnicos (dispositivo, versión)

2. CÓMO USAMOS SU INFORMACIÓN
- Proporcionar el servicio
- Mejorar la app
- Seguridad

3. COMPARTIR INFORMACIÓN
Compartimos datos únicamente con proveedores de servicios (hosting, email) y por razones legales si es requerido.

4. ALMACENAMIENTO Y SEGURIDAD
Tus datos están encriptados y protegidos con políticas de control de acceso.

5. SUS DERECHOS
Puedes acceder, rectificar o eliminar tus datos en cualquier momento.

6. CONTACTO
cristhian.loor05@outlook.com
''';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppConfig.primaryColor),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              Icon(
                Icons.handshake_outlined,
                size: 80,
                color: AppConfig.primaryColor,
              ),

              const SizedBox(height: 24),

              Text(
                'Bienvenido a StockFlow',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'Para continuar, acepta nuestros términos.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showTermsDialog(false),
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('Términos'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showTermsDialog(true),
                      icon: const Icon(Icons.privacy_tip_outlined),
                      label: const Text('Privacidad'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Checkbox(
                    value: _hasAccepted,
                    onChanged: (value) {
                      setState(() {
                        _hasAccepted = value ?? false;
                      });
                    },
                    activeColor: AppConfig.primaryColor,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _hasAccepted = !_hasAccepted;
                        });
                      },
                      child: const Text(
                        'He leído y acepto los términos y condiciones y la política de privacidad',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasAccepted ? _acceptTerms : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasAccepted
                        ? AppConfig.primaryColor
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
