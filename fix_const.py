import re

def fix_const():
    with open('inventario_app/lib/screens/tabla_precios_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Fix `const TextStyle(... isDark ...)`
    # This might span multiple lines, but usually `const TextStyle` is on the same line as `style:` or one line above.
    # Let's just find `const TextStyle` and remove `const ` if `isDark` is inside its parentheses.
    # Since regex for balanced parentheses is hard, let's just remove `const ` before `TextStyle` globally if it's near `isDark`.
    # Actually, let's just remove `const ` from `const TextStyle`, `const Text`, `const Icon` if `isDark` is found within the next 200 characters without encountering another widget.
    
    # A safer approach:
    content = content.replace('const Icon(Icons.wifi_off, size: 48, color: isDark ? Colors.white : Colors.black),', 'Icon(Icons.wifi_off, size: 48, color: isDark ? Colors.white : Colors.black),')
    content = content.replace("const Text('Error de conexión', style: TextStyle(color: isDark ? Colors.white : Colors.black)),", "Text('Error de conexión', style: TextStyle(color: isDark ? Colors.white : Colors.black)),")
    content = content.replace('style: const TextStyle(color: isDark ? Colors.white : Colors.black),', 'style: TextStyle(color: isDark ? Colors.white : Colors.black),')
    
    # Text('Filtros')
    content = content.replace('''const Text(
                        'Filtros',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),''', '''Text(
                        'Filtros',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),''')

    # Dropdown items
    content = content.replace('style: const TextStyle(color: isDark ? Colors.white : Colors.black)', 'style: TextStyle(color: isDark ? Colors.white : Colors.black)')

    # Table text 1
    content = content.replace('''style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black,
                          ),''', '''style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black,
                          ),''')
                          
    content = content.replace('''style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: isDark ? Colors.white : Colors.black,
                          ),''', '''style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: isDark ? Colors.white : Colors.black,
                          ),''')
                          
    # Check for any remaining `const Icon(` that use isDark
    import re
    content = re.sub(r'const\s+Icon\(([^)]*isDark[^)]*)\)', r'Icon(\1)', content)

    # Check for any remaining `const Text(` that use isDark on the same line
    content = re.sub(r'const\s+Text\(([^)]*isDark[^)]*)\)', r'Text(\1)', content)

    with open('inventario_app/lib/screens/tabla_precios_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_const()
