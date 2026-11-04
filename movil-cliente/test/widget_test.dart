import 'package:flutter_test/flutter_test.dart';

import 'package:movil_cliente/main.dart';

void main() {
  testWidgets('La aplicación inicia en la pantalla de login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('SRLN'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
