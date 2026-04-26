class Quota {
  final int generationsUsed;
  final int generationsLimit;
  final double storageUsedGB;
  final double storageLimitGB;
  final String? resetDate;

  Quota({
    required this.generationsUsed,
    required this.generationsLimit,
    required this.storageUsedGB,
    required this.storageLimitGB,
    this.resetDate,
  });

  factory Quota.fromJson(Map<String, dynamic> json) {
    // Support backend format: { generations: {used, limit, resetDate}, storage: {used, limit} }
    final gens = json['generations'] as Map<String, dynamic>?;
    final storage = json['storage'] as Map<String, dynamic>?;

    if (gens != null && storage != null) {
      final rawUsed = (storage['used'] as num?)?.toDouble() ?? 0;
      final rawLimit = (storage['limit'] as num?)?.toDouble() ?? 0;
      // Le backend retourne le stockage en bytes, convertir en Go
      final usedGB = rawUsed > 1000 ? rawUsed / (1024 * 1024 * 1024) : rawUsed;
      final limitGB = rawLimit > 1000
          ? rawLimit / (1024 * 1024 * 1024)
          : rawLimit;

      return Quota(
        generationsUsed: (gens['used'] as num?)?.toInt() ?? 0,
        generationsLimit: (gens['limit'] as num?)?.toInt() ?? 0,
        storageUsedGB: usedGB,
        storageLimitGB: limitGB,
        resetDate: gens['resetDate'] as String?,
      );
    }

    // Fallback: flat format
    return Quota(
      generationsUsed:
          (json['generationsUsed'] as num?)?.toInt() ??
          (json['videosUsed'] as num?)?.toInt() ??
          0,
      generationsLimit:
          (json['generationsLimit'] as num?)?.toInt() ??
          (json['videosLimit'] as num?)?.toInt() ??
          0,
      storageUsedGB: (json['storageUsedGB'] as num?)?.toDouble() ?? 0,
      storageLimitGB: (json['storageLimitGB'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generations': {
        'used': generationsUsed,
        'limit': generationsLimit,
        if (resetDate != null) 'resetDate': resetDate,
      },
      'storage': {'used': storageUsedGB, 'limit': storageLimitGB},
    };
  }

  factory Quota.defaultFree() {
    return Quota(
      generationsUsed: 0,
      generationsLimit: 3,
      storageUsedGB: 0,
      storageLimitGB: 1,
    );
  }

  double get generationsUsagePercent =>
      generationsLimit > 0 ? generationsUsed / generationsLimit : 0;

  double get storageUsagePercent =>
      storageLimitGB > 0 ? storageUsedGB / storageLimitGB : 0;

  bool get hasGenerationsRemaining =>
      generationsLimit < 0 || generationsUsed < generationsLimit;

  bool get canGenerate => hasGenerationsRemaining;

  // Backwards compatibility
  int get videosUsed => generationsUsed;
  int get videosLimit => generationsLimit;
  double get videosUsagePercent => generationsUsagePercent;
  bool get hasVideosRemaining => hasGenerationsRemaining;
}
