import 'package:dio/dio.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/features/payment/domain/subscription_plan.dart';
import 'package:visiobook_mobile/features/payment/domain/subscription.dart';
import 'package:visiobook_mobile/features/payment/domain/quota.dart';

class PaymentService {
  final ApiClient _apiClient;

  PaymentService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<SubscriptionPlan>> getPlans() async {
    if (EnvironmentConfig.useMockData) {
      return SubscriptionPlan.defaults;
    }
    try {
      final response = await _apiClient.getSubscriptionPlans();
      final plans = (response.data as List)
          .map((p) => SubscriptionPlan.fromJson(p as Map<String, dynamic>))
          .toList();
      return plans;
    } catch (e) {
      return SubscriptionPlan.defaults;
    }
  }

  Future<Subscription?> getCurrentSubscription() async {
    if (EnvironmentConfig.useMockData) {
      return null; // Free tier by default in mock
    }
    try {
      final response = await _apiClient.getCurrentSubscription();
      return Subscription.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Quota> getQuota() async {
    if (EnvironmentConfig.useMockData) {
      return Quota.defaultFree();
    }
    try {
      final response = await _apiClient.getQuota();
      return Quota.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return Quota.defaultFree();
    }
  }

  Future<Map<String, String>> createCheckoutSession({
    required String planId,
    required String interval,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final response = await _apiClient.createCheckoutSession({
      'planId': planId,
      'interval': interval,
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
    });
    final data = response.data as Map<String, dynamic>;
    return {
      'sessionId': data['sessionId'] as String,
      'checkoutUrl': data['checkoutUrl'] as String,
    };
  }

  /// Create a PaymentIntent for in-app payment via Stripe Payment Sheet
  /// This endpoint will be added by the backend team
  Future<Map<String, String>> createPaymentIntent({
    required String planId,
    required String interval,
  }) async {
    final response = await _apiClient.createPaymentIntent({
      'planId': planId,
      'interval': interval,
    });
    final data = response.data as Map<String, dynamic>;
    return {
      'clientSecret': data['clientSecret'] as String,
      'customerId': data['customerId'] as String,
      'ephemeralKey': data['ephemeralKey'] as String,
    };
  }

  Future<void> cancelSubscription({String? reason}) async {
    await _apiClient.cancelSubscription(reason: reason);
  }

  Future<void> upgradeSubscription(String planId) async {
    await _apiClient.upgradeSubscription(planId);
  }

  Future<void> downgradeSubscription(String planId) async {
    await _apiClient.downgradeSubscription(planId);
  }

  Future<String?> getPortalUrl() async {
    try {
      final response = await _apiClient.getStripePortalUrl();
      return (response.data as Map<String, dynamic>)['portalUrl'] as String?;
    } catch (e) {
      return null;
    }
  }
}
