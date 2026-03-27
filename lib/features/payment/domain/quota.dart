class Quota {
  final int projectsUsed;
  final int projectsLimit;
  final int videosUsed;
  final int videosLimit;
  final int maxVideoLength;

  Quota({
    required this.projectsUsed,
    required this.projectsLimit,
    required this.videosUsed,
    required this.videosLimit,
    required this.maxVideoLength,
  });

  factory Quota.fromJson(Map<String, dynamic> json) {
    return Quota(
      projectsUsed: json['projectsUsed'] as int? ?? 0,
      projectsLimit: json['projectsLimit'] as int? ?? 0,
      videosUsed: json['videosUsed'] as int? ?? 0,
      videosLimit: json['videosLimit'] as int? ?? 0,
      maxVideoLength: json['maxVideoLength'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectsUsed': projectsUsed,
      'projectsLimit': projectsLimit,
      'videosUsed': videosUsed,
      'videosLimit': videosLimit,
      'maxVideoLength': maxVideoLength,
    };
  }

  factory Quota.defaultFree() {
    return Quota(
      projectsUsed: 0,
      projectsLimit: 2,
      videosUsed: 0,
      videosLimit: 3,
      maxVideoLength: 60,
    );
  }

  double get projectsUsagePercent =>
      projectsLimit > 0 ? projectsUsed / projectsLimit : 0;

  double get videosUsagePercent =>
      videosLimit > 0 ? videosUsed / videosLimit : 0;

  bool get hasProjectsRemaining =>
      projectsLimit < 0 || projectsUsed < projectsLimit;

  bool get hasVideosRemaining => videosLimit < 0 || videosUsed < videosLimit;

  bool get canGenerate => hasProjectsRemaining && hasVideosRemaining;
}
