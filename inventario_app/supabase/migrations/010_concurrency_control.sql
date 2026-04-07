-- =====================================================
-- CONCURRENCY CONTROL - Optimistic Locking
-- Agrega columna 'version' a todas las tablas editables
-- =====================================================

-- Categorías
ALTER TABLE categorias ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;

-- Productos (CRÍTICO para stock)
ALTER TABLE productos ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;

-- Ventas
ALTER TABLE ventas ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;

-- Tarifas de precios
ALTER TABLE tarifa_precios ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;

-- Proveedores
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;

-- Clientes
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;

-- Combo items
ALTER TABLE combo_items ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;

-- Purchase orders (órdenes de compra)
ALTER TABLE purchase_orders ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;

-- =====================================================
-- FUNCIÓN: Auto-incrementar versión en UPDATE
-- =====================================================

-- Función para automáticamente incrementar version
CREATE OR REPLACE FUNCTION increment_version()
RETURNS TRIGGER AS $$
BEGIN
    NEW.version = OLD.version + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para categorías
DROP TRIGGER IF EXISTS increment_categorias_version ON categorias;
CREATE TRIGGER increment_categorias_version
    BEFORE UPDATE ON categorias
    FOR EACH ROW
    EXECUTE FUNCTION increment_version();

-- Trigger para productos
DROP TRIGGER IF EXISTS increment_productos_version ON productos;
CREATE TRIGGER increment_productos_version
    BEFORE UPDATE ON productos
    FOR EACH ROW
    EXECUTE FUNCTION increment_version();

-- Trigger para ventas
DROP TRIGGER IF EXISTS increment_ventas_version ON ventas;
CREATE TRIGGER increment_ventas_version
    BEFORE UPDATE ON ventas
    FOR EACH ROW
    EXECUTE FUNCTION increment_version();

-- Trigger para tarifas
DROP TRIGGER IF EXISTS increment_tarifa_precios_version ON tarifa_precios;
CREATE TRIGGER increment_tarifa_precios_version
    BEFORE UPDATE ON tarifa_precios
    FOR EACH ROW
    EXECUTE FUNCTION increment_version();

-- Trigger para proveedores
DROP TRIGGER IF EXISTS increment_proveedores_version ON proveedores;
CREATE TRIGGER increment_proveedores_version
    BEFORE UPDATE ON proveedores
    FOR EACH ROW
    EXECUTE FUNCTION increment_version();

-- Trigger para clientes
DROP TRIGGER IF EXISTS increment_clientes_version ON clientes;
CREATE TRIGGER increment_clientes_version
    BEFORE UPDATE ON clientes
    FOR EACH ROW
    EXECUTE FUNCTION increment_version();

-- Trigger para combo_items
DROP TRIGGER IF EXISTS increment_combo_items_version ON combo_items;
CREATE TRIGGER increment_combo_items_version
    BEFORE UPDATE ON combo_items
    FOR EACH ROW
    EXECUTE FUNCTION increment_version();

-- Trigger para purchase_orders
DROP TRIGGER IF EXISTS increment_purchase_orders_version ON purchase_orders;
CREATE TRIGGER increment_purchase_orders_version
    BEFORE UPDATE ON purchase_orders
    FOR EACH ROW
    EXECUTE FUNCTION increment_version();

-- =====================================================
-- Verificar que se aplicó correctamente
-- =====================================================
SELECT 
    'categorias' as tabla, column_name 
FROM information_schema.columns 
WHERE table_name = 'categorias' AND column_name = 'version'
UNION ALL
SELECT 'productos', column_name FROM information_schema.columns WHERE table_name = 'productos' AND column_name = 'version'
UNION ALL
SELECT 'ventas', column_name FROM information_schema.columns WHERE table_name = 'ventas' AND column_name = 'version'
UNION ALL
SELECT 'tarifa_precios', column_name FROM information_schema.columns WHERE table_name = 'tarifa_precios' AND column_name = 'version'
UNION ALL
SELECT 'proveedores', column_name FROM information_schema.columns WHERE table_name = 'proveedores' AND column_name = 'version'
UNION ALL
SELECT 'clientes', column_name FROM information_schema.columns WHERE table_name = 'clientes' AND column_name = 'version'
UNION ALL
SELECT 'combo_items', column_name FROM information_schema.columns WHERE table_name = 'combo_items' AND column_name = 'version'
UNION ALL
SELECT 'purchase_orders', column_name FROM information_schema.columns WHERE table_name = 'purchase_orders' AND column_name = 'version';
