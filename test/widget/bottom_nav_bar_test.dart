import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/core/widgets/bottom_nav_bar.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(home: Scaffold(bottomNavigationBar: child));
  }

  group('BottomNavBar', () {
    testWidgets('renders 5 items (3 nav + 1 play + 1 add)', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(BottomNavBar(currentIndex: 0, onTap: (_) {})),
      );

      // 3 nav icons + 1 play button icon + 1 add icon = 5 Icon widgets
      expect(find.byType(Icon), findsNWidgets(5));
    });

    testWidgets('onTap callback fires with correct index', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        wrapWithMaterial(
          BottomNavBar(currentIndex: 0, onTap: (index) => tappedIndex = index),
        ),
      );

      final icons = find.byType(Icon);
      expect(icons, findsNWidgets(5));

      // Tap the last icon (profile, index 4)
      await tester.tap(icons.at(4));
      await tester.pump();
      expect(tappedIndex, 4);

      // Tap the first icon (home, index 0)
      await tester.tap(icons.at(0));
      await tester.pump();
      expect(tappedIndex, 0);
    });

    testWidgets('onPlayTap callback fires when play button tapped', (
      tester,
    ) async {
      bool playTapped = false;

      await tester.pumpWidget(
        wrapWithMaterial(
          BottomNavBar(
            currentIndex: 0,
            onTap: (_) {},
            onPlayTap: () => playTapped = true,
          ),
        ),
      );

      // The play button is the 3rd item (middle)
      final playButtonIcon = find.byType(Icon).at(2);
      await tester.tap(playButtonIcon);
      await tester.pump();

      expect(playTapped, isTrue);
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

      // The add button is the 4th item
      final addButtonIcon = find.byType(Icon).at(3);
      await tester.tap(addButtonIcon);
      await tester.pump();

      expect(addTapped, isTrue);
    });
  });
}
