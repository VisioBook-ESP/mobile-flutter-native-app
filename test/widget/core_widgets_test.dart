import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/core/widgets/animated_gradient_background.dart';
import 'package:visiobook_mobile/core/widgets/app_input.dart';
import 'package:visiobook_mobile/core/widgets/glass_container.dart';
import 'package:visiobook_mobile/core/widgets/gradient_background.dart';
import 'package:visiobook_mobile/core/widgets/skeleton_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('GradientBackground', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const GradientBackground(child: Text('Hello'))),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders GradientBackground type', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const GradientBackground(child: SizedBox())),
      );

      expect(find.byType(GradientBackground), findsOneWidget);
    });
  });

  group('GlassContainer', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const GlassContainer(child: Text('Glass'))),
      );

      expect(find.text('Glass'), findsOneWidget);
    });

    testWidgets('renders GlassContainer type', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const GlassContainer(child: SizedBox())),
      );

      expect(find.byType(GlassContainer), findsOneWidget);
    });

    testWidgets('renders with custom padding and margin', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          const GlassContainer(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(8),
            child: Text('Padded'),
          ),
        ),
      );

      expect(find.text('Padded'), findsOneWidget);
    });
  });

  group('AnimatedGradientBackground', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          const AnimatedGradientBackground(child: Text('Animated')),
        ),
      );

      expect(find.text('Animated'), findsOneWidget);
    });

    testWidgets('renders AnimatedGradientBackground type', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const AnimatedGradientBackground(child: SizedBox())),
      );

      expect(find.byType(AnimatedGradientBackground), findsOneWidget);
    });
  });

  group('AppInput', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const AppInput(label: 'Email')));

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('renders with placeholder', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const AppInput(placeholder: 'Enter your email')),
      );

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('renders AppInput type', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const AppInput()));

      expect(find.byType(AppInput), findsOneWidget);
    });

    testWidgets('renders in disabled state', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const AppInput(label: 'Disabled', enabled: false)),
      );

      expect(find.text('Disabled'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('renders with prefix and suffix icons', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          const AppInput(
            label: 'Password',
            prefixIcon: Icon(Icons.lock),
            suffixIcon: Icon(Icons.visibility),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });

  group('SkeletonProjectCard', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const SkeletonProjectCard()));

      expect(find.byType(SkeletonProjectCard), findsOneWidget);
    });
  });

  group('SkeletonTextDetail', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          const SingleChildScrollView(child: SkeletonTextDetail()),
        ),
      );

      expect(find.byType(SkeletonTextDetail), findsOneWidget);
    });
  });

  group('SkeletonProjectView', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const SkeletonProjectView()));

      expect(find.byType(SkeletonProjectView), findsOneWidget);
    });
  });

  group('SkeletonDashboard', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const SkeletonDashboard()));

      expect(find.byType(SkeletonDashboard), findsOneWidget);
    });
  });
}
