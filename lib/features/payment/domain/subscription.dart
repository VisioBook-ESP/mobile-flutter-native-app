class Subscription {
  final String id;
  final String planId;
  final String status;
  final String interval;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? cancelAt;
  final bool cancelAtPeriodEnd;

  Subscription({
    required this.id,
    required this.planId,
    required this.status,
    required this.interval,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAt,
    this.cancelAtPeriodEnd = false,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      status: json['status'] as String? ?? 'inactive',
      interval: json['interval'] as String? ?? 'month',
      currentPeriodStart: json['currentPeriodStart'] != null
          ? DateTime.parse(json['currentPeriodStart'] as String)
          : null,
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.parse(json['currentPeriodEnd'] as String)
          : null,
      cancelAt: json['cancelAt'] != null
          ? DateTime.parse(json['cancelAt'] as String)
          : null,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planId': planId,
      'status': status,
      'interval': interval,
      if (currentPeriodStart != null)
        'currentPeriodStart': currentPeriodStart!.toIso8601String(),
      if (currentPeriodEnd != null)
        'currentPeriodEnd': currentPeriodEnd!.toIso8601String(),
      if (cancelAt != null) 'cancelAt': cancelAt!.toIso8601String(),
      'cancelAtPeriodEnd': cancelAtPeriodEnd,
    };
  }

  bool get isActive => status == 'active';
  bool get isCanceled => status == 'canceled' || cancelAtPeriodEnd;
  bool get isTrialing => status == 'trialing';
}
