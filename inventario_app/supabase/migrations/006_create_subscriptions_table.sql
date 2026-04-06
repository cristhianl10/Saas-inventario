-- Tabla de suscripciones para manejar renovaciones y cancelaciones
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  plan TEXT NOT NULL CHECK (plan IN ('gratis', 'basico', 'pro')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'canceled', 'expired', 'pending')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  canceled_at TIMESTAMPTZ,
  payphone_subscription_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Política: usuarios ven solo su suscripción
CREATE POLICY "Users can view own subscription" ON public.subscriptions
  FOR SELECT USING (auth.uid() = user_id);

-- Política: usuarios pueden actualizar su suscripción (solo cancelar)
CREATE POLICY "Users can update own subscription" ON public.subscriptions
  FOR UPDATE USING (auth.uid() = user_id);

-- Política: sistema inserta suscripciones
CREATE POLICY "System can insert subscriptions" ON public.subscriptions
  FOR INSERT WITH CHECK (true);

-- Función para cancelar suscripción
CREATE OR REPLACE FUNCTION cancel_subscription(p_user_id UUID)
RETURNS public.subscriptions
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_subscription public.subscriptions;
BEGIN
  -- Actualizar suscripción a cancelada
  UPDATE public.subscriptions
  SET 
    status = 'canceled',
    canceled_at = NOW(),
    updated_at = NOW()
  WHERE user_id = p_user_id AND status = 'active'
  RETURNING * INTO v_subscription;

  -- Regresar al plan gratis
  UPDATE public.users
  SET 
    plan = 'gratis',
    plan_active = false,
    updated_at = NOW()
  WHERE id = p_user_id;

  RETURN v_subscription;
END;
$$;

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
