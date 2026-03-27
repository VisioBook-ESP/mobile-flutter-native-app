class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final int maxProjects;
  final int maxVideosPerMonth;
  final int maxVideoLength;
  final List<String> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.maxProjects,
    required this.maxVideosPerMonth,
    required this.maxVideoLength,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      monthlyPrice: (json['monthlyPrice'] as num?)?.toDouble() ?? 0,
      yearlyPrice: (json['yearlyPrice'] as num?)?.toDouble() ?? 0,
      maxProjects: json['maxProjects'] as int? ?? 0,
      maxVideosPerMonth: json['maxVideosPerMonth'] as int? ?? 0,
      maxVideoLength: json['maxVideoLength'] as int? ?? 0,
      features:
          (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'monthlyPrice': monthlyPrice,
      'yearlyPrice': yearlyPrice,
      'maxProjects': maxProjects,
      'maxVideosPerMonth': maxVideosPerMonth,
      'maxVideoLength': maxVideoLength,
      'features': features,
    };
  }

  static List<SubscriptionPlan> get defaults => [
    SubscriptionPlan(
      id: 'free',
      name: 'Free',
      description: 'Pour commencer',
      monthlyPrice: 0,
      yearlyPrice: 0,
      maxProjects: 2,
      maxVideosPerMonth: 3,
      maxVideoLength: 60,
      features: ['2 projets', '3 vidéos/mois', '1 min max'],
    ),
    SubscriptionPlan(
      id: 'pro',
      name: 'Pro',
      description: 'Pour les professionnels',
      monthlyPrice: 19.99,
      yearlyPrice: 199.99,
      maxProjects: 20,
      maxVideosPerMonth: 50,
      maxVideoLength: 600,
      features: [
        '20 projets',
        '50 vidéos/mois',
        '10 min max',
        'Support prioritaire',
      ],
    ),
    SubscriptionPlan(
      id: 'enterprise',
      name: 'Enterprise',
      description: 'Pour les grandes équipes',
      monthlyPrice: 49.99,
      yearlyPrice: 499.99,
      maxProjects: -1,
      maxVideosPerMonth: -1,
      maxVideoLength: 1800,
      features: [
        'Projets illimités',
        'Vidéos illimitées',
        '30 min max',
        'Support dédié',
        'API access',
      ],
    ),
  ];
}
