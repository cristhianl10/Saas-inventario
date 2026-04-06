// Supabase Edge Function: cancel-subscription
// Cancela la suscripción del usuario y regresa a plan gratis

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    // Obtener user_id del header de autorización
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "No autorizado" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // Crear cliente con el token del usuario
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    })

    // Obtener usuario actual
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Usuario no encontrado" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // Verificar que tiene una suscripción activa
    const { data: subscription, error: subError } = await supabase
      .from("subscriptions")
      .select("*")
      .eq("user_id", user.id)
      .eq("status", "active")
      .maybeSingle()

    if (subError) {
      console.error("Error buscando suscripción:", subError)
      return new Response(
        JSON.stringify({ error: "Error al verificar suscripción" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    if (!subscription) {
      return new Response(
        JSON.stringify({ error: "No tienes una suscripción activa para cancelar" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // Cancelar suscripción usando la función SQL
    const { data: canceledSub, error: cancelError } = await supabase
      .rpc("cancel_subscription", { p_user_id: user.id })

    if (cancelError) {
      console.error("Error cancelando:", cancelError)
      return new Response(
        JSON.stringify({ error: "Error al cancelar suscripción" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // Registrar en logs
    await supabase.from("subscription_logs").insert({
      user_id: user.id,
      plan: subscription.plan,
      action: "subscription_canceled",
      transaction_id: subscription.payphone_subscription_id,
      status: "canceled"
    })

    return new Response(
      JSON.stringify({
        success: true,
        message: "Suscripción cancelada. Has regresado al plan gratis.",
        plan: "gratis"
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )

  } catch (error) {
    console.error("Error:", error)
    return new Response(
      JSON.stringify({ error: "Error interno del servidor" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})
