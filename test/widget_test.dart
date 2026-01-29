import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/main.dart';

void main() {
  testWidgets('App should start without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const VisioBookApp());
    await tester.pumpAndSettle();

    // L'app devrait demarrer sans erreur
    expect(find.byType(VisioBookApp), findsOneWidget);
  });
}
