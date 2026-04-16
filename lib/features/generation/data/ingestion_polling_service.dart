import 'dart:async';

import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/features/generation/domain/ingestion_state.dart';

class IngestionPollingService {
  final ApiClient _apiClient;
  Timer? _timer;
  StreamController<IngestionState>? _controller;

  IngestionPollingService({required ApiClient apiClient})
    : _apiClient = apiClient;

  /// Starts polling ingestion status every 2 seconds.
  /// Returns a stream of [IngestionState] updates.
  /// Automatically stops when status is finished.
  Stream<IngestionState> pollIngestionStatus(String jobId) {
    stopPolling();

    _controller = StreamController<IngestionState>.broadcast(
      onCancel: stopPolling,
    );

    _poll(jobId);

    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _poll(jobId);
    });

    return _controller!.stream;
  }

  Future<void> _poll(String jobId) async {
    final state = await getIngestionStatus(jobId);
    if (state == null || _controller == null || _controller!.isClosed) return;

    _controller!.add(state);

    if (state.isFinished) {
      stopPolling();
    }
  }

  /// Stop polling and close the stream.
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _controller?.close();
    _controller = null;
  }

  /// Single status check for one-off queries.
  Future<IngestionState?> getIngestionStatus(String jobId) async {
    try {
      final response = await _apiClient.getIngestionStatus(jobId);
      final data = response.data as Map<String, dynamic>;
      return IngestionState.fromJson(jobId, data);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    stopPolling();
  }
}
