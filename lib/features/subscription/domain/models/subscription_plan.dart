import 'package:equatable/equatable.dart';

enum SubscriptionPlanType { monthly, annual }

class SubscriptionPlan extends Equatable {
  final String id;
  final String name;
  final String description;
  final double priceTND;
  final SubscriptionPlanType type;
  final List<String> features;
  final bool isRecommended;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceTND,
    required this.type,
    required this.features,
    this.isRecommended = false,
  });

  int get priceMillimes => (priceTND * 1000).toInt();

  String get priceLabel => '${priceTND.toStringAsFixed(0)} TND';

  String get periodLabel {
    switch (type) {
      case SubscriptionPlanType.monthly:
        return '/mois';
      case SubscriptionPlanType.annual:
        return '/an';
    }
  }

  String get savingsLabel {
    if (type == SubscriptionPlanType.annual) {
      const monthlyTotal = 29.9 * 12;
      final savings = monthlyTotal - priceTND;
      return 'Économisez ${savings.toStringAsFixed(0)} TND/an';
    }
    return '';
  }

  @override
  List<Object?> get props => [id];
}

class SubscriptionPlans {
  static const SubscriptionPlan monthly = SubscriptionPlan(
    id: 'plan_monthly',
    name: 'Mensuel',
    description: 'Accès complet à la plateforme',
    priceTND: 29.9,
    type: SubscriptionPlanType.monthly,
    features: [
      'Accès illimité aux cours',
      'Sessions de formation en direct',
      'Quiz interactifs',
      'Support prioritaire',
      'Certificats de réussite',
    ],
  );

  static const SubscriptionPlan annual = SubscriptionPlan(
    id: 'plan_annual',
    name: 'Annuel',
    description: 'Économisez avec l\'abonnement annuel',
    priceTND: 299.0,
    type: SubscriptionPlanType.annual,
    features: [
      'Tout le plan mensuel',
      '2 mois offerts',
      'Accès anticipé aux nouveaux cours',
      'Téléconsultation illimitée',
      'Contenu exclusif premium',
      'Badge membre premium',
    ],
    isRecommended: true,
  );

  static List<SubscriptionPlan> all() => [monthly, annual];
}
