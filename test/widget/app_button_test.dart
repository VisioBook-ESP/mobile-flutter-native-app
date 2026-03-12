import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/core/widgets/app_button.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('AppButton', () {
    testWidgets('renders with given text', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(AppButton(text: 'Click Me', onPressed: () {})),
      );

      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('onPressed callback fires on tap', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        wrapWithMaterial(
          AppButton(text: 'Tap', onPressed: () => pressed = true),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('loading state shows CircularProgressIndicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          AppButton(text: 'Loading', onPressed: () {}, isLoading: true),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('outline variant renders with border', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          AppButton(
            text: 'Outline',
            onPressed: () {},
            variant: AppButtonVariant.outline,
          ),
        ),
      );

      expect(find.text('Outline'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const AppButton(text: 'Disabled', onPressed: null)),
      );

      expect(find.text('Disabled'), findsOneWidget);
    });
  });
}
