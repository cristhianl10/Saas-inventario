-- Agregar campos de plan a la tabla users
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS plan TEXT DEFAULT 'gratis';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS plan_active BOOLEAN DEFAULT true;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS plan_started_at TIMESTAMPTZ;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS plan_expires_at TIMESTAMPTZ;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS payphone_transaction_id TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS subscription_id TEXT;

-- Crear función para actualizar plan
CREATE OR REPLACE FUNCTION update_user_plan(
  p_user_id UUID,
  p_plan TEXT,
  p_transaction_id TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.users
  SET 
    plan = p_plan,
    plan_active = true,
    plan_started_at = NOW(),
    plan_expires_at = CASE 
      WHEN p_plan = 'basico' THEN NOW() + INTERVAL '1 month'
      WHEN p_plan = 'pro' THEN NOW() + INTERVAL '1 month'
      ELSE NULL
    END,
    payphone_transaction_id = COALESCE(p_transaction_id, payphone_transaction_id),
    updated_at = NOW()
  WHERE id = p_user_id;
END;
$$;

-- Crear función para verificar acceso a功能
CREATE OR REPLACE FUNCTION check_plan_feature(
  p_user_id UUID,
  p_feature TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_plan TEXT;
  v_active BOOLEAN;
BEGIN
  SELECT plan, plan_active INTO v_plan, v_active
  FROM public.users
  WHERE id = p_user_id;
  
  IF NOT v_active OR v_plan IS NULL THEN
    RETURN false;
  END IF;
  
  -- Definir características por plan
  IF p_feature = 'unlimited_products' THEN
    RETURN v_plan IN ('basico', 'pro');
  ELSIF p_feature = 'combos' THEN
    RETURN v_plan IN ('basico', 'pro');
  ELSIF p_feature = 'volume_pricing' THEN
    RETURN v_plan IN ('basico', 'pro');
  ELSIF p_feature = 'pdf_export' THEN
    RETURN v_plan IN ('basico', 'pro');
  ELSIF p_feature = 'suppliers' THEN
    RETURN v_plan IN ('basico', 'pro');
  ELSIF p_feature = 'brand_config' THEN
    RETURN v_plan = 'pro';
  ELSIF p_feature = 'ai_analysis' THEN
    RETURN v_plan = 'pro';
  ELSIF p_feature = 'historical_reports' THEN
    RETURN v_plan = 'pro';
  ELSE
    RETURN false;
  END IF;
END;
$$;

-- Crear tabla para logs de suscripciones
CREATE TABLE IF NOT EXISTS public.subscription_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  plan TEXT NOT NULL,
  action TEXT NOT NULL,
  transaction_id TEXT,
  amount INTEGER,
  status TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.subscription_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscription logs" ON public.subscription_logs
  FOR SELECT USING (auth.uid() = user_id);
