# Inventario App - Versión Comercial

## Resumen

App de inventario multi-tenant lista para vender. Cada cliente tiene:
- Sus propios datos (separados por user_id)
- Su propia configuración de marca (logo, colores, nombre)
- Autenticación propia (login/registro)

## Archivos Creados/Modificados

### Nuevos
```
lib/
├── config/
│   ├── app_config.dart         # Configuración centralizada de marca
│   └── tenant_service.dart    # Servicio multi-tenant
├── screens/
│   ├── auth_screen.dart        # Login/Registro
│   └── configuracion_screen.dart # Configuración de marca
└── COMERCIAL_SQL.sql          # Estructura de BD
```

### Modificados
```
lib/
├── main.dart                  # Con autenticación
├── services/api_service.dart   # Filtrado por user_id
├── screens/home_screen.dart    # Menú de configuración
└── utils/pdf_helper.dart      # Marca configurable
```

## Pasos para Deploy

### 1. Crear nuevo proyecto en Supabase
- Ve a supabase.com
- Crea nuevo proyecto (ej: "Inventario SaaS")

### 2. Ejecutar SQL
- En el nuevo proyecto > SQL Editor
- Copia el contenido de `COMERCIAL_SQL.sql`
- Ejecuta

### 3. Configurar Auth en Supabase
- Authentication > Settings
- Configura email templates si quieres verificar emails
- Anota las credenciales del proyecto (Settings > API)

### 4. Actualizar .env
```bash
# En inventario_app/
cp .env.comercial.example .env
# Editar .env con las nuevas credenciales
```

### 5. Compilar
```bash
cd inventario_app
flutter pub get
flutter build apk --release
```

## Modelos de Monetización

### SaaS (Recomendado)
1. Hospedas la app
2. Clientes se registran solos
3. Cobras suscripción (ej: $15/mes)
4. Puedes agregar Stripe después

### Licencia
1. Compilas la app con las credenciales del cliente
2. El cliente usa su propio Supabase (o el tuyo)
3. Vendes licencia perpetua

## Base de Datos - Estructura

```
┌─────────────────────────────────────────────────┐
│                    USUARIO                       │
│              (Supabase Auth)                      │
└─────────────────┬───────────────────────────────┘
                  │ UUID
    ┌─────────────┼─────────────┐
    ▼             ▼             ▼
┌─────────┐ ┌──────────┐ ┌──────────┐
│categorias│ │productos │ │  ventas  │
│(propios)│ │ (propios)│ │ (propias)│
└─────────┘ └──────────┘ └──────────┘

tenant_config: guarda nombre, logo, colores
```

## Próximos Pasos (Opcional)

- [ ] Integrar Stripe para suscripciones
- [ ] Agregar plan gratuito con límite de productos
- [ ] Panel de admin para ver clientes
- [ ] Email de bienvenida automático
