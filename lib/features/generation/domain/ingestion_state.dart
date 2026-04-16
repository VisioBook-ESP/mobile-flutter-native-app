enum IngestionStatus { queued, processing, completed, failed, cancelled }

class IngestionState {
  final String jobId;
  final IngestionStatus status;
  final String? error;
  final int? totalChunks;

  const IngestionState({
    required this.jobId,
    required this.status,
    this.error,
    this.totalChunks,
  });

  bool get isFinished =>
      status == IngestionStatus.completed ||
      status == IngestionStatus.failed ||
      status == IngestionStatus.cancelled;

  bool get isInProgress =>
      status == IngestionStatus.queued || status == IngestionStatus.processing;

  factory IngestionState.fromJson(String jobId, Map<String, dynamic> json) {
    final statusStr = json['status'] as String;
    final status = IngestionStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => IngestionStatus.failed,
    );

    final result = json['result'] as Map<String, dynamic>?;
    final totalChunks = result?['totalChunks'] as int?;

    return IngestionState(
      jobId: jobId,
      status: status,
      error: json['error'] as String?,
      totalChunks: totalChunks,
    );
  }
}
