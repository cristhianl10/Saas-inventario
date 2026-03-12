# 🎨 Instrucciones para Personalizar tu App Sublirium

## ✅ Cambios Realizados

He adaptado toda la interfaz de tu app de inventario con los colores vibrantes de Sublirium:

### Colores Aplicados:
- **Cyan**: `#2ABDE8` (00BCD4)
- **Púrpura**: `#7B2FBE` (9C27B0)
- **Rosa/Magenta**: `#D81B8A` (E91E63)
- **Naranja**: `#FF6B35` (FF9800)
- **Amarillo**: `#FFC107` (FFEB3B)

### Elementos Actualizados:
- ✨ Gradiente principal en el AppBar (cyan → púrpura → rosa)
- 🎯 Botones flotantes con color rosa de Sublirium
- 📱 Navegación inferior con color rosa cuando está activa
- 🎨 Tema general de la app con paleta Sublirium

## 📸 Agregar tu Logo Circular

### Paso 1: Preparar el Logo
1. Toma tu logo de Sublirium (el circular con las letras "S" en gradiente)
2. Asegúrate que sea una imagen cuadrada (recomendado: 512x512px o mayor)
3. Formato: PNG con fondo transparente

### Paso 2: Colocar el Logo
Copia tu archivo de logo a esta ubicación:
```
inventario_app/assets/images/sublirium_logo.png
```

### Paso 3: Ejecutar la App
```bash
cd inventario_app
flutter pub get
flutter run
```

## 🎯 Dónde Aparece el Logo

El logo aparecerá de forma circular en:
- Esquina superior derecha del AppBar principal
- Con un borde blanco elegante
- Sombra suave para darle profundidad

Si no colocas el logo, la app mostrará una "S" con el gradiente de Sublirium como fallback.

## 🚀 Comandos Útiles

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Ejecutar en Chrome (web)
flutter run -d chrome

# Ejecutar en Android
flutter run -d android

# Ver dispositivos disponibles
flutter devices

# Compilar para release
flutter build apk  # Android
flutter build web  # Web
```

## 🎨 Personalización Adicional

Si quieres ajustar más colores, edita el archivo:
```
inventario_app/lib/config/app_theme.dart
```

Ahí encontrarás todos los colores de Sublirium definidos y podrás modificarlos fácilmente.

## 📱 Resultado Final

Tu app ahora refleja completamente la identidad visual de Sublirium:
- Colores vibrantes y modernos
- Logo circular profesional
- Interfaz coherente con tu marca
- ¡Lista para impresionar! 🚀
