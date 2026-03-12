import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/core/widgets/skeleton_loader.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('SkeletonLoader', () {
    testWidgets('renders with given dimensions', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const SkeletonLoader(width: 200, height: 50)),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });

  group('SkeletonProjectCard', () {
    testWidgets('renders', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const SkeletonProjectCard()));

      expect(find.byType(SkeletonProjectCard), findsOneWidget);
    });
  });

  group('SkeletonListItem', () {
    testWidgets('renders', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const SkeletonListItem()));

      expect(find.byType(SkeletonListItem), findsOneWidget);
    });
  });
}
