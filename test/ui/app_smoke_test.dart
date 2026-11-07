import 'package:finanzas/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('arranca y muestra el título', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FinanzasApp()));
    await tester.pumpAndSettle();

    expect(find.text('Mis cuentas'), findsOneWidget);
  });
}
