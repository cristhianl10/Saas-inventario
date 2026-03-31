# Monetización de Sublirium Inventario

## Lo que ya se implementó

### 1. Sistema Multi-Tenant (Completado)
- Nueva tabla `tenant_config` para guardar configuración de marca por cliente
- Columna `user_id` agregada a todas las tablas (categorias, productos, ventas, tarifa_precios, proveedores)
- Row Level Security (RLS) habilitado para separar datos de cada cliente
- **Tus datos actuales NO se tocan** - están en tu cuenta de Supabase

### 2. Autenticación (Completado)
- Pantalla de login/registro con Supabase Auth
- Cada cliente crea su propia cuenta
- Sesiones persistentes

### 3. Personalización de Marca (Completado)
- Logo configurable por cliente
- Colores personalizables (primario, secundario, acento)
- Nombre del negocio configurable
- Todo guardado en `tenant_config`

## Próximos Pasos

### Paso 1: Ejecutar el SQL de migración
Ejecuta `TENANT_MULTI_SQL.sql` en tu Supabase Dashboard > SQL Editor.

### Paso 2: Configurar Auth en Supabase
1. Ve a Supabase Dashboard > Authentication > Settings
2. Habilita "Enable email confirmations" si quieres verificar emails
3. Configura URLs de redirect si usas web

### Paso 3: Agregar suscripciones (Stripe)
Pendiente - requiere cuenta de Stripe y configuración backend.

---

## Modelos de Monetización

### Modelo SaaS (Recomendado para empezar)
1. Mantienes tu Supabase actual para tus datos
2. Creas UN NUEVO proyecto de Supabase para la versión SaaS
3. Cobras $10-30/mes por usuario/negocio
4. Los clientes se registran en tu app y pagan por Stripe

### Modelo Licencia
1. Los clientes compran licencia perpetua
2. Les das la app compilada con SU propio Supabase
3. Tú das soporte técnico (puedes cobrar extra)
4. Ideal para negocios que quieren control total

---

## Para Probar Localmente

```bash
# Instalar Flutter (si no lo tienes)
# Descargar de https://flutter.dev

cd inventario_app
flutter pub get
flutter run
```

## Para Compilar

```bash
# Android APK
flutter build apk --release

# iOS (solo en Mac)
flutter build ios --release

# Web
flutter build web
```

## Estructura de Archivos Nuevos

```
inventario_app/lib/
├── config/
│   ├── app_config.dart        # Configuración centralizada
│   ├── app_theme.dart        # Tema de colores
│   └── tenant_service.dart   # Servicio multi-tenant
├── screens/
│   ├── auth_screen.dart      # Login/Registro
│   ├── home_screen.dart      # Pantalla principal (actualizada)
│   └── ...
└── utils/
    └── pdf_helper.dart       # PDF helper (actualizado)

inventario_app/
├── TENANT_MULTI_SQL.sql      # Migración de BD
└── ...
```

---

## Tu Base de Datos - PROTEGIDA

| Lo que SÍ pasa | Lo que NO pasa |
|----------------|----------------|
| Se ejecutó SQL de migración en tu Supabase | Tu base de datos se mueve |
| Se agregaron columnas `user_id` | Tu información se comparte |
| Se habilitó RLS | Alguien ve tus productos |

**IMPORTANTE**: Los datos existentes en tus tablas NO tienen `user_id` asignado.
Necesitas actualizar tus registros existentes:

```sql
-- Actualiza tus categorías con tu user_id
-- (reemplaza 'tu-user-id' con tu ID de Supabase)
UPDATE categorias SET user_id = 'tu-user-id' WHERE user_id IS NULL;
UPDATE productos SET user_id = 'tu-user-id' WHERE user_id IS NULL;
UPDATE ventas SET user_id = 'tu-user-id' WHERE user_id IS NULL;
UPDATE tarifa_precios SET user_id = 'tu-user-id' WHERE user_id IS NULL;
UPDATE proveedores SET user_id = 'tu-user-id' WHERE user_id IS NULL;
```
