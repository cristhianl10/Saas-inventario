-- Script para corregir la tabla categorias
-- Ejecuta esto en Supabase SQL Editor

-- Agregar columna descripcion a la tabla categorias
ALTER TABLE categorias 
ADD COLUMN IF NOT EXISTS descripcion TEXT;

-- Verificar que se agregó correctamente
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'categorias'
ORDER BY ordinal_position;

-- Resultado esperado:
-- id, nombre, emoji, color, descripcion
