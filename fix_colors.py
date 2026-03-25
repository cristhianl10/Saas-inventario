import re

def fix_colors():
    with open('inventario_app/lib/screens/tabla_precios_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Inject isDark into build() if not present
    if "final isDark =" not in content.split("Widget build(BuildContext context) {")[1].split("return Scaffold(")[0]:
        content = re.sub(
            r'(Widget build\(BuildContext context\) \{)(\n\s*return Scaffold\()',
            r'\1\n    final isDark = Theme.of(context).brightness == Brightness.dark;\2',
            content
        )

    # 2. Inject isDark into _buildTablaPrecios() if not present
    if "final isDark =" not in content.split("Widget _buildTablaPrecios() {")[1].split("return Container(")[0]:
        content = re.sub(
            r'(Widget _buildTablaPrecios\(\) \{)(\n\s*final precioBase = _precioBase;)',
            r'\1\n    final isDark = Theme.of(context).brightness == Brightness.dark;\2',
            content
        )

    # 3. Inject isDark into _buildTodosLosProductos() if not present
    if "final isDark =" not in content.split("Widget _buildTodosLosProductos() {")[1].split("return ListView.separated(")[0]:
        content = re.sub(
            r'(Widget _buildTodosLosProductos\(\) \{)(\n\s*final productos = _productosAgrupados;)',
            r'\1\n    final isDark = Theme.of(context).brightness == Brightness.dark;\2',
            content
        )

    # 4. Replace hardcoded Colors.black with our dynamic color
    # Make sure we don't match Colors.black.withValues
    pattern1 = r'color:\s*Colors\.black\b(?!\.withValues)'
    content = re.sub(pattern1, 'color: isDark ? Colors.white : Colors.black', content)

    # 5. Fix specific card backgrounds that are forcefully white
    content = re.sub(r'color:\s*SubliriumColors\.cardBackground', 'color: isDark ? Theme.of(context).colorScheme.surface : SubliriumColors.cardBackground', content)

    # 6. Fix specific dropdownColor that is forcefully white
    content = re.sub(r'dropdownColor:\s*SubliriumColors\.cardBackground', 'dropdownColor: isDark ? Theme.of(context).colorScheme.surface : SubliriumColors.cardBackground', content)

    # 7. Write back
    with open('inventario_app/lib/screens/tabla_precios_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_colors()
