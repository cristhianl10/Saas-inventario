# Sublirium Inventario App

## Descripción

Sistema de control de inventario para el emprendimiento **Sublirium**, desarrollado en Flutter con conexión a Supabase como backend.

## Funcionalidades

### 1. Gestión de Categorías
- Crear, editar y eliminar categorías
- Vista de todas las categorías con contador de productos
- Búsqueda de categorías por nombre

### 2. Gestión de Productos
- CRUD completo de productos (crear, leer, actualizar, eliminar)
- Asociación de productos con categorías
- Control de stock (cantidad)
- Registro de precios
- Filtros por estado de stock (todos, en stock, sin stock)
- Actualización rápida de cantidad (+/-)
- Registro de ventas con fecha, cantidad, precio y cliente

### 3. Tabla de Precios por Cantidad
- Definición de precios variables según cantidad
- Precio base (1 unidad) sincronizado con el producto
- Rangos de cantidad con precios específicos
- Validación automática para evitar duplicados
- Sincronización bidireccional (editar desde producto o tabla de precios)
- Opción de "precio ilimitado" para el último rango

### 4. Resumen y Estadísticas
- Vista general de ventas
- Totales por período (día, semana, mes, total)
- Filtrado por fechas
- Detalle de cada venta con información del producto
- Eliminación de ventas

### 5. Exportación PDF
- Generación de reportes en PDF
- Inventario completo por categoría
- Tabla de precios por producto
- Incluye valores totales y descuentos

## Tecnologías

| Componente | Tecnología |
|------------|------------|
| Frontend | Flutter |
| Backend | Supabase |
| Base de datos | PostgreSQL |
| PDF | pdf + printing packages |
| Estado | StatefulWidget |

## Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── config/
│   └── app_theme.dart          # Tema y colores de marca
├── models/
│   ├── categoria.dart          # Modelo de categoría
│   ├── producto.dart           # Modelo de producto
│   ├── venta.dart              # Modelo de venta
│   └── precio_tarifa.dart      # Modelo de tarifas de precios
├── services/
│   └── api_service.dart        # Conexión con Supabase
├── screens/
│   ├── home_screen.dart        # Pantalla principal
│   ├── productos_screen.dart    # Gestión de productos
│   ├── resumen_screen.dart     # Resumen de ventas
│   └── tabla_precios_screen.dart # Tabla de precios
└── utils/
    └── pdf_tablas_precios_builder.dart # Constructor de PDFs
```

## Base de Datos (Supabase)

### Tablas

#### categorias
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | SERIAL | Identificador único |
| nombre | TEXT | Nombre de la categoría |

#### productos
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | SERIAL | Identificador único |
| categoria_id | INTEGER | FK a categorias |
| nombre | TEXT | Nombre del producto |
| descripcion | TEXT | Descripción (nullable) |
| cantidad | INTEGER | Stock actual |
| precio | DECIMAL | Precio unitario base |
| fecha_actualizacion | TIMESTAMP | Última modificación |

#### ventas
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | SERIAL | Identificador único |
| producto_id | INTEGER | FK a productos |
| cantidad | INTEGER | Cantidad vendida |
| precio_unitario | DECIMAL | Precio por unidad |
| total | DECIMAL | Total de la venta |
| fecha_venta | TIMESTAMP | Fecha de la venta |
| vendido_a | TEXT | Nombre del cliente (nullable) |
| observaciones | TEXT | Notas adicionales (nullable) |

#### tarifa_precios
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | SERIAL | Identificador único |
| producto_id | INTEGER | FK a productos |
| cantidad_min | INTEGER | Cantidad mínima del rango |
| cantidad_max | INTEGER | Cantidad máxima (nullable = ilimitado) |
| precio_unitario | DECIMAL | Precio por unidad en este rango |
| fecha_creacion | TIMESTAMP | Fecha de creación |

## Colores de Marca

| Color | Hex | Uso |
|-------|-----|-----|
| Cyan | #00BCD4 | Acentos principales |
| Purple | #9C27B0 | Gradientes |
| Magenta | #E91E63 | Acentos |
| Orange | #FF9800 | Alertas |
| Yellow | #FFEB3B | Destacados |

## Validaciones

### Productos
- Nombre obligatorio
- Cantidad no negativa
- Precio no negativo (soporta formato con coma o punto)

### Tarifas de Precios
- Cantidad mínima >= 1
- Cantidad máxima > cantidad mínima
- No permitir rangos duplicados para el mismo producto
- Precio base (1 unidad) sincronizado con el producto

## Uso

1. **Categorías**: Crear categorías para organizar productos
2. **Productos**: Agregar productos con stock y precio base
3. **Tabla de Precios**: Definir precios por cantidad para descuentos por volumen
4. **Ventas**: Registrar ventas para llevar control de inventario
5. **Resumen**: Ver estadísticas y totales de ventas
6. **PDF**: Exportar reportes de inventario o tablas de precios

## Instalación

```bash
flutter pub get
flutter build apk --release
```

## Notas

- La app requiere conexión a internet para sincronizar con Supabase
- Los datos se almacenan en la nube, permitiendo acceso desde múltiples dispositivos
- El precio base del producto y la tarifa de cantidad = 1 están siempre sincronizados
