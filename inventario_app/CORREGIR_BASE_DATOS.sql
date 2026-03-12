-- Script para corregir la base de datos de Sublirium Inventario
-- Ejecuta estos comandos en tu consola de Supabase SQL Editor

-- 1. Agregar columna descripcion a categorias
ALTER TABLE categorias 
ADD COLUMN IF NOT EXISTS descripcion TEXT;

-- 2. Agregar columnas faltantes a la tabla productos
ALTER TABLE productos 
ADD COLUMN IF NOT EXISTS vendido BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS fecha_venta TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS vendido_a TEXT,
ADD COLUMN IF NOT EXISTS precio_venta DECIMAL(10,2);

-- 3. Verificar que las columnas se agregaron correctamente
SELECT 'categorias' as tabla, column_name, data_type
FROM information_schema.columns
WHERE table_name = 'categorias'
UNION ALL
SELECT 'productos' as tabla, column_name, data_type
FROM information_schema.columns
WHERE table_name = 'productos'
ORDER BY tabla, column_name;
