import re

def fix_styles_and_spacing():
    with open('inventario_app/lib/screens/tabla_precios_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Revert Texts and Icons back to Colors.black
    content = content.replace("color: isDark ? Colors.white : Colors.black", "color: Colors.black")

    # 2. Revert Backgrounds back to SubliriumColors.cardBackground
    content = content.replace("color: isDark ? Theme.of(context).colorScheme.surface : SubliriumColors.cardBackground", "color: SubliriumColors.cardBackground")
    content = content.replace("dropdownColor: isDark ? Theme.of(context).colorScheme.surface : SubliriumColors.cardBackground", "dropdownColor: SubliriumColors.cardBackground")

    # 3. Fix the "espaciote innecesario" (SizedBox height 100 in loop)
    # The code looks like this:
    #             ...productos.map((producto) => _buildProductoItem(producto)),
    #             const SizedBox(height: 100),
    #           ],
    content = content.replace('''            ...productos.map((producto) => _buildProductoItem(producto)),
            const SizedBox(height: 100),
          ],''', '''            ...productos.map((producto) => _buildProductoItem(producto)),
          ],''')

    # 4. Add the padding to ListView.builder
    content = content.replace('''    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: categoriasOrdenadas.length,''', '''    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: categoriasOrdenadas.length,''')

    # Remove the `final isDark = Theme.of(context)...` if we don't need it anywhere else?
    # Actually it's fine to leave them, dart compiler will optimize them away or we can just ignore warnings about unused vars. 
    # But let's clean them up using regex if they are no longer used.
    # We will just write the file back. Unused variables will be handled by flutter analyze if necessary but they won't break the build.
    
    with open('inventario_app/lib/screens/tabla_precios_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_styles_and_spacing()
