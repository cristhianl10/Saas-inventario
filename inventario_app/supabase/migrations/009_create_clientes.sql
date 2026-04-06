-- Tabla de clientes
CREATE TABLE IF NOT EXISTS clientes (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  telefono TEXT,
  email TEXT,
  direccion TEXT,
  notas TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Añadir cliente_id a ventas si no existe
ALTER TABLE ventas ADD COLUMN IF NOT EXISTS cliente_id INTEGER REFERENCES clientes(id) ON DELETE SET NULL;

-- Índices
CREATE INDEX IF NOT EXISTS idx_clientes_user ON clientes(user_id);
CREATE INDEX IF NOT EXISTS idx_ventas_cliente ON ventas(cliente_id);

-- Enable RLS
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;

-- Policies para clientes
CREATE POLICY "Users can view their own clients" 
  ON clientes FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own clients" 
  ON clientes FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own clients" 
  ON clientes FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own clients" 
  ON clientes FOR DELETE 
  USING (auth.uid() = user_id);
