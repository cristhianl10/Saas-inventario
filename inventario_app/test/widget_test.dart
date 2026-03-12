import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const InventarioApp());
    expect(find.text('Categorías'), findsOneWidget);
  });
}
