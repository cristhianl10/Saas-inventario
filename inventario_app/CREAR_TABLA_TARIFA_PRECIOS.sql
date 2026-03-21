-- ============================================
-- TABLA DE TARIFAS DE PRECIOS
-- ============================================
-- Ejecuta esto en tu Supabase SQL Editor
-- NO afecta las tablas existentes (categorias, productos, ventas)

CREATE TABLE IF NOT EXISTS tarifa_precios (
    id SERIAL PRIMARY KEY,
    producto_id INTEGER NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    cantidad_min INTEGER NOT NULL CHECK (cantidad_min >= 1),
    cantidad_max INTEGER,
    precio_unitario DECIMAL(10, 2) NOT NULL CHECK (precio_unitario > 0),
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT cantidad_rango_valido CHECK (
        cantidad_max IS NULL OR cantidad_max > cantidad_min
    )
);

-- Índice para búsqueda rápida por producto
CREATE INDEX IF NOT EXISTS idx_tarifa_precios_producto 
ON tarifa_precios(producto_id);

-- Índice para ordenamiento
CREATE INDEX IF NOT EXISTS idx_tarifa_precios_cantidad 
ON tarifa_precios(producto_id, cantidad_min);

-- ============================================
-- POLÍTICAS DE SEGURIDAD (RLS)
-- ============================================

-- Habilitar RLS
ALTER TABLE tarifa_precios ENABLE ROW LEVEL SECURITY;

-- Permitir lectura a todos (anon key)
CREATE POLICY "Permitir lectura" ON tarifa_precios
    FOR SELECT USING (true);

-- Permitir insertar a todos
CREATE POLICY "Permitir insertar" ON tarifa_precios
    FOR INSERT WITH CHECK (true);

-- Permitir actualizar a todos
CREATE POLICY "Permitir actualizar" ON tarifa_precios
    FOR UPDATE USING (true);

-- Permitir eliminar a todos
CREATE POLICY "Permitir eliminar" ON tarifa_precios
    FOR DELETE USING (true);
