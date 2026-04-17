import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    test('instance is a singleton', () {
      final a = NotificationService.instance;
      final b = NotificationService.instance;
      expect(identical(a, b), isTrue);
    });

    test('init does not throw', () async {
      // init may fail silently on test platform (no native plugin),
      // but it should not throw.
      await expectLater(NotificationService.instance.init(), completes);
    });

    test('requestPermission does not throw', () async {
      await expectLater(
        NotificationService.instance.requestPermission(),
        completes,
      );
    });

    test(
      'showGenerationComplete does not throw when not initialized',
      () async {
        // Create a fresh-ish service — but since it is a singleton and init
        // may or may not have succeeded, we just verify no exception escapes.
        await expectLater(
          NotificationService.instance.showGenerationComplete('TestProject'),
          completes,
        );
      },
    );

    test('showGenerationFailed does not throw', () async {
      await expectLater(
        NotificationService.instance.showGenerationFailed('TestProject'),
        completes,
      );
    });

    test('showIngestionComplete does not throw', () async {
      await expectLater(
        NotificationService.instance.showIngestionComplete('file.pdf'),
        completes,
      );
    });

    test('showIngestionFailed does not throw', () async {
      await expectLater(
        NotificationService.instance.showIngestionFailed('file.pdf'),
        completes,
      );
    });
  });
}
