import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/core/widgets/bottom_nav_bar.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(home: Scaffold(bottomNavigationBar: child));
  }

  group('BottomNavBar', () {
    testWidgets('renders 5 items (4 nav + 1 add button)', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(BottomNavBar(currentIndex: 0, onTap: (_) {})),
      );

      // 4 nav icons + 1 add button icon = 5 Icon widgets
      expect(find.byType(Icon), findsNWidgets(5));
    });

    testWidgets('onTap callback fires with correct index', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        wrapWithMaterial(
          BottomNavBar(currentIndex: 0, onTap: (index) => tappedIndex = index),
        ),
      );

      // Find all GestureDetector widgets inside the nav bar
      // The icons are wrapped in SizedBox(48x48) inside GestureDetectors
      final icons = find.byType(Icon);
      expect(icons, findsNWidgets(5));

      // Tap the last icon (profile, index 4)
      await tester.tap(icons.at(3));
      await tester.pump();
      expect(tappedIndex, 3);

      // Tap the first icon (home, index 0)
      await tester.tap(icons.at(0));
      await tester.pump();
      expect(tappedIndex, 0);
    });

    testWidgets('onAddTap callback fires when add button tapped', (
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

      // The add button is the 3rd item (middle), which is a Container
      // with a white background and plus icon
      // Find it by its container size (56x56)
      final addButtonIcon = find.byType(Icon).at(2);
      await tester.tap(addButtonIcon);
      await tester.pump();

      expect(addTapped, isTrue);
    });
  });
}
