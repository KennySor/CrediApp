import 'package:flutter_test/flutter_test.dart';
import 'package:crediapp/main.dart';

void main() {
  testWidgets('La app abre en el login', (WidgetTester tester) async {
    await tester.pumpWidget(const CrediApp());

    expect(find.text('Iniciar sesión'), findsWidgets);
  });
}