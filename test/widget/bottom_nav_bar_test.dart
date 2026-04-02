import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:visiobook_mobile/core/widgets/bottom_nav_bar.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: const SizedBox.expand(), bottomNavigationBar: child),
    );
  }

  group('BottomNavBar', () {
    testWidgets('renders 5 items (4 nav + 1 play button)', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(BottomNavBar(currentIndex: 0, onTap: (_) {})),
      );

      expect(find.byType(Icon), findsNWidgets(5));
    });

    testWidgets('onTap callback fires with correct index', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        wrapWithMaterial(
          BottomNavBar(currentIndex: 0, onTap: (index) => tappedIndex = index),
        ),
      );

      await tester.tap(find.byIcon(LucideIcons.home));
      await tester.pump();
      expect(tappedIndex, 0);
    });

    testWidgets('onAddTap callback fires when plus button tapped', (
      tester,
    ) async {
      bool addTapped = false;

      await tester.pumpWidget(
        wrapWithMaterial(
          BottomNavBar(
            currentIndex: 0,
            onTap: (_) {},
            onAddTap: () => addTapped = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pump();
      expect(addTapped, isTrue);
    });

    testWidgets('play button fires onTap with index 2', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        wrapWithMaterial(
          BottomNavBar(currentIndex: 0, onTap: (index) => tappedIndex = index),
        ),
      );

      await tester.tap(find.byIcon(LucideIcons.playCircle));
      await tester.pump();
      expect(tappedIndex, 2);
    });
  });
}
