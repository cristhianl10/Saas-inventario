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

9.1. STOCKFLOW SE PROPORCIONA "TAL COMO ES".

9.2. NO SOMOS RESPONSABLES POR:
• Pérdida de datos por fallos técnicos
• Decisiones tomadas basadas en los reportes
• Interrupciones del servicio

9.3. Nuestra responsabilidad máxima es el monto que haya pagado por el servicio.

10. CAMBIOS A ESTOS TÉRMINOS

Podemos actualizar estos términos ocasionalmente. El uso continuado después de los cambios constituye aceptación.

11. CONTACTO

Para preguntas sobre estos términos, contacte a: tu-email@tu-dominio.com

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
      content: '''
POLÍTICA DE PRIVACIDAD

StockFlow

Última actualización: Abril 2026

1. INTRODUCCIÓN

En StockFlow, respetamos su privacidad y nos comprometemos a proteger sus datos personales.

Esta Política de Privacidad explica cómo recopilamos, usamos, almacenamos y protegemos su información.

2. INFORMACIÓN QUE RECOPILAMOS

2.1. Información que usted proporciona:
• Datos de cuenta: Email y contraseña (encriptada)
• Datos del negocio: Nombre, colores, logo
• Datos de inventario: Productos, categorías, precios
• Datos de ventas: Transacciones, clientes

2.2. Información recopilada automáticamente:
• Datos técnicos: Tipo de dispositivo, sistema operativo
• Datos de uso: Funciones usadas, errores

3. CÓMO USAMOS SU INFORMACIÓN

Usamos su información para:
• Proporcionar el servicio
• Mejorar el servicio
• Comunicaciones relacionadas con su cuenta
• Seguridad

4. COMPARTIR INFORMACIÓN

NO vendemos sus datos personales. Compartimos información únicamente con:
• Proveedores de servicios (hosting, email)
• Por razones legales (si es requerido)

5. ALMACENAMIENTO Y SEGURIDAD

• Datos encriptados en tránsito (HTTPS)
• Contraseñas encriptadas
• Control de acceso (RLS)
• Monitoreo de seguridad

6. SUS DERECHOS

Usted tiene derecho a:
• Acceder a sus datos
• Rectificar datos inexactos
• Eliminar sus datos
• Portabilidad de datos

Para ejercer sus derechos, contacte a: cristhian.loor05@outlook.com

7. COOKIES

Usamos cookies esenciales para:
• Mantener su sesión iniciada
• Recordar preferencias
• Analizar uso de la app

8. NIÑOS

La Aplicación no está diseñada para menores de 18 años.

9. CAMBIOS A ESTA POLÍTICA

Pueden actualizar esta política periódicamente. Cambios significativos serán notificados.

10. CONTACTO

Email: cristhian.loor05@outlook.com

---

*Esta política de privacidad fue actualizada por última vez en Abril 2026.*
''',
    );
  }
}
