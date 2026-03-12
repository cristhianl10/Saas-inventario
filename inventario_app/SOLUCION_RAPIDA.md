# ⚡ Solución Rápida - Errores de Categorías y Productos

## 🔴 Problema

Errores al crear o editar categorías y productos:
```
Could not find the 'descripcion' column of 'categorias'
Could not find the 'fecha_venta' column of 'productos'
```

## ✅ Solución en 2 Minutos

### 1️⃣ Abre Supabase
- Ve a [supabase.com](https://supabase.com)
- Abre tu proyecto
- Clic en **SQL Editor** (menú izquierdo)

### 2️⃣ Copia y Pega este Código

```sql
-- Corregir tabla categorias
ALTER TABLE categorias 
ADD COLUMN IF NOT EXISTS descripcion TEXT;

-- Corregir tabla productos
ALTER TABLE productos 
ADD COLUMN IF NOT EXISTS vendido BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS fecha_venta TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS vendido_a TEXT,
ADD COLUMN IF NOT EXISTS precio_venta DECIMAL(10,2);
```

### 3️⃣ Ejecuta
- Clic en **Run** o presiona `Ctrl + Enter`
- Espera el mensaje de éxito ✅

### 4️⃣ Reinicia la App
- Cierra completamente la app
- Abre de nuevo
- ¡Listo! 🎉

---

## 🎯 Qué Hace Este Script

**Tabla categorias:**
- ✅ Agrega columna `descripcion` (para notas opcionales)

**Tabla productos:**
- ✅ Agrega columna `vendido` (si el producto fue vendido)
- ✅ Agrega columna `fecha_venta` (cuándo se vendió)
- ✅ Agrega columna `vendido_a` (nombre del cliente)
- ✅ Agrega columna `precio_venta` (precio de venta)

---

## ✅ Después de Ejecutar

Tu app podrá:
- ✅ Crear categorías
- ✅ Editar categorías
- ✅ Crear productos
- ✅ Editar productos
- ✅ Registrar ventas

---

## 🆘 Si Sigue Fallando

1. **Verifica que ejecutaste el script completo**
2. **Reinicia la app completamente**
3. **Verifica tu conexión a internet**
4. **Revisa que la URL y API Key de Supabase sean correctas en `main.dart`**

---

## 📱 Contacto

Si necesitas ayuda adicional, revisa:
- `SOLUCION_ERROR_POSTGRES.md` - Guía detallada
- `CORREGIR_BASE_DATOS.sql` - Script completo

¡Tu app Sublirium estará funcionando en 2 minutos! 🚀
