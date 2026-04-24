class PlanLimits {
  final int generationsPerMonth;
  final int storageGB;
  final int maxProjectSize;
  final String exportQuality;
  final bool watermark;

  const PlanLimits({
    required this.generationsPerMonth,
    required this.storageGB,
    required this.maxProjectSize,
    required this.exportQuality,
    required this.watermark,
  });

  factory PlanLimits.fromJson(Map<String, dynamic> json) {
    return PlanLimits(
      generationsPerMonth: (json['generationsPerMonth'] as num?)?.toInt() ?? 0,
      storageGB: (json['storageGB'] as num?)?.toInt() ?? 0,
      maxProjectSize: (json['maxProjectSize'] as num?)?.toInt() ?? 0,
      exportQuality: json['exportQuality'] as String? ?? '720p',
      watermark: json['watermark'] as bool? ?? true,
    );
  }

  String get generationsLabel =>
      generationsPerMonth < 0 ? 'Illimité' : '$generationsPerMonth';
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final String currency;
  final PlanLimits limits;
  final List<String> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.currency,
    required this.limits,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final limits = json['limits'] is Map<String, dynamic>
        ? PlanLimits.fromJson(json['limits'] as Map<String, dynamic>)
        : const PlanLimits(
            generationsPerMonth: 3,
            storageGB: 1,
            maxProjectSize: 5,
            exportQuality: '720p',
            watermark: true,
          );

    // Construire les features depuis les limits si pas fournies
    final features =
        (json['features'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        _buildFeaturesFromLimits(limits);

    return SubscriptionPlan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      monthlyPrice:
          (json['price'] as num?)?.toDouble() ??
          (json['monthlyPrice'] as num?)?.toDouble() ??
          0,
      yearlyPrice:
          (json['priceYearly'] as num?)?.toDouble() ??
          (json['yearlyPrice'] as num?)?.toDouble() ??
          0,
      currency: json['currency'] as String? ?? 'eur',
      limits: limits,
      features: features,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': monthlyPrice,
      'priceYearly': yearlyPrice,
      'currency': currency,
      'features': features,
    };
  }

  static List<String> _buildFeaturesFromLimits(PlanLimits limits) {
    final features = <String>[];
    features.add('${limits.generationsLabel} générations/mois');
    features.add('${limits.storageGB} Go de stockage');
    features.add('Export ${limits.exportQuality}');
    if (!limits.watermark) features.add('Sans filigrane');
    return features;
  }

  static List<SubscriptionPlan> get defaults => [
    SubscriptionPlan(
      id: 'free',
      name: 'Free',
      description: 'Pour découvrir',
      monthlyPrice: 0,
      yearlyPrice: 0,
      currency: 'eur',
      limits: const PlanLimits(
        generationsPerMonth: 3,
        storageGB: 1,
        maxProjectSize: 5,
        exportQuality: '720p',
        watermark: true,
      ),
      features: ['3 générations/mois', '1 Go de stockage', 'Export 720p'],
    ),
    SubscriptionPlan(
      id: 'premium',
      name: 'Premium',
      description: 'Pour les créateurs',
      monthlyPrice: 9.99,
      yearlyPrice: 99.99,
      currency: 'eur',
      limits: const PlanLimits(
        generationsPerMonth: 50,
        storageGB: 10,
        maxProjectSize: 50,
        exportQuality: '1080p',
        watermark: false,
      ),
      features: [
        '50 générations/mois',
        '10 Go de stockage',
        'Export 1080p',
        'Sans filigrane',
      ],
    ),
    SubscriptionPlan(
      id: 'enterprise',
      name: 'Enterprise',
      description: 'Pour les équipes',
      monthlyPrice: 29.99,
      yearlyPrice: 299.99,
      currency: 'eur',
      limits: const PlanLimits(
        generationsPerMonth: -1,
        storageGB: 100,
        maxProjectSize: 200,
        exportQuality: '4k',
        watermark: false,
      ),
      features: [
        'Générations illimitées',
        '100 Go de stockage',
        'Export 4K',
        'Sans filigrane',
        'Support dédié',
      ],
    ),
  ];
}
