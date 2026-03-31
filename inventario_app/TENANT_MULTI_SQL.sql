-- ============================================
-- TABLA DE CONFIGURACIÓN MULTI-TENANT
-- Para separar datos de cada cliente/empresa
-- ============================================

-- Tabla de configuración de tenant (negocio/empresa)
CREATE TABLE IF NOT EXISTS tenant_config (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    config JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_tenant_config_user_id ON tenant_config(user_id);

-- Políticas de seguridad (RLS)
ALTER TABLE tenant_config ENABLE ROW LEVEL SECURITY;

-- Cada usuario solo puede ver/modificar su propia configuración
CREATE POLICY "Users can view own tenant config" ON tenant_config
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tenant config" ON tenant_config
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tenant config" ON tenant_config
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own tenant config" ON tenant_config
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_tenant_config_updated_at
    BEFORE UPDATE ON tenant_config
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- AGREGAR user_id A LAS TABLAS EXISTENTES
-- Para filtrar datos por cliente
-- ============================================

-- Agregar user_id a categorias (si no existe)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'categorias' AND column_name = 'user_id') THEN
        ALTER TABLE categorias ADD COLUMN user_id TEXT REFERENCES auth.users(id);
        CREATE INDEX IF NOT EXISTS idx_categorias_user_id ON categorias(user_id);
        
        -- Permitir que usuarios solo vean sus categorías
        ALTER TABLE categorias ENABLE ROW LEVEL SECURITY;
        
        CREATE POLICY "Users can view own categories" ON categorias
            FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert own categories" ON categorias
            FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "Users can update own categories" ON categorias
            FOR UPDATE USING (auth.uid() = user_id);
        CREATE POLICY "Users can delete own categories" ON categorias
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Agregar user_id a productos
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'productos' AND column_name = 'user_id') THEN
        ALTER TABLE productos ADD COLUMN user_id TEXT REFERENCES auth.users(id);
        CREATE INDEX IF NOT EXISTS idx_productos_user_id ON productos(user_id);
        
        ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
        
        CREATE POLICY "Users can view own productos" ON productos
            FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert own productos" ON productos
            FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "Users can update own productos" ON productos
            FOR UPDATE USING (auth.uid() = user_id);
        CREATE POLICY "Users can delete own productos" ON productos
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Agregar user_id a ventas
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ventas' AND column_name = 'user_id') THEN
        ALTER TABLE ventas ADD COLUMN user_id TEXT REFERENCES auth.users(id);
        CREATE INDEX IF NOT EXISTS idx_ventas_user_id ON ventas(user_id);
        
        ALTER TABLE ventas ENABLE ROW LEVEL SECURITY;
        
        CREATE POLICY "Users can view own ventas" ON ventas
            FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert own ventas" ON ventas
            FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "Users can update own ventas" ON ventas
            FOR UPDATE USING (auth.uid() = user_id);
        CREATE POLICY "Users can delete own ventas" ON ventas
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Agregar user_id a tarifa_precios
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tarifa_precios' AND column_name = 'user_id') THEN
        ALTER TABLE tarifa_precios ADD COLUMN user_id TEXT REFERENCES auth.users(id);
        CREATE INDEX IF NOT EXISTS idx_tarifa_precios_user_id ON tarifa_precios(user_id);
        
        ALTER TABLE tarifa_precios ENABLE ROW LEVEL SECURITY;
        
        CREATE POLICY "Users can view own tarifa_precios" ON tarifa_precios
            FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert own tarifa_precios" ON tarifa_precios
            FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "Users can update own tarifa_precios" ON tarifa_precios
            FOR UPDATE USING (auth.uid() = user_id);
        CREATE POLICY "Users can delete own tarifa_precios" ON tarifa_precios
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Agregar user_id a proveedores
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proveedores' AND column_name = 'user_id') THEN
        ALTER TABLE proveedores ADD COLUMN user_id TEXT REFERENCES auth.users(id);
        CREATE INDEX IF NOT EXISTS idx_proveedores_user_id ON proveedores(user_id);
        
        ALTER TABLE proveedores ENABLE ROW LEVEL SECURITY;
        
        CREATE POLICY "Users can view own proveedores" ON proveedores
            FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert own proveedores" ON proveedores
            FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "Users can update own proveedores" ON proveedores
            FOR UPDATE USING (auth.uid() = user_id);
        CREATE POLICY "Users can delete own proveedores" ON proveedores
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

COMMENT ON TABLE tenant_config IS 'Configuración de marca y preferences por tenant (negocio/empresa)';
