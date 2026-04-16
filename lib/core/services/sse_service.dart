import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:visiobook_mobile/config/environment.dart';

/// Represents a single step's detail within a workflow SSE event.
class SseStepDetail {
  final String step;
  final String status;
  final int progress;

  const SseStepDetail({
    required this.step,
    required this.status,
    required this.progress,
  });

  factory SseStepDetail.fromJson(Map<String, dynamic> json) {
    return SseStepDetail(
      step: json['step'] as String? ?? '',
      status: json['status'] as String? ?? '',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Represents a parsed SSE event from the workflow progress stream.
class SseEvent {
  final String executionId;

  /// One of: running, completed, failed, cancelled
  final String status;

  /// One of: analysis, reference_generation, image_generation,
  /// audio_generation, assembly — or null
  final String? currentStep;

  /// Overall progress 0-100
  final int progress;

  final List<SseStepDetail> steps;

  const SseEvent({
    required this.executionId,
    required this.status,
    this.currentStep,
    required this.progress,
    required this.steps,
  });

  factory SseEvent.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>? ?? [];
    return SseEvent(
      executionId: json['executionId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      currentStep: json['currentStep'] as String?,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      steps: rawSteps
          .map((s) => SseStepDetail.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Returns true when the workflow has reached a terminal state.
  bool get isTerminal =>
      status == 'completed' || status == 'failed' || status == 'cancelled';
}

/// Generic SSE client that connects to the workflow progress stream.
///
/// Usage:
/// ```dart
/// final sse = SseService(dio: apiClient.dio);
/// sse.connectToWorkflowProgress(
///   projectId: '...',
///   versionId: '...',
/// ).listen((event) {
///   print('${event.status} — ${event.progress}%');
/// });
/// ```
class SseService {
  final Dio _dio;

  CancelToken? _cancelToken;
  StreamController<SseEvent>? _controller;
  bool _disconnected = false;

  SseService({required Dio dio}) : _dio = dio;

  /// Connects to the workflow progress SSE endpoint and returns a broadcast
  /// stream of [SseEvent]. Automatically reconnects with exponential backoff
  /// (1 s, 2 s, 4 s, … max 10 s) on unexpected disconnects.
  ///
  /// The stream completes when a terminal event is received or [disconnect]
  /// is called.
  Stream<SseEvent> connectToWorkflowProgress({
    required String projectId,
    required String versionId,
  }) {
    _disconnected = false;
    _controller?.close();
    _controller = StreamController<SseEvent>.broadcast(onCancel: disconnect);

    final url =
        '${EnvironmentConfig.projectServiceUrl}/projects/$projectId/versions/$versionId/workflow/progress/stream';

    _connect(url);

    return _controller!.stream;
  }

  /// Disconnect from the current SSE stream and release resources.
  void disconnect() {
    _disconnected = true;
    _cancelToken?.cancel('SSE disconnected by client');
    _cancelToken = null;
    _controller?.close();
    _controller = null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _connect(String url, {int retryAttempt = 0}) async {
    if (_disconnected || _controller == null || _controller!.isClosed) return;

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    try {
      final response = await _dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
          // Disable the default receive timeout so the stream stays open.
          receiveTimeout: Duration.zero,
        ),
        cancelToken: _cancelToken,
      );

      final stream = response.data?.stream;
      if (stream == null) {
        _scheduleReconnect(url, retryAttempt);
        return;
      }

      // Reset retry counter on successful connection.
      var currentRetry = 0;

      final buffer = StringBuffer();

      await for (final chunk in stream) {
        if (_disconnected) break;

        buffer.write(utf8.decode(chunk, allowMalformed: true));

        // SSE events are separated by double newlines.
        while (buffer.toString().contains('\n\n')) {
          final raw = buffer.toString();
          final eventEnd = raw.indexOf('\n\n');
          final eventStr = raw.substring(0, eventEnd);
          buffer
            ..clear()
            ..write(raw.substring(eventEnd + 2));

          final event = _parseEvent(eventStr);
          if (event != null && !_controller!.isClosed) {
            _controller!.add(event);

            if (event.isTerminal) {
              // Workflow finished — close the stream cleanly.
              disconnect();
              return;
            }
          }
        }

        // Connection is alive — keep retry counter at zero.
        currentRetry = 0;
      }

      // Stream ended without a terminal event — reconnect.
      if (!_disconnected) {
        _scheduleReconnect(url, currentRetry);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;

      if (!_disconnected && _controller != null && !_controller!.isClosed) {
        _scheduleReconnect(url, retryAttempt);
      }
    }
  }

  void _scheduleReconnect(String url, int attempt) {
    if (_disconnected) return;

    final delaySec = _backoffSeconds(attempt);
    Future.delayed(Duration(seconds: delaySec), () {
      _connect(url, retryAttempt: attempt + 1);
    });
  }

  /// Exponential backoff: 1, 2, 4, 8, 10, 10, … seconds.
  int _backoffSeconds(int attempt) {
    final base = 1 << attempt; // 1, 2, 4, 8, 16, …
    return base.clamp(1, 10);
  }

  /// Parses a raw SSE text block into an [SseEvent], or returns null if the
  /// block doesn't contain a valid data line.
  SseEvent? _parseEvent(String raw) {
    String? dataPayload;

    for (final line in raw.split('\n')) {
      if (line.startsWith('data:')) {
        dataPayload = line.substring('data:'.length).trim();
      }
    }

    if (dataPayload == null || dataPayload.isEmpty) return null;

    try {
      final json = jsonDecode(dataPayload) as Map<String, dynamic>;
      return SseEvent.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
