import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/main.dart';

void main() {
  testWidgets('App should start without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const VisioBookApp());

    // Pump pour laisser l'app s'initialiser
    await tester.pump();
    await tester.pump();

    // L'app devrait demarrer sans erreur
    expect(find.byType(VisioBookApp), findsOneWidget);
  });
}
