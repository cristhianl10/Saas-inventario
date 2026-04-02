-- ═══════════════════════════════════════════════════════════════════════════════
-- 📧 CONFIGURACIÓN DE VERIFICACIÓN DE EMAIL - STOCKFLOW
-- ═══════════════════════════════════════════════════════════════════════════════
-- Este script configura Supabase para enviar emails de verificación
-- cuando un usuario se registra.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 1: HABILITAR SMTP PARA ENVÍO DE EMAILS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Ve a tu Dashboard de Supabase:
-- Authentication → Email Templates → Templates
-- Verifica que el template de "Confirm signup" esté activo

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 2: CONFIGURAR REDIRECT URL (SITE URL)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Ve a: Authentication → URL Configuration

/*
Configura estos valores:

Site URL: stockflow://auth/callback
Redirect URLs:
  - stockflow://auth/callback
  - app://auth/callback
  - io.supabase.stockflow://login-callback/

NOTA: El esquema "stockflow://" debe estar configurado en tu app Flutter.
Para desarrollo local, puedes usar:
  - http://localhost:3000/auth/callback
*/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 3: CONFIGURAR AUTENTICACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

-- Ve a: Authentication → Settings

/*
Configura:

✅ Enable sign up: YES (permite nuevos registros)
❌ Enable anonymous sign-ins: NO (seguridad)
❌ Enable auto-confirm: NO (requiere verificar email)
✅ Enable confirm email: YES (envía email de verificación)
❌ Enable auto-delete users: NO

Password requirements:
- Minimum length: 8 characters

Rate limits:
- Maximum simultaneous connections:可根据需要调整
- Login attempts per email: 5 per minute
*/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 4: PERSONALIZAR EMAIL DE VERIFICACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

-- Ve a: Authentication → Email Templates → Confirm signup

-- Template predeterminado (puedes personalizarlo):
/*
Subject: Confirma tu cuenta de StockFlow

Hola {{ .Email }},

Gracias por registrarte en StockFlow. Por favor confirma tu cuenta haciendo clic en el siguiente enlace:

<a href="{{ .ConfirmationURL }}">Confirmar mi cuenta</a>

Si no solicitaste este registro, ignora este correo.

Saludos,
El equipo de StockFlow
*/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 5: AGREGAR POLÍTICA DE VERIFICACIÓN DE EMAIL
-- ═══════════════════════════════════════════════════════════════════════════════

-- Crear función para verificar si el usuario ha confirmado su email
CREATE OR REPLACE FUNCTION auth.user_has_verified_email()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND email_confirmed_at IS NOT NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Crear función para verificar si el usuario está activo
CREATE OR REPLACE FUNCTION auth.is_user_active()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND (email_confirmed_at IS NOT NULL OR created_at > NOW() - INTERVAL '5 minutes')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 6: POLÍTICAS DE SEGURIDAD PARA TENANT_CONFIG
-- ═══════════════════════════════════════════════════════════════════════════════

-- Asegurar que solo usuarios verificados puedan ver su configuración
CREATE POLICY tenant_config_select_verified ON tenant_config
    FOR SELECT
    USING (
        auth.uid() = user_id 
        AND EXISTS (
            SELECT 1 FROM auth.users 
            WHERE id = auth.uid() 
            AND email_confirmed_at IS NOT NULL
        )
    );

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 7: FUNCIÓN PARA OBTENER ESTADO DE VERIFICACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION auth.get_user_verification_status()
RETURNS JSONB AS $$
DECLARE
    user_record auth.users;
    result JSONB;
