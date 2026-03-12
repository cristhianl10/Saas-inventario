#!/bin/bash

# Script para construir la app Android de Sublirium Inventario
# Uso: ./build_android.sh [opcion]

echo "🚀 Construyendo Sublirium Inventario para Android..."
echo ""

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar el menú
show_menu() {
    echo "${BLUE}Selecciona una opción:${NC}"
    echo "1) APK Universal (para compartir, ~45MB)"
    echo "2) APK Optimizado (más pequeño, ~22MB)"
    echo "3) Instalar directamente en dispositivo conectado"
    echo "4) App Bundle (para Google Play Store)"
    echo "5) Limpiar y reconstruir"
    echo "0) Salir"
    echo ""
}

# Función para construir APK universal
build_universal() {
    echo "${YELLOW}Construyendo APK universal...${NC}"
    flutter build apk --release
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "${GREEN}✅ APK construido exitosamente!${NC}"
        echo "📍 Ubicación: build/app/outputs/flutter-apk/app-release.apk"
        echo "📦 Tamaño: $(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)"
        echo ""
        echo "Para instalar en tu dispositivo:"
        echo "  adb install build/app/outputs/flutter-apk/app-release.apk"
    else
        echo "${YELLOW}❌ Error al construir APK${NC}"
    fi
}

# Función para construir APK optimizado
build_optimized() {
    echo "${YELLOW}Construyendo APKs optimizados por arquitectura...${NC}"
    flutter build apk --split-per-abi
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "${GREEN}✅ APKs construidos exitosamente!${NC}"
        echo "📍 Ubicación: build/app/outputs/flutter-apk/"
        echo ""
        echo "APKs generados:"
        ls -lh build/app/outputs/flutter-apk/*.apk | awk '{print "  " $9 " - " $5}'
        echo ""
        echo "${BLUE}Recomendado: app-arm64-v8a-release.apk (para la mayoría de teléfonos)${NC}"
    else
        echo "${YELLOW}❌ Error al construir APKs${NC}"
    fi
}

# Función para instalar directamente
install_direct() {
    echo "${YELLOW}Verificando dispositivos conectados...${NC}"
    flutter devices
    echo ""
    
    read -p "¿Continuar con la instalación? (s/n): " confirm
    if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
        echo "${YELLOW}Instalando en dispositivo...${NC}"
        flutter run --release
    else
        echo "Instalación cancelada."
    fi
}

# Función para construir App Bundle
build_bundle() {
    echo "${YELLOW}Construyendo App Bundle para Google Play...${NC}"
    flutter build appbundle --release
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "${GREEN}✅ App Bundle construido exitosamente!${NC}"
        echo "📍 Ubicación: build/app/outputs/bundle/release/app-release.aab"
        echo "📦 Tamaño: $(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)"
    else
        echo "${YELLOW}❌ Error al construir App Bundle${NC}"
    fi
}

# Función para limpiar y reconstruir
clean_build() {
    echo "${YELLOW}Limpiando proyecto...${NC}"
    flutter clean
    echo "${YELLOW}Obteniendo dependencias...${NC}"
    flutter pub get
    echo ""
    echo "${GREEN}✅ Proyecto limpio y listo para construir${NC}"
    echo ""
    show_menu
    read -p "Selecciona una opción: " option
    handle_option $option
}

# Función para manejar la opción seleccionada
handle_option() {
    case $1 in
        1)
            build_universal
            ;;
        2)
            build_optimized
            ;;
        3)
            install_direct
            ;;
        4)
            build_bundle
            ;;
        5)
            clean_build
            ;;
        0)
            echo "👋 ¡Hasta luego!"
            exit 0
            ;;
        *)
            echo "${YELLOW}Opción inválida${NC}"
            ;;
    esac
}

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo "${YELLOW}❌ Error: Debes ejecutar este script desde el directorio inventario_app${NC}"
    exit 1
fi

# Si se pasa un argumento, ejecutar directamente
if [ $# -eq 1 ]; then
    handle_option $1
else
    # Mostrar menú interactivo
    show_menu
    read -p "Selecciona una opción: " option
    handle_option $option
fi

echo ""
echo "${GREEN}¡Proceso completado! 🎉${NC}"
