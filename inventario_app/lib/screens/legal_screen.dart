import 'package:flutter/material.dart';
import '../config/app_config.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
      ),
    );
  }
}

class TerminosYCondiciones extends StatelessWidget {
  const TerminosYCondiciones({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'Términos y Condiciones',
      content: '''
TÉRMINOS Y CONDICIONES

StockFlow

Última actualización: Abril 2026

1. ACEPTACIÓN DE LOS TÉRMINOS

Al descargar, instalar o usar StockFlow ("la Aplicación"), usted ("el Usuario") acepta estar sujeto a estos Términos y Condiciones. Si no está de acuerdo con estos términos, no use la Aplicación.

2. DESCRIPCIÓN DEL SERVICIO

StockFlow es una aplicación de gestión de inventario que permite a los usuarios:
• Gestionar productos e inventario
• Registrar ventas
• Crear combinaciones de productos (Combos)
• Configurar precios por volumen
• Generar reportes en PDF
• Personalizar la apariencia de la app con su marca

3. CUENTA DE USUARIO

3.1. Para usar StockFlow, debe crear una cuenta proporcionando información precisa y completa.

3.2. Usted es responsable de:
• Mantener la confidencialidad de su contraseña
• Todas las actividades realizadas con su cuenta
• Notificarnos inmediatamente sobre cualquier uso no autorizado

3.3. Debe tener al menos 18 años para usar esta Aplicación.

4. SUSCRIPCIONES Y PAGOS

4.1. StockFlow ofrece planes de suscripción de pago.

4.2. Los precios se muestran en la aplicación y pueden cambiar ocasionalmente.

4.3. La suscripción se renueva automáticamente a menos que la cancele.

4.4. Puede cancelar su suscripción en cualquier momento desde la configuración de la cuenta.

5. PRUEBA GRATUITA

5.1. Podemos ofrecer períodos de prueba gratuita.

5.2. Si cancela durante la prueba, no se le cobrará.

6. SUSPENSIÓN Y CIERRE DE CUENTA

6.1. Puede cerrar su cuenta en cualquier momento usando la función "Desactivar cuenta" en la configuración.

6.2. Al desactivar su cuenta:
• Sus datos se conservarán por un período razonable
• No podrá acceder a su cuenta

6.3. Podemos suspender o cerrar cuentas que violen estos términos.

7. USO ACEPTABLE

7.1. Usted acepta NO:
• Usar la app para fines ilegales
• Intentar acceder a cuentas de otros usuarios
• Realizar ingeniería inversa del software
• Distribuir virus o malware
• Spamear o enviar contenido no solicitado

8. PROPIEDAD INTELECTUAL

8.1. StockFlow y todo su contenido están protegidos por derechos de autor.

8.2. No puede copiar, modificar o distribuir nuestro contenido sin permiso.

8.3. Los datos que usted ingresa siguen siendo de su propiedad.

  9. LIMITACIÓN DE RESPONSABILIDAD

  9.1. NO SOMOS RESPONSABLES POR:
  • Pérdida de datos por fallos técnicos
  • Decisiones tomadas basadas en los reportes
  • Interrupciones del servicio

  9.2. Nuestra responsabilidad máxima es el monto que haya pagado por el servicio.

  10. CAMBIOS A ESTOS TÉRMINOS

  Podemos actualizar estos términos ocasionalmente. El uso continuado después de los cambios constituye aceptación.

  11. CONTACTO

  Para preguntas sobre estos términos, contacte a: cristhian.loor05@outlook.com

---

Al usar StockFlow, usted reconoce haber leído y aceptado estos Términos y Condiciones.
''',
    );
  }
}

class PoliticaDePrivacidad extends StatelessWidget {
  const PoliticaDePrivacidad({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'Política de Privacidad',
      content: '''STOCKFLOW
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
''',
    );
  }
}
