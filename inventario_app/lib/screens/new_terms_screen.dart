import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/terms_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewTermsScreen extends StatefulWidget {
  final VoidCallback onAccepted;

  const NewTermsScreen({super.key, required this.onAccepted});

  @override
  State<NewTermsScreen> createState() => _NewTermsScreenState();
}

class _NewTermsScreenState extends State<NewTermsScreen> {
  bool _hasAccepted = false;
  bool _isLoading = true;
  bool _isSaving = false;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkAcceptance();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  Future<void> _checkAcceptance() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final acceptedVersion = await TermsService.getAcceptedVersion(userId);
      setState(() {
        _hasAccepted = acceptedVersion == TermsService.currentVersion;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptTerms() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await TermsService.acceptTerms(userId);
      widget.onAccepted();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  static const String _fullLegalText = '''STOCKFLOW
Política de Privacidad
Última actualización: Abril 2026

Resumen de puntos clave
- No vendemos sus datos personales a terceros bajo ninguna circunstancia.
- Sus datos de inventario y negocio son exclusivamente suyos.
- Puede solicitar eliminación completa de sus datos en cualquier momento.
- Toda la comunicación está cifrada con TLS/HTTPS.

1. Introducción

StockFlow es una aplicación de gestión de inventario diseñada para pequeños negocios y emprendimientos. Respetamos su privacidad y nos comprometemos a proteger sus datos personales con las más altas medidas de seguridad.

Esta Política de Privacidad describe de forma transparente cómo recopilamos, usamos, almacenamos y protegemos su información cuando utiliza nuestra aplicación móvil y servicios relacionados.

Al registrarse y utilizar StockFlow, usted acepta las prácticas descritas en este documento. Si tiene dudas, puede contactarnos antes de continuar.

2. Información que Recopilamos

2.1. Información que usted proporciona directamente
- Datos de cuenta: dirección de correo electrónico y contraseña (almacenada con hash bcrypt, nunca en texto plano).
- Datos del negocio: nombre comercial, colores de marca, logotipo.
- Datos de inventario: productos, categorías, precios de compra y venta, niveles de stock.
- Datos de ventas: transacciones, fechas, montos, información opcional de clientes.

2.2. Información recopilada automáticamente
- Datos técnicos del dispositivo: tipo de dispositivo, sistema operativo y versión, identificadores anónimos de sesión.
- Datos de uso: funcionalidades utilizadas, frecuencia de acceso, errores y crashlogs (sin datos de negocio asociados).
- Metadatos de red: dirección IP, zona horaria (para sincronización de datos).

2.3. Información que NO recopilamos
- No accedemos a su micrófono, cámara ni galería sin su consentimiento explícito.
- No recopilamos datos de ubicación GPS.
- No rastreamos su actividad fuera de la aplicación.

3. Cómo Usamos su Información

- Servicio: Proveer, mantener y mejorar las funcionalidades de StockFlow, incluyendo sincronización de datos entre dispositivos.
- Soporte: Responder a sus consultas, resolver problemas técnicos y notificarle sobre actualizaciones importantes de la app.
- Seguridad: Detectar, prevenir y responder a fraudes, abusos o accesos no autorizados a su cuenta.
- Mejoras: Analizar patrones de uso de forma agregada y anónima para desarrollar nuevas funcionalidades.
- Legal: Cumplir con obligaciones legales aplicables en Ecuador y normativas internacionales de protección de datos.

4. Compartir Información con Terceros

StockFlow NO vende, alquila ni comercializa sus datos personales. Compartimos información únicamente en los siguientes casos limitados:

- Proveedores de infraestructura: Supabase (base de datos y autenticación), con contratos de protección de datos (DPA).
- Servicios de email transaccional: para notificaciones de cuenta (confirmación de registro, restablecimiento de contraseña).
- Obligaciones legales: cuando así lo requiera una orden judicial o autoridad competente ecuatoriana, previa verificación de legitimidad.
- Con su consentimiento explícito: en cualquier otro caso no contemplado, le solicitaremos permiso expreso.

5. Almacenamiento y Seguridad

Sus datos se almacenan en servidores seguros gestionados por Supabase. Las medidas de seguridad implementadas incluyen:

- Cifrado en tránsito: toda comunicación entre la app y el servidor usa TLS 1.2+ (HTTPS).
- Cifrado en reposo: los datos sensibles están cifrados en la base de datos.
- Contraseñas: almacenadas únicamente con hash criptográfico (bcrypt). Nunca en texto plano.
- Control de acceso por filas (RLS): cada usuario solo puede acceder a sus propios datos, impuesto a nivel de base de datos.
- Autenticación segura: sesiones con tokens JWT de corta duración y renovación automática.
- Monitoreo continuo: registro de eventos de acceso y alertas automáticas ante comportamientos anómalos.

En caso de detectar una brecha de seguridad que afecte sus datos, le notificaremos dentro de las 72 horas siguientes al descubrimiento.

6. Sus Derechos sobre sus Datos

- Acceso: solicitar una copia completa de los datos que tenemos sobre usted.
- Rectificación: corregir datos incorrectos o desactualizados directamente desde la app o por email.
- Eliminación: solicitar la eliminación permanente de su cuenta y todos sus datos asociados (máximo 30 días).
- Portabilidad: recibir sus datos en formato estructurado (JSON/CSV) para exportarlos a otro servicio.
- Oposición: oponerse al uso de sus datos para ciertos fines, como análisis de uso.
- Limitación: solicitar que restrinjamos el procesamiento de sus datos mientras se resuelve una disputa.

Para ejercer cualquiera de estos derechos: cristhian.loor05@outlook.com — respondemos en máximo 5 días hábiles.

7. Retención de Datos

- Datos de cuenta y negocio: se conservan mientras la cuenta esté activa y hasta 30 días después de una solicitud de eliminación.
- Datos de uso y logs técnicos: se eliminan automáticamente tras 90 días.
- Copias de seguridad: se conservan hasta 30 días adicionales por razones de continuidad del servicio.

8. Cookies y Tecnologías Similares

StockFlow utiliza almacenamiento local en el dispositivo para:

- Mantener su sesión iniciada de forma segura (tokens de autenticación cifrados).
- Recordar sus preferencias de interfaz (tema, idioma, configuración).
- Analizar patrones de uso de la app de forma anónima y agregada.

No utilizamos cookies de rastreo publicitario ni compartimos datos de uso con plataformas de publicidad.

9. Transferencias Internacionales de Datos

Sus datos pueden ser procesados en servidores ubicados fuera de Ecuador (principalmente en Estados Unidos), donde opera la infraestructura de Supabase. Nos aseguramos de que dichas transferencias estén protegidas mediante:

- Cláusulas contractuales estándar de protección de datos (DPA) con nuestros proveedores.
- Servidores certificados bajo marcos de seguridad reconocidos internacionalmente (SOC 2, ISO 27001).

10. Cambios a Esta Política

Podemos actualizar esta Política de Privacidad periódicamente para reflejar cambios en nuestra app o en la legislación aplicable. La fecha de la última actualización se indica siempre al inicio del documento. Le recomendamos revisarla periódicamente.

11. Legislación Aplicable

Esta Política de Privacidad se rige por la legislación vigente de la República del Ecuador, incluyendo la Ley Orgánica de Protección de Datos Personales (LOPDP) y sus reglamentos.

12. Contacto

Aplicación: StockFlow
Desarrollador: Cristhian Loor
Email: cristhian.loor05@outlook.com
Respuesta: Máximo 5 días hábiles

Este documento fue actualizado por última vez el 1 de Abril de 2026.
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.update, size: 48, color: AppConfig.primaryColor),
                  const SizedBox(height: 8),
                  Text(
                    'Términos Actualizados',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hemos actualizado nuestra Política de Privacidad. Por favor lee los cambios para continuar.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _hasScrolledToBottom
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _hasScrolledToBottom
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasScrolledToBottom
                        ? Icons.check_circle
                        : Icons.warning_amber,
                    size: 20,
                    color: _hasScrolledToBottom
                        ? Colors.green
                        : Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _hasScrolledToBottom
                          ? '✓ Documento leído completamente'
                          : 'Debes leer todo el documento para continuar',
                      style: TextStyle(
                        fontSize: 13,
                        color: _hasScrolledToBottom
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _fullLegalText,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _hasScrolledToBottom && _hasAccepted,
                        onChanged: _hasScrolledToBottom
                            ? (value) {
                                setState(() {
                                  _hasAccepted = value ?? false;
                                });
                              }
                            : null,
                        activeColor: AppConfig.primaryColor,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _hasScrolledToBottom
                              ? () {
                                  setState(() {
                                    _hasAccepted = !_hasAccepted;
                                  });
                                }
                              : null,
                          child: Text(
                            'He leído y acepto la Política de Privacidad',
                            style: TextStyle(
                              fontSize: 14,
                              color: _hasScrolledToBottom
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_hasScrolledToBottom && _hasAccepted && !_isSaving)
                          ? _acceptTerms
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (_hasScrolledToBottom && _hasAccepted && !_isSaving)
                            ? AppConfig.primaryColor
                            : Colors.grey[300],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Aceptar y Continuar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
