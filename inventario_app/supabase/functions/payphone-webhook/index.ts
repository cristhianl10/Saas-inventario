// Supabase Edge Function: payphone-webhook
// Recibe notificaciones de PayPhone cuando se completa un pago

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
}

interface PayPhoneWebhookPayload {
  id?: string
  status?: string
  amount?: number
  clientTransactionId?: string
  optionalParameter?: string
  reference?: string
}

serve(async (req: Request) => {
  // Manejar preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const payload: PayPhoneWebhookPayload = await req.json()

    console.log("PayPhone Webhook received:", JSON.stringify(payload))

    // Validar que tenemos los datos necesarios
    if (!payload.clientTransactionId) {
      console.error("Missing clientTransactionId")
      return new Response(
        JSON.stringify({ error: "Datos incompletos" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // Parsear el clientTransactionId: userId_plan_timestamp
    const parts = payload.clientTransactionId.split("_")
    if (parts.length < 2) {
      console.error("Invalid clientTransactionId format")
      return new Response(
        JSON.stringify({ error: "Formato de transacción inválido" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const userId = parts[0]
    const plan = parts[1]

    // Crear cliente de Supabase con clave de servicio
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Verificar que el usuario existe
    const { data: user, error: userError } = await supabase
      .from("users")
      .select("id, email")
      .eq("id", userId)
      .single()

    if (userError || !user) {
      console.error("User not found:", userId)
      return new Response(
        JSON.stringify({ error: "Usuario no encontrado" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // Procesar según estado del pago
    // Estados PayPhone: Approved, Rejected, Canceled, Pending
    const paymentStatus = payload.status?.toLowerCase() || ""

    if (paymentStatus === "approved") {
      // Pago exitoso - Activar plan
      console.log(`Activating plan ${plan} for user ${userId}`)

      // Actualizar plan del usuario
      const { error: updateError } = await supabase.rpc("update_user_plan", {
        p_user_id: userId,
        p_plan: plan,
        p_transaction_id: payload.id || payload.clientTransactionId
      })

      if (updateError) {
        console.error("Error updating plan:", updateError)
      }

      // Registrar en logs
      await supabase.from("subscription_logs").insert({
        user_id: userId,
        plan: plan,
        action: "payment_approved",
        transaction_id: payload.id || payload.clientTransactionId,
        amount: payload.amount,
        status: "active"
      })

      console.log(`Plan ${plan} activated for user ${userId}`)

    } else if (paymentStatus === "rejected" || paymentStatus === "canceled") {
      // Pago fallido o cancelado
      console.log(`Payment rejected/canceled for user ${userId}`)

      await supabase.from("subscription_logs").insert({
        user_id: userId,
        plan: plan,
        action: "payment_failed",
        transaction_id: payload.id || payload.clientTransactionId,
        amount: payload.amount,
        status: "failed"
      })

    } else if (paymentStatus === "pending") {
      // Pago pendiente
      console.log(`Payment pending for user ${userId}`)

      await supabase.from("subscription_logs").insert({
        user_id: userId,
        plan: plan,
        action: "payment_pending",
        transaction_id: payload.id || payload.clientTransactionId,
        amount: payload.amount,
        status: "pending"
      })
    }

    // PayPhone espera una respuesta 200 para confirmar recepción
    return new Response(
      JSON.stringify({ received: true }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )

  } catch (error) {
    console.error("Webhook error:", error)
    return new Response(
      JSON.stringify({ error: "Error procesando webhook" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})
