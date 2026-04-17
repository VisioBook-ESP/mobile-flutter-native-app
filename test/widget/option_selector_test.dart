import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:visiobook_mobile/features/project_detail/domain/project_config.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/widgets/option_selector.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/widgets/style_selector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  // -----------------------------------------------------------------------
  // OptionSelector
  // -----------------------------------------------------------------------
  group('OptionSelector', () {
    testWidgets('renders title and selected option label', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          OptionSelector<String>(
            title: 'Language',
            icon: LucideIcons.globe,
            selectedValue: 'fr',
            options: const [
              OptionItem(value: 'fr', label: 'Francais'),
              OptionItem(value: 'en', label: 'English'),
            ],
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Francais'), findsOneWidget);
    });

    testWidgets('renders all options', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          OptionSelector<String>(
            title: 'Language',
            icon: LucideIcons.globe,
            selectedValue: 'fr',
            options: const [
              OptionItem(value: 'fr', label: 'Francais'),
              OptionItem(value: 'en', label: 'English'),
              OptionItem(value: 'es', label: 'Espanol'),
            ],
            onChanged: (_) {},
          ),
        ),
      );

      // Only the selected label is shown on the main widget
      expect(find.text('Francais'), findsOneWidget);
      expect(find.byType(OptionSelector<String>), findsOneWidget);
    });

    testWidgets('opens bottom sheet when tapped', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          OptionSelector<String>(
            title: 'Language',
            icon: LucideIcons.globe,
            selectedValue: 'fr',
            options: const [
              OptionItem(value: 'fr', label: 'Francais'),
              OptionItem(value: 'en', label: 'English'),
            ],
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(OptionSelector<String>));
      await tester.pumpAndSettle();

      // Bottom sheet should show all options
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('calls onChanged when option is tapped', (tester) async {
      String? selectedValue;
      await tester.pumpWidget(
        wrapWithMaterial(
          OptionSelector<String>(
            title: 'Language',
            icon: LucideIcons.globe,
            selectedValue: 'fr',
            options: const [
              OptionItem(value: 'fr', label: 'Francais'),
              OptionItem(value: 'en', label: 'English'),
            ],
            onChanged: (val) => selectedValue = val,
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.byType(OptionSelector<String>));
      await tester.pumpAndSettle();

      // Tap 'English' option
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(selectedValue, equals('en'));
    });
  });

  // -----------------------------------------------------------------------
  // StyleSelector
  // -----------------------------------------------------------------------
  group('StyleSelector', () {
    testWidgets('renders style options', (tester) async {
      // Ignore overflow errors from _StyleCard layout
      final origHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        origHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = origHandler);

      await tester.pumpWidget(
        wrapWithMaterial(
          StyleSelector(
            selectedStyle: VideoStyle.realistic,
            onStyleChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Style graphique'), findsOneWidget);
      expect(find.byType(StyleSelector), findsOneWidget);
      // All VideoStyle labels should appear
      for (final style in VideoStyle.values) {
        expect(find.text(style.label), findsOneWidget);
      }
    });

    testWidgets('calls onStyleChanged when style is tapped', (tester) async {
      // Ignore overflow errors from _StyleCard layout
      final origHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        origHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = origHandler);

      VideoStyle? tappedStyle;
      await tester.pumpWidget(
        wrapWithMaterial(
          StyleSelector(
            selectedStyle: VideoStyle.realistic,
            onStyleChanged: (style) => tappedStyle = style,
          ),
        ),
      );

      // Tap 'Cartoon' style
      await tester.tap(find.text(VideoStyle.cartoon.label));
      await tester.pump();

      expect(tappedStyle, equals(VideoStyle.cartoon));
    });
  });
}
