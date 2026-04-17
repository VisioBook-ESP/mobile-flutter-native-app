import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/core/services/sse_service.dart';

void main() {
  group('SseStepDetail', () {
    test('fromJson parses correctly', () {
      final json = {'step': 'analysis', 'status': 'completed', 'progress': 100};

      final detail = SseStepDetail.fromJson(json);

      expect(detail.step, 'analysis');
      expect(detail.status, 'completed');
      expect(detail.progress, 100);
    });

    test('fromJson handles missing fields with defaults', () {
      final detail = SseStepDetail.fromJson(<String, dynamic>{});

      expect(detail.step, '');
      expect(detail.status, '');
      expect(detail.progress, 0);
    });
  });

  group('SseEvent', () {
    test('fromJson parses full event', () {
      final json = {
        'executionId': 'exec-123',
        'status': 'running',
        'currentStep': 'image_generation',
        'progress': 45,
        'steps': [
          {'step': 'analysis', 'status': 'completed', 'progress': 100},
          {'step': 'image_generation', 'status': 'running', 'progress': 30},
        ],
      };

      final event = SseEvent.fromJson(json);

      expect(event.executionId, 'exec-123');
      expect(event.status, 'running');
      expect(event.currentStep, 'image_generation');
      expect(event.progress, 45);
      expect(event.steps, hasLength(2));
      expect(event.steps[0].step, 'analysis');
      expect(event.steps[0].status, 'completed');
      expect(event.steps[0].progress, 100);
      expect(event.steps[1].step, 'image_generation');
      expect(event.steps[1].status, 'running');
      expect(event.steps[1].progress, 30);
    });

    test('fromJson handles missing steps list', () {
      final json = {
        'executionId': 'exec-456',
        'status': 'running',
        'currentStep': 'analysis',
        'progress': 10,
      };

      final event = SseEvent.fromJson(json);

      expect(event.executionId, 'exec-456');
      expect(event.steps, isEmpty);
    });

    test('fromJson handles null currentStep', () {
      final json = {
        'executionId': 'exec-789',
        'status': 'completed',
        'currentStep': null,
        'progress': 100,
        'steps': <dynamic>[],
      };

      final event = SseEvent.fromJson(json);

      expect(event.currentStep, isNull);
    });

    test('isTerminal true for completed/failed/cancelled', () {
      for (final status in ['completed', 'failed', 'cancelled']) {
        final event = SseEvent.fromJson({
          'executionId': 'exec-t',
          'status': status,
          'progress': 100,
        });

        expect(event.isTerminal, isTrue, reason: '$status should be terminal');
      }
    });

    test('isTerminal false for running', () {
      final event = SseEvent.fromJson({
        'executionId': 'exec-r',
        'status': 'running',
        'progress': 50,
      });

      expect(event.isTerminal, isFalse);
    });
  });
}
