#!/bin/bash

# Script de Build Optimizado para Sublirium Inventario
# Genera APKs pequeños y rápidos

echo "🚀 Construyendo Sublirium Inventario (Optimizado)..."
echo ""

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo "${YELLOW}❌ Error: Ejecuta este script desde inventario_app/${NC}"
    exit 1
fi

# Paso 1: Limpiar builds anteriores
echo "${BLUE}🧹 Limpiando builds anteriores...${NC}"
flutter clean

# Paso 2: Obtener dependencias
echo "${BLUE}📦 Obteniendo dependencias...${NC}"
flutter pub get

# Paso 3: Analizar código
echo "${BLUE}🔍 Analizando código...${NC}"
dart fix --apply

# Paso 4: Build optimizado
echo "${BLUE}⚙️  Construyendo APKs optimizados...${NC}"
echo "   - Minificación activada"
echo "   - Recursos no usados eliminados"
echo "   - Código ofuscado"
echo "   - APKs divididos por arquitectura"
echo ""

flutter build apk --release \
  --split-per-abi \
  --obfuscate \
  --split-debug-info=./debug-info \
  --tree-shake-icons

# Verificar si el build fue exitoso
if [ $? -eq 0 ]; then
    echo ""
    echo "${GREEN}✅ Build completado exitosamente!${NC}"
    echo ""
    echo "${BLUE}📍 APKs generados:${NC}"
    echo ""
    
    # Mostrar tamaños
    cd build/app/outputs/flutter-apk/
    for apk in *.apk; do
        size=$(du -h "$apk" | cut -f1)
        echo "   📦 $apk - ${GREEN}$size${NC}"
    done
    cd ../../../../
    
    echo ""
    echo "${BLUE}💡 Recomendaciones:${NC}"
    echo "   • Para la mayoría de dispositivos: ${GREEN}app-arm64-v8a-release.apk${NC}"
    echo "   • Para dispositivos antiguos: app-armeabi-v7a-release.apk"
    echo ""
    echo "${BLUE}📲 Para instalar:${NC}"
    echo "   adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
    echo ""
    
    # Calcular reducción de tamaño
    arm64_size=$(du -b build/app/outputs/flutter-apk/app-arm64-v8a-release.apk 2>/dev/null | cut -f1)
    if [ ! -z "$arm64_size" ]; then
        original_estimate=23068672  # ~22 MB estimado
        reduction=$(( (original_estimate - arm64_size) * 100 / original_estimate ))
        echo "${GREEN}🎉 Reducción estimada de tamaño: ~${reduction}%${NC}"
    fi
    
else
    echo ""
    echo "${YELLOW}❌ Error en el build${NC}"
    exit 1
fi

echo ""
echo "${GREEN}¡Listo para instalar! 🚀✨${NC}"
