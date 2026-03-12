# 📱 Guía de Instalación en Android

## Opción 1: Instalación Directa (Más Rápida) 🚀

### Paso 1: Conectar tu dispositivo Android

1. **Habilitar Modo Desarrollador en tu Android:**
   - Ve a `Ajustes` → `Acerca del teléfono`
   - Toca 7 veces sobre `Número de compilación`
   - Verás un mensaje: "Ahora eres desarrollador"

2. **Habilitar Depuración USB:**
   - Ve a `Ajustes` → `Opciones de desarrollador`
   - Activa `Depuración USB`

3. **Conectar el dispositivo:**
   - Conecta tu teléfono a la computadora con un cable USB
   - Acepta el mensaje de "Permitir depuración USB" en tu teléfono

4. **Verificar conexión:**
   ```bash
   cd inventario_app
   flutter devices
   ```
   Deberías ver tu dispositivo en la lista.

### Paso 2: Instalar directamente

```bash
cd inventario_app
flutter run --release
```

La app se instalará automáticamente en tu dispositivo.

---

## Opción 2: Generar APK (Para compartir) 📦

### Paso 1: Construir el APK

```bash
cd inventario_app
flutter build apk --release
```

Este comando genera un APK optimizado. Tomará unos minutos.

### Paso 2: Ubicar el APK

El APK se generará en:
```
inventario_app/build/app/outputs/flutter-apk/app-release.apk
```

### Paso 3: Transferir a tu Android

**Opción A - Por cable USB:**
```bash
# Copiar el APK a tu dispositivo
adb push build/app/outputs/flutter-apk/app-release.apk /sdcard/Download/
```

**Opción B - Manualmente:**
1. Copia el archivo `app-release.apk` a tu computadora
2. Envíalo a tu teléfono por:
   - WhatsApp (a ti mismo)
   - Email
   - Google Drive
   - Bluetooth
   - Cable USB (copia directa)

### Paso 4: Instalar en Android

1. En tu teléfono, ve a `Descargas` o donde guardaste el APK
2. Toca el archivo `app-release.apk`
3. Si aparece "Instalar aplicaciones desconocidas":
   - Toca `Configuración`
   - Activa `Permitir desde esta fuente`
   - Vuelve atrás y toca el APK nuevamente
4. Toca `Instalar`
5. ¡Listo! La app estará instalada

---

## Opción 3: APK Dividido por Arquitectura (Más pequeño) 📉

Para generar APKs más pequeños según la arquitectura del dispositivo:

```bash
cd inventario_app
flutter build apk --split-per-abi
```

Esto genera 3 APKs en:
```
build/app/outputs/flutter-apk/
├── app-armeabi-v7a-release.apk  (32-bit, ~20MB)
├── app-arm64-v8a-release.apk    (64-bit, ~22MB) ← Más común
└── app-x86_64-release.apk       (Emuladores)
```

**¿Cuál usar?**
- La mayoría de teléfonos modernos: `app-arm64-v8a-release.apk`
- Teléfonos antiguos: `app-armeabi-v7a-release.apk`

---

## Opción 4: App Bundle (Para Google Play Store) 🏪

Si planeas publicar en Google Play:

```bash
cd inventario_app
flutter build appbundle --release
```

El archivo se genera en:
```
build/app/outputs/bundle/release/app-release.aab
```

---

## 🔧 Antes de Construir (Opcional pero Recomendado)

### 1. Agregar tu logo

Coloca tu logo en:
```
inventario_app/assets/images/sublirium_logo.png
```

### 2. Cambiar el nombre de la app

Edita `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:label="Sublirium Inventario"
    ...>
```

### 3. Cambiar el ícono de la app

Reemplaza los íconos en:
```
android/app/src/main/res/mipmap-*/ic_launcher.png
```

O usa el paquete `flutter_launcher_icons`:
```bash
flutter pub add flutter_launcher_icons
```

---

## 📋 Comandos Rápidos

```bash
# Ver dispositivos conectados
flutter devices

# Instalar en modo release (rápido)
flutter run --release

# Generar APK universal
flutter build apk --release

# Generar APKs por arquitectura (más pequeños)
flutter build apk --split-per-abi

# Generar App Bundle (para Play Store)
flutter build appbundle --release

# Instalar APK con ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# Copiar APK a descargas del teléfono
adb push build/app/outputs/flutter-apk/app-release.apk /sdcard/Download/
```

---

## ⚠️ Solución de Problemas

### Error: "No devices found"
```bash
# Verificar que ADB detecta el dispositivo
adb devices

# Si no aparece, reconectar USB y aceptar depuración
```

### Error: "Gradle build failed"
```bash
# Limpiar y reconstruir
cd inventario_app
flutter clean
flutter pub get
flutter build apk --release
```

### Error: "Insufficient storage"
- Libera espacio en tu dispositivo
- O genera APK dividido (más pequeño)

### La app no se instala
- Desinstala versiones anteriores
- Verifica que "Instalar apps desconocidas" esté habilitado

---

## 🎯 Recomendación

**Para uso personal:**
```bash
cd inventario_app
flutter build apk --split-per-abi
```
Luego instala `app-arm64-v8a-release.apk` en tu teléfono.

**Para compartir con otros:**
```bash
cd inventario_app
flutter build apk --release
```
Comparte el archivo `app-release.apk`.

---

## 📱 Tamaño Aproximado

- APK universal: ~45-50 MB
- APK arm64-v8a: ~22-25 MB
- APK armeabi-v7a: ~20-22 MB

---

## ✅ Verificar la Instalación

Una vez instalada:
1. Busca "Sublirium Inventario" en tu lista de apps
2. Abre la app
3. Verifica que los colores y el logo se vean correctamente
4. Prueba la búsqueda de categorías

¡Tu app Sublirium está lista para usar! 🚀✨
