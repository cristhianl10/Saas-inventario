-- Tabla para órdenes de compra a proveedores
CREATE TABLE IF NOT EXISTS purchase_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id INTEGER REFERENCES proveedores(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT 'Orden de compra',
  details TEXT,
  units INTEGER DEFAULT 0,
  amount NUMERIC(10,2) DEFAULT 0,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'requested', 'received', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expected_at TIMESTAMPTZ,
  received_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla para historial de compras completadas (stock agregado al inventario)
CREATE TABLE IF NOT EXISTS purchase_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_order_id UUID REFERENCES purchase_orders(id) ON DELETE SET NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  provider_id INTEGER REFERENCES proveedores(id) ON DELETE SET NULL,
  product_id INTEGER REFERENCES productos(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  unit_cost NUMERIC(10,2) NOT NULL,
  total_cost NUMERIC(10,2) NOT NULL,
  received_at TIMESTAMPTZ DEFAULT NOW(),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_purchase_orders_provider ON purchase_orders(provider_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_user ON purchase_orders(user_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_status ON purchase_orders(status);
CREATE INDEX IF NOT EXISTS idx_purchase_history_provider ON purchase_history(provider_id);
CREATE INDEX IF NOT EXISTS idx_purchase_history_product ON purchase_history(product_id);
CREATE INDEX IF NOT EXISTS idx_purchase_history_user ON purchase_history(user_id);

-- Enable RLS
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_history ENABLE ROW LEVEL SECURITY;

-- Policies para purchase_orders
CREATE POLICY "Users can view their own purchase orders" 
  ON purchase_orders FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own purchase orders" 
  ON purchase_orders FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own purchase orders" 
  ON purchase_orders FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own purchase orders" 
  ON purchase_orders FOR DELETE 
  USING (auth.uid() = user_id);

-- Policies para purchase_history
CREATE POLICY "Users can view their own purchase history" 
  ON purchase_history FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own purchase history" 
  ON purchase_history FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own purchase history" 
  ON purchase_history FOR DELETE 
  USING (auth.uid() = user_id);
