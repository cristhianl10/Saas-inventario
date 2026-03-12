-- Script para corregir la base de datos de Sublirium Inventario
-- Ejecuta estos comandos en tu consola de Supabase SQL Editor

-- 1. Agregar columnas faltantes a la tabla productos
ALTER TABLE productos 
ADD COLUMN IF NOT EXISTS vendido BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS fecha_venta TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS vendido_a TEXT,
ADD COLUMN IF NOT EXISTS precio_venta DECIMAL(10,2);

-- 2. Verificar que las columnas se agregaron correctamente
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'productos'
ORDER BY ordinal_position;

-- 3. (Opcional) Si quieres ver la estructura completa de tus tablas
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name IN ('categorias', 'productos', 'ventas')
ORDER BY table_name, ordinal_position;
