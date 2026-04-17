import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    EnvironmentConfig.useMockData = true;
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
  });

  testWidgets('VisioBookApp renders without error', (tester) async {
    EnvironmentConfig.useMockData = true;
    await tester.pumpWidget(const VisioBookApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
