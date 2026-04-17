import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/features/projects/presentation/widgets/stats_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('StatsCard', () {
    testWidgets('renders visiobooks count', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const StatsCard(visiobooksCount: 5, textsCount: 12)),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders texts count', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const StatsCard(visiobooksCount: 5, textsCount: 12)),
      );

      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('renders VisioBooks label', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const StatsCard(visiobooksCount: 0, textsCount: 0)),
      );

      expect(find.text('VisioBooks'), findsOneWidget);
    });

    testWidgets('renders Textes label', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const StatsCard(visiobooksCount: 0, textsCount: 0)),
      );

      expect(find.text('Textes'), findsOneWidget);
    });

    testWidgets('renders with zero counts', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const StatsCard(visiobooksCount: 0, textsCount: 0)),
      );

      expect(find.text('0'), findsNWidgets(2));
    });

    testWidgets('renders StatsCard widget type', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const StatsCard(visiobooksCount: 3, textsCount: 7)),
      );

      expect(find.byType(StatsCard), findsOneWidget);
    });
  });
}
