import 'package:flutter/foundation.dart';
import 'package:visiobook_mobile/features/payment/data/payment_service.dart';
import 'package:visiobook_mobile/features/payment/domain/subscription_plan.dart';
import 'package:visiobook_mobile/features/payment/domain/subscription.dart';
import 'package:visiobook_mobile/features/payment/domain/quota.dart';

enum PaymentState { initial, loading, loaded, error }

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService;

  PaymentState _state = PaymentState.initial;
  List<SubscriptionPlan> _plans = [];
  Subscription? _subscription;
  Quota? _quota;
  String? _error;
  bool _isProcessing = false;

  PaymentProvider({required PaymentService paymentService})
    : _paymentService = paymentService;

  PaymentState get state => _state;
  List<SubscriptionPlan> get plans => _plans;
  Subscription? get subscription => _subscription;
  Quota? get quota => _quota;
  String? get error => _error;
  bool get isProcessing => _isProcessing;
  bool get isLoading => _state == PaymentState.loading;

  String get currentPlanId => _subscription?.planId ?? 'free';
  bool get isFree => currentPlanId == 'free';
  bool get canGenerate => _quota?.canGenerate ?? true;

  SubscriptionPlan? get currentPlan {
    if (_plans.isEmpty) return null;
    try {
      return _plans.firstWhere((p) => p.id == currentPlanId);
    } catch (_) {
      return _plans.first;
    }
  }

  /// Load plans, subscription and quota
  Future<void> loadAll() async {
    _state = PaymentState.loading;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _paymentService.getPlans(),
        _paymentService.getCurrentSubscription(),
        _paymentService.getQuota(),
      ]);

      _plans = results[0] as List<SubscriptionPlan>;
      _subscription = results[1] as Subscription?;
      _quota = results[2] as Quota;
      _state = PaymentState.loaded;
    } catch (e) {
      _plans = SubscriptionPlan.defaults;
      _quota = Quota.defaultFree();
      _error = "Impossible de charger les données d'abonnement";
      _state = PaymentState.error;
    }
    notifyListeners();
  }

  /// Load only quota (lighter, for checking before generation)
  Future<void> loadQuota() async {
    try {
      _quota = await _paymentService.getQuota();
      notifyListeners();
    } catch (_) {}
  }

  /// Create payment intent for in-app Stripe payment
  /// Returns the clientSecret, customerId, ephemeralKey
  Future<Map<String, String>?> createPaymentIntent({
    required String planId,
    required String interval,
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _paymentService.createPaymentIntent(
        planId: planId,
        interval: interval,
      );
      _isProcessing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = 'Erreur lors de la création du paiement';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// Cancel current subscription
  Future<bool> cancelSubscription({String? reason}) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      await _paymentService.cancelSubscription(reason: reason);
      await loadAll();
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = "Erreur lors de l'annulation";
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  /// Upgrade to a higher plan
  Future<bool> upgradePlan(String planId) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      await _paymentService.upgradeSubscription(planId);
      await loadAll();
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors du changement de plan';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  /// Downgrade to a lower plan
  Future<bool> downgradePlan(String planId) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      await _paymentService.downgradeSubscription(planId);
      await loadAll();
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors du changement de plan';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  /// Get Stripe billing portal URL
  Future<String?> getPortalUrl() async {
    return _paymentService.getPortalUrl();
  }
}
