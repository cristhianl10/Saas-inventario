-- ============================================
-- ESTRUCTURA DE BASE DE DATOS PARA APP COMERCIAL
-- Nuevo proyecto de Supabase (separado del personal)
-- ============================================

-- CONFIGURACIÓN DE TENANT (marca por negocio)
CREATE TABLE tenant_config (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    config JSONB NOT NULL DEFAULT '{"app_name":"Inventario","brand_name":"Mi Negocio","logo_path":"assets/logos/logo_default.png","primary_color":"#C1356F","secondary_color":"#597FA9","accent_color":"#E57836","background_color":"#FBF8F1"}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_tenant_config_user_id ON tenant_config(user_id);

-- CATEGORÍAS
CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    emoji TEXT,
    color TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_categorias_user_id ON categorias(user_id);

-- PROVEEDORES
CREATE TABLE proveedores (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre VARCHAR NOT NULL,
    telefono VARCHAR,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_proveedores_user_id ON proveedores(user_id);

-- PRODUCTOS
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    categoria_id INT REFERENCES categorias(id),
    proveedor_id INT REFERENCES proveedores(id),
    nombre TEXT NOT NULL,
    descripcion TEXT,
    cantidad INT DEFAULT 0,
    precio NUMERIC DEFAULT 0,
    costo NUMERIC DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE,
    fecha_actualizacion TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_productos_user_id ON productos(user_id);
CREATE INDEX idx_productos_categoria ON productos(categoria_id);

-- VENTAS
CREATE TABLE ventas (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    producto_id INT NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    cantidad INT NOT NULL,
    precio_unitario NUMERIC NOT NULL,
    total NUMERIC NOT NULL,
    fecha_venta TIMESTAMPTZ DEFAULT NOW(),
    vendido_a TEXT,
    observaciones TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_ventas_user_id ON ventas(user_id);
CREATE INDEX idx_ventas_fecha ON ventas(fecha_venta);

-- TARIFA DE PRECIOS
CREATE TABLE tarifa_precios (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    producto_id INT NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    cantidad_min INT NOT NULL,
    cantidad_max INT,
    precio_unitario NUMERIC NOT NULL,
    fecha_creacion TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_tarifa_user_id ON tarifa_precios(user_id);
CREATE INDEX idx_tarifa_producto ON tarifa_precios(producto_id);

-- SEGURIDAD RLS
ALTER TABLE tenant_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE proveedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE ventas ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarifa_precios ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tenant_config_own" ON tenant_config FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "categorias_own" ON categorias FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "proveedores_own" ON proveedores FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "productos_own" ON productos FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "ventas_own" ON ventas FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "tarifa_precios_own" ON tarifa_precios FOR ALL USING (auth.uid() = user_id);
