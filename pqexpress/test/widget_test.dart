// ============================================================
// PQEXPRESS - Test de Widget Básico
// Verifica que la aplicación se inicie correctamente
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:pqexpress/main.dart';

void main() {
  testWidgets('App should start without errors', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const PQExpressApp());

    // Verify the splash screen loads (can customize based on actual app)
    expect(find.text('PQExpress'), findsWidgets);
  });
}
