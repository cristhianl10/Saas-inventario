# 🔒 STOCKFLOW - GUÍA DE SEGURIDAD COMPLETA

## 📋 ÍNDICE
1. [Nivel de Seguridad Actual](#nivel-actual)
2. [Cómo Aplicar las Políticas](#como-aplicar)
3. [Configuración de Supabase](#configuracion-supabase)
4. [Seguridad en la App](#seguridad-app)
5. [Monitoreo y Alertas](#monitoreo)
6. [Respuesta a Incidentes](#respuesta-incidentes)

---

## 🚨 NIVEL DE SEGURIDAD ACTUAL

Tu sistema StockFlow tiene implementadas:

| Medida | Estado | Prioridad |
|--------|--------|-----------|
| RLS (Row Level Security) | ✅ Implementado | CRÍTICA |
| Autenticación Multi-tenant | ✅ Implementado | CRÍTICA |
| Auditoría de Acciones | ✅ Implementado | ALTA |
| Validación de Inputs | ✅ Implementado | ALTA |
| HTTPS Enforced | ✅ Por defecto | CRÍTICA |
| Rate Limiting | ⚠️ Básico | MEDIA |
| 2FA (Doble Factor) | ❌ Pendiente | ALTA |
| Encriptación de Datos | ⚠️ Parcial | ALTA |
| Backups Automáticos | ⚠️ Configurar | CRÍTICA |
| Alertas de Seguridad | ❌ Pendiente | ALTA |

---

## 🎯 CÓMO APLICAR LAS POLÍTICAS DE SEGURIDAD

### Paso 1: Ejecutar el Script SQL

1. Ve a tu proyecto en [Supabase Dashboard](https://app.supabase.com)
2. Selecciona tu proyecto `hikfwvllbbliwvflqlye`
3. Ve a **SQL Editor**
4. Crea una nueva query
5. Copia y pega todo el contenido de `SEGURIDAD_MAXIMA.sql`
6. Ejecuta el script (botón **RUN**)

### Paso 2: Verificar que RLS está Activo

Después de ejecutar, ejecuta esta consulta para verificar:

```sql
SELECT 
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public'
AND rowsecurity = true;
```

Deberías ver todas tus tablas con `rowsecurity = true`.

### Paso 3: Verificar las Políticas

```sql
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public';
```

Deberías ver políticas como:
- `categorias_select`
- `categorias_insert`
- `categorias_update`
- `categorias_delete`
- Y lo mismo para productos, ventas, etc.

---

## ⚙️ CONFIGURACIÓN DE SUPABASE

### 1. Habilitar Autenticación Segura

Ve a **Authentication** > **Settings** en tu dashboard de Supabase:

```
✅ Enable Sign Up: YES (solo si quieres nuevos registros)
✅ Enable Anonymous Sign-ins: NO ← IMPORTANTE
✅ Enable Auto-confirm: NO ← IMPORTANTE
✅ Enable Confirm Email: YES ← IMPORTANTE
✅ Password minimum length: 8
✅ Site URL: https://tudominio.com (configurar después)
```

### 2. Configurar Rate Limiting

En **Authentication** > **Settings** > **Rate Limits**:

```
Login attempts per email: 5 por minuto
API requests per minute: 60
```

### 3. Habilitar 2FA (Doble Factor)

En **Authentication** > **Providers** > **Authenticator (TOTP)**:

```
Enable TOTP: YES ← IMPORTANTE
```

### 4. Configurar Logs de Auditoría

En **Database** > **Extensions**, asegúrate que `pgcrypto` está habilitado:

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

### 5. Backups Automáticos

En **Database** > **Backups**:

```
✅ Point-in-time recovery: ENABLE
✅ Backup retention: 30 days
✅ Backup schedule: Daily at 02:00 UTC
```

---

## 📱 SEGURIDAD EN LA APP FLUTTER

### Medidas Implementadas

1. **Tokens Seguros**: Los tokens se almacenan en variables seguras de Supabase
2. **Validación de Inputs**: Sanitización de todos los datos de entrada
3. **HTTPS Only**: Todas las comunicaciones son encriptadas
4. **Multi-tenant**: Aislamiento de datos por usuario

### Para Mayor Seguridad, Implementar:

#### 1. Detección de Dispositivos Rooteados

```dart
// En pubspec.yaml, agregar:
dependencies:
  flutter_secure_storage: ^9.0.0
  package_info_plus: ^5.0.0
```

#### 2. Certificate Pinning (Para producción)

En el archivo `lib/main.dart`, agregar validación de certificados.

#### 3. Obscurecer datos sensibles

Nunca guardar datos sensibles en texto plano.

---

## 📊 MONITOREO Y ALERTAS

### Configurar Alertas en Supabase

1. Ve a **Logs** > **Alerts**
2. Crea alertas para:

```
🚨 Alerta 1: Intentos de login fallidos
   - Condition: count > 5 in 10 minutes
   - Action: Notificar por email

🚨 Alerta 2: Acceso desde nueva IP
   - Condition: new ip_address detected
   - Action: Enviar notificación

🚨 Alerta 3: Volumen inusual de queries
   - Condition: requests > 1000 in 5 minutes
   - Action: Revisar actividad
```

### Logs de Auditoría

Para ver los logs de auditoría:

```sql
-- Ver últimos 100 acciones
SELECT * FROM audit_log 
ORDER BY created_at DESC 
LIMIT 100;

-- Ver intentos de login fallidos
SELECT * FROM audit_log 
WHERE action_type = 'LOGIN_FAILED'
ORDER BY created_at DESC;

-- Ver actividad de un usuario específico
SELECT * FROM audit_log 
WHERE user_id = 'TU-USER-UUID'
ORDER BY created_at DESC;
```

---

## 🚨 RESPUESTA A INCIDENTES

### Si Detectas Acceso No Autorizado:

1. **Imediatamente**:
   - Cambia la contraseña del usuario afectado
   - Revoca todas las sesiones activas
   - Revisa los logs de auditoría

2. **Investigar**:
   - Revisa `audit_log` para ver qué se accesó
   - Revisa `failed_login_attempts` para ver intentos
   - Identifica la IP de origen

3. **Mitigar**:
   - Si hay datos comprometidos, notificar usuarios
   - Restaurar desde backup si es necesario
   - Actualizar políticas de seguridad

### Contacto de Emergencia

- **Supabase Support**: support@supabase.io
- **Documentación**: https://supabase.com/docs

---

## 📝 CHECKLIST DE SEGURIDAD

Copia esta lista y marca cada ítem cuando lo completes:

```
BASICO (Requerido):
[ ] Ejecutar script SEGURIDAD_MAXIMA.sql
[ ] Habilitar confirmación de email
[ ] Deshabilitar auto-confirm
[ ] Configurar contraseña mínima de 8 caracteres
[ ] Verificar RLS está activo

INTERMEDIO (Recomendado):
[ ] Habilitar 2FA
[ ] Configurar rate limiting
[ ] Habilitar backups PITR
[ ] Configurar alertas de login
[ ] Revisar logs semanalmente

AVANZADO (Para producción):
[ ] Implementar certificate pinning
[ ] Configurar WAF (Web Application Firewall)
[ ] Implementar CAPTCHA en login
[ ] Configurar notificaciones de seguridad
[ ] Auditoría de seguridad externa
```

---

## 🔐 RECURSOS ADICIONALES

- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **Supabase Security**: https://supabase.com/docs/guides/auth
- **Flutter Security**: https://flutter.dev/docs/security

---

**Última actualización**: Abril 2026
**Versión**: 1.0
**Estado**: En implementación