BEGIN
    SELECT * INTO user_record FROM auth.users WHERE id = auth.uid();
    
    IF user_record IS NULL THEN
        RETURN jsonb_build_object(
            'exists', false,
            'verified', false,
            'message', 'Usuario no encontrado'
        );
    END IF;
    
    RETURN jsonb_build_object(
        'exists', true,
        'verified', user_record.email_confirmed_at IS NOT NULL,
        'email', user_record.email,
        'created_at', user_record.created_at,
        'last_sign_in_at', user_record.last_sign_in_at,
        'message', CASE 
            WHEN user_record.email_confirmed_at IS NOT NULL THEN 'Email verificado'
            ELSE 'Email pendiente de verificación'
        END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 8: LOG DE VERIFICACIONES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Crear tabla para logs de verificación
CREATE TABLE IF NOT EXISTS email_verification_log (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    email TEXT NOT NULL,
    action TEXT NOT NULL, -- 'SENT', 'CONFIRMED', 'RESENT'
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS email_verification_log_user_id_idx ON email_verification_log(user_id);
CREATE INDEX IF NOT EXISTS email_verification_log_email_idx ON email_verification_log(email);
CREATE INDEX IF NOT EXISTS email_verification_log_created_at_idx ON email_verification_log(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 9: FUNCIÓN PARA REENVÍO DE EMAIL DE VERIFICACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

-- Esta función permite reenviar el email de verificación
-- Se llama desde la app cuando el usuario lo solicita

-- NOTA: En Supabase, el reenvío de emails de verificación se hace
-- automáticamente con la función de Supabase auth:
-- await supabase.auth.resend({type: 'signup', email: userEmail})

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 10: VERIFICACIÓN DE CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

-- Ejecuta esta consulta para verificar que todo está configurado:
SELECT 
    'Auth Functions' as check_type,
    COUNT(*) as count,
    'Verificadas' as status
FROM pg_proc 
WHERE proname IN ('user_has_verified_email', 'is_user_active', 'get_user_verification_status');

-- ═══════════════════════════════════════════════════════════════════════════════
-- ✅ CONFIGURACIÓN COMPLETA
-- ═══════════════════════════════════════════════════════════════════════════════

/*
LO QUE FALTA HACER MANUALMENTE EN SUPABASE DASHBOARD:

1. Ir a Authentication → Settings → Email
   - Configurar SMTP si tienes uno personalizado
   - O usar el SMTP de Supabase (configurado por defecto)

2. Ir a Authentication → URL Configuration
   - Site URL: stockflow://auth/callback
   - Redirect URLs:
     * stockflow://auth/callback
     * app://auth/callback

3. Ir a Authentication → Providers → Email
   - Enable Email provider: YES
   - Allow New Users: YES
   - Allow Manual Linking: NO (opcional)

4. En tu app Flutter, configurar el deep linking:
   - Android: Agregar intent-filter en AndroidManifest.xml
   - iOS: Agregar URL scheme en Info.plist

PARA DESARROLLO LOCAL, puedes usar:
   - Site URL: http://localhost:3000
   - Redirect URL: http://localhost:3000/auth/callback

PARA PRODUCCIÓN, usa tu dominio:
   - Site URL: https://tudominio.com
   - Redirect URLs:
     * https://tudominio.com/auth/callback
     * stockflow://auth/callback
*/

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔧 CONFIGURACIÓN DE DEEP LINKING EN FLUTTER
-- ═══════════════════════════════════════════════════════════════════════════════

/*
En Android (android/app/src/main/AndroidManifest.xml):

<intent-filter>
    <action android:name="android.intent.action.MAIN" />
    <category android:name="android.intent.category.LAUNCHER" />
</intent-filter>

<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="stockflow" android:host="auth/callback" />
</intent-filter>

<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="tudominio.com" />
</intent-filter>

En iOS (ios/Runner/Info.plist):

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>stockflow</string>
        </array>
        <key>CFBundleURLName</key>
        <string>StockFlow</string>
    </dict>
</array>
*/

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📱 ACTUALIZAR main.dart PARA MANEJAR DEEP LINKS
-- ═══════════════════════════════════════════════════════════════════════════════

/*
En tu main.dart, ya está configurado el manejo de verificación.
Pero si necesitas manejar deep links explícitamente, añade:

import 'package:uni_links/uni_links.dart';

Y en initState():
_initDeepLinkListener();

Future<void> _initDeepLinkListener() async {
    // Manejar links cuando la app se abre con un link
    final initialUri = await getInitialUri();
    if (initialUri != null) {
        await Supabase.instance.auth.getSessionFromUrl(initialUri);
    }

    // Escuchar cambios de links mientras la app está abierta
    uriLinkStream.listen((uri) async {
        if (uri != null) {
            await Supabase.instance.auth.getSessionFromUrl(uri);
        }
    });
}
*/
