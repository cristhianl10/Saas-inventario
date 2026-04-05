// Supabase Edge Function: payphone-payment
// Genera botón de pago de PayPhone

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const PAYPHONE_API_URL = "https://api.payphonetodoespanol.com/api/v2"
const PAYPHONE_TOKEN_URL = "https://api.payphonetodoespanol.com/api/v2/login"

// Precios en centavos (USD - PayPhone usa centavos)
const PRICES: Record<string, number> = {
  gratis: 0,
  basico: 900,   // $9.00
  pro: 1900      // $19.00
}

const PLAN_NAMES: Record<string, string> = {
  gratis: "StockFlow Gratis",
  basico: "StockFlow Básico",
  pro: "StockFlow Pro"
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
}

serve(async (req: Request) => {
  // Manejar preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const { plan, userId, userEmail, userName } = await req.json()

    // Validaciones
    if (!plan || !["gratis", "basico", "pro"].includes(plan)) {
      return new Response(
        JSON.stringify({ error: "Plan inválido" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    if (plan === "gratis") {
      return new Response(
        JSON.stringify({ 
          error: "El plan gratis no requiere pago",
          isFree: true 
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // Si el plan es gratis, activar directamente
    if (plan === "gratis") {
      const supabaseUrl = Deno.env.get("SUPABASE_URL")!
      const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
      const supabase = createClient(supabaseUrl, supabaseServiceKey)

      await supabase.rpc("update_user_plan", {
        p_user_id: userId,
        p_plan: "gratis"
      })

      return new Response(
        JSON.stringify({ success: true, plan: "gratis" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // Obtener token de PayPhone
    const clientId = Deno.env.get("PAYPHONE_CLIENT_ID")
    const clientSecret = Deno.env.get("PAYPHONE_CLIENT_SECRET")

    if (!clientId || !clientSecret) {
      return new Response(
        JSON.stringify({ error: "PayPhone no configurado" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const tokenResponse = await fetch(PAYPHONE_TOKEN_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        clientId: clientId,
        clientSecret: clientSecret
      })
    })

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text()
      console.error("PayPhone auth error:", errorText)
      return new Response(
        JSON.stringify({ error: "Error de autenticación con PayPhone" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const { token } = await tokenResponse.json()

    // Crear botón de pago
    const amount = PRICES[plan]
    const clientTransactionId = `${userId}_${plan}_${Date.now()}`

    const buttonResponse = await fetch(`${PAYPHONE_API_URL}/button`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`
      },
      body: JSON.stringify({
        amount: amount,
        amountWithTax: amount,
        clientTransactionId: clientTransactionId,
        email: userEmail || "",
        "optionalParameter": userId,
        "phone": "",
        "productDescription": PLAN_NAMES[plan],
        "responseUrl": `${Deno.env.get("APP_URL") || "stockflow://"}/payment-callback`,
        "referenceUrl": `${Deno.env.get("SUPABASE_URL")}/functions/v1/payphone-webhook`
      })
    })

    if (!buttonResponse.ok) {
      const errorText = await buttonResponse.text()
      console.error("PayPhone button error:", errorText)
      return new Response(
        JSON.stringify({ error: "Error al crear botón de pago" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const paymentData = await buttonResponse.json()

    // Guardar intento de pago en logs
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    await supabase.from("subscription_logs").insert({
      user_id: userId,
      plan: plan,
      action: "payment_initiated",
      transaction_id: clientTransactionId,
      amount: amount,
      status: "pending"
    })

    return new Response(
      JSON.stringify({
        success: true,
        payphoneUrl: paymentData.href,
        transactionId: clientTransactionId,
        amount: amount,
        plan: plan
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
