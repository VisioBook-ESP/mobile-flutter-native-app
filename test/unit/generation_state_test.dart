import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/features/generation/domain/generation_state.dart';
import 'package:visiobook_mobile/features/generation/domain/ingestion_state.dart';

void main() {
  group('GenerationStep', () {
    test('fromString with all valid values', () {
      expect(GenerationStep.fromString('analysis'), GenerationStep.analysis);
      expect(
        GenerationStep.fromString('reference_generation'),
        GenerationStep.referenceGeneration,
      );
      expect(
        GenerationStep.fromString('image_generation'),
        GenerationStep.imageGeneration,
      );
      expect(
        GenerationStep.fromString('audio_generation'),
        GenerationStep.audioGeneration,
      );
      expect(GenerationStep.fromString('assembly'), GenerationStep.assembly);
    });

    test(
      'fromString backward compat (images -> imageGeneration, audio -> audioGeneration)',
      () {
        expect(
          GenerationStep.fromString('images'),
          GenerationStep.imageGeneration,
        );
        expect(
          GenerationStep.fromString('audio'),
          GenerationStep.audioGeneration,
        );
      },
    );

    test('fromString unknown defaults to analysis', () {
      expect(GenerationStep.fromString('unknown'), GenerationStep.analysis);
      expect(GenerationStep.fromString(''), GenerationStep.analysis);
    });

    test('label returns correct French labels', () {
      expect(GenerationStep.analysis.label, 'Analyse');
      expect(GenerationStep.referenceGeneration.label, 'Références');
      expect(GenerationStep.imageGeneration.label, 'Images');
      expect(GenerationStep.audioGeneration.label, 'Audio');
      expect(GenerationStep.assembly.label, 'Assemblage');
    });

    test('description returns non-empty strings', () {
      for (final step in GenerationStep.values) {
        expect(step.description, isNotEmpty);
      }
    });

    test('weight values sum to roughly 1.0', () {
      final sum = GenerationStep.values.fold<double>(
        0.0,
        (acc, step) => acc + step.weight,
      );
      expect(sum, closeTo(1.0, 0.01));
    });
  });

  group('WorkflowStatus', () {
    test('fromString all valid values', () {
      expect(WorkflowStatus.fromString('pending'), WorkflowStatus.pending);
      expect(
        WorkflowStatus.fromString('processing'),
        WorkflowStatus.processing,
      );
      expect(WorkflowStatus.fromString('running'), WorkflowStatus.running);
      expect(WorkflowStatus.fromString('completed'), WorkflowStatus.completed);
      expect(WorkflowStatus.fromString('failed'), WorkflowStatus.failed);
      expect(WorkflowStatus.fromString('cancelled'), WorkflowStatus.cancelled);
    });

    test('fromString unknown defaults to pending', () {
      expect(WorkflowStatus.fromString('unknown'), WorkflowStatus.pending);
      expect(WorkflowStatus.fromString(''), WorkflowStatus.pending);
    });
  });

  group('StepDetail', () {
    test('fromJson parses correctly', () {
      final detail = StepDetail.fromJson({
        'step': 'image_generation',
        'status': 'running',
        'progress': 42,
      });
      expect(detail.step, GenerationStep.imageGeneration);
      expect(detail.status, 'running');
      expect(detail.progress, 42);
    });

    test('fromJson handles missing fields', () {
      final detail = StepDetail.fromJson(<String, dynamic>{});
      expect(detail.step, GenerationStep.analysis);
      expect(detail.status, 'pending');
      expect(detail.progress, 0);
    });
  });

  group('WorkflowState', () {
    test('fromJson with SSE format (progress 0-100)', () {
      final state = WorkflowState.fromJson({
        'workflowId': 'wf1',
        'status': 'running',
        'progress': 75,
        'currentStep': 'image_generation',
      });
      expect(state.workflowId, 'wf1');
      expect(state.status, WorkflowStatus.running);
      expect(state.progress, closeTo(0.75, 0.001));
      expect(state.currentStep, GenerationStep.imageGeneration);
    });

    test('fromJson with legacy format (progress 0.0-1.0)', () {
      final state = WorkflowState.fromJson({
        'workflowId': 'wf2',
        'status': 'processing',
        'progress': 0.5,
        'currentStep': 'analysis',
      });
      expect(state.progress, closeTo(0.5, 0.001));
    });

    test('fromJson with steps list', () {
      final state = WorkflowState.fromJson({
        'workflowId': 'wf3',
        'status': 'running',
        'progress': 50,
        'currentStep': 'image_generation',
        'steps': [
          {'step': 'analysis', 'status': 'completed', 'progress': 100},
          {'step': 'image_generation', 'status': 'running', 'progress': 30},
        ],
      });
      expect(state.steps, hasLength(2));
      expect(state.steps[0].step, GenerationStep.analysis);
      expect(state.steps[0].status, 'completed');
      expect(state.steps[1].progress, 30);
    });

    test('fromJson with executionId key', () {
      final state = WorkflowState.fromJson({
        'executionId': 'exec1',
        'status': 'pending',
      });
      expect(state.workflowId, 'exec1');
    });

    test('isFinished for completed/failed/cancelled', () {
      for (final status in ['completed', 'failed', 'cancelled']) {
        final state = WorkflowState.fromJson({
          'workflowId': 'wf',
          'status': status,
        });
        expect(state.isFinished, isTrue, reason: '$status should be finished');
        expect(
          state.isInProgress,
          isFalse,
          reason: '$status should not be in progress',
        );
      }
    });

    test('isInProgress for pending/processing/running', () {
      for (final status in ['pending', 'processing', 'running']) {
        final state = WorkflowState.fromJson({
          'workflowId': 'wf',
          'status': status,
        });
        expect(
          state.isInProgress,
          isTrue,
          reason: '$status should be in progress',
        );
        expect(
          state.isFinished,
          isFalse,
          reason: '$status should not be finished',
        );
      }
    });
  });

  group('IngestionStatus / IngestionState', () {
    test('fromJson parses all statuses', () {
      for (final status in IngestionStatus.values) {
        final state = IngestionState.fromJson('job1', {'status': status.name});
        expect(state.status, status);
        expect(state.jobId, 'job1');
      }
    });

    test('isFinished for completed/failed/cancelled', () {
      for (final status in [
        IngestionStatus.completed,
        IngestionStatus.failed,
        IngestionStatus.cancelled,
      ]) {
        final state = IngestionState(jobId: 'j', status: status);
        expect(
          state.isFinished,
          isTrue,
          reason: '${status.name} should be finished',
        );
      }
    });

    test('isInProgress for queued/processing', () {
      for (final status in [
        IngestionStatus.queued,
        IngestionStatus.processing,
      ]) {
        final state = IngestionState(jobId: 'j', status: status);
        expect(
          state.isInProgress,
          isTrue,
          reason: '${status.name} should be in progress',
        );
      }
    });

    test('fromJson with result containing totalChunks', () {
      final state = IngestionState.fromJson('job2', {
        'status': 'completed',
        'result': {'totalChunks': 42},
      });
      expect(state.totalChunks, 42);
    });

    test('fromJson with error', () {
      final state = IngestionState.fromJson('job3', {
        'status': 'failed',
        'error': 'Something went wrong',
      });
      expect(state.error, 'Something went wrong');
      expect(state.status, IngestionStatus.failed);
    });
  });
}
