import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/payment/data/payment_service.dart';
import 'package:visiobook_mobile/features/payment/presentation/providers/payment_provider.dart';

// ---------------------------------------------------------------------------
// Stubs to avoid platform channels (FlutterSecureStorage)
// ---------------------------------------------------------------------------

class _FakeSecureStorage extends SecureStorageService {
  @override
  Future<String?> getAccessToken() async => 'fake_token';
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> saveAccessToken(String token) async {}
  @override
  Future<void> saveRefreshToken(String token) async {}
  @override
  Future<void> clearTokens() async {}
  @override
  Future<bool> isLoggedIn() async => true;
  @override
  Future<void> saveUserId(String userId) async {}
  @override
  Future<String?> getUserId() async => 'fake_user';
  @override
  Future<void> saveUserName(String name) async {}
  @override
  Future<String?> getUserName() async => 'Fake';
  @override
  Future<void> setOnboardingComplete(bool complete) async {}
  @override
  Future<bool> isOnboardingComplete() async => true;
  @override
  Future<void> clearAll() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PaymentProvider provider;
  late PaymentService paymentService;

  setUp(() {
    EnvironmentConfig.useMockData = true;
    paymentService = PaymentService(
      apiClient: ApiClient(storage: _FakeSecureStorage()),
    );
    provider = PaymentProvider(paymentService: paymentService);
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
    provider.dispose();
  });

  group('PaymentProvider initial state', () {
    test('state is initial', () {
      expect(provider.state, PaymentState.initial);
    });

    test('plans is empty', () {
      expect(provider.plans, isEmpty);
    });

    test('subscription is null', () {
      expect(provider.subscription, isNull);
    });

    test('quota is null', () {
      expect(provider.quota, isNull);
    });

    test('error is null', () {
      expect(provider.error, isNull);
    });

    test('isProcessing is false', () {
      expect(provider.isProcessing, isFalse);
    });

    test('isLoading is false', () {
      expect(provider.isLoading, isFalse);
    });

    test('currentPlanId is free when no subscription', () {
      expect(provider.currentPlanId, 'free');
    });

    test('isFree is true when no subscription', () {
      expect(provider.isFree, isTrue);
    });

    test('canGenerate is true when no quota', () {
      expect(provider.canGenerate, isTrue);
    });

    test('currentPlan is null when plans empty', () {
      expect(provider.currentPlan, isNull);
    });
  });

  group('PaymentProvider loadAll mock mode', () {
    test('loads plans, subscription and quota', () async {
      await provider.loadAll();

      expect(provider.state, PaymentState.loaded);
      expect(provider.plans, isNotEmpty);
      expect(provider.plans.length, 3);
      expect(provider.subscription, isNull); // Mock returns null (free tier)
      expect(provider.quota, isNotNull);
      expect(provider.error, isNull);
    });

    test('plans contain free, pro and enterprise', () async {
      await provider.loadAll();

      final planIds = provider.plans.map((p) => p.id).toList();
      expect(planIds, contains('free'));
      expect(planIds, contains('pro'));
      expect(planIds, contains('enterprise'));
    });

    test('quota is default free', () async {
      await provider.loadAll();

      expect(provider.quota!.projectsLimit, 2);
      expect(provider.quota!.videosLimit, 3);
      expect(provider.quota!.maxVideoLength, 60);
      expect(provider.quota!.projectsUsed, 0);
      expect(provider.quota!.videosUsed, 0);
    });

    test('canGenerate is true with default free quota', () async {
      await provider.loadAll();

      expect(provider.canGenerate, isTrue);
    });

    test('currentPlan returns free plan after loading', () async {
      await provider.loadAll();

      expect(provider.currentPlan, isNotNull);
      expect(provider.currentPlan!.id, 'free');
      expect(provider.currentPlan!.name, 'Free');
    });

    test('notifies listeners during load', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadAll();

      // At least 2: loading + loaded
      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });

  group('PaymentProvider loadQuota mock mode', () {
    test('loads quota independently', () async {
      await provider.loadQuota();

      expect(provider.quota, isNotNull);
      expect(provider.quota!.projectsLimit, 2);
    });
  });

  group('PaymentProvider loadPlans populates plans', () {
    test('loadAll populates plans list with 3 plans', () async {
      await provider.loadAll();

      expect(provider.plans, isNotEmpty);
      expect(provider.plans.length, 3);
    });

    test('each plan has an id and name', () async {
      await provider.loadAll();

      for (final plan in provider.plans) {
        expect(plan.id, isNotEmpty);
        expect(plan.name, isNotEmpty);
      }
    });
  });

  group('PaymentProvider loadQuota populates quota', () {
    test('loadQuota sets quota with correct limits', () async {
      await provider.loadQuota();

      expect(provider.quota, isNotNull);
      expect(provider.quota!.projectsLimit, 2);
      expect(provider.quota!.videosLimit, 3);
      expect(provider.quota!.maxVideoLength, 60);
    });

    test('loadQuota sets correct usage defaults', () async {
      await provider.loadQuota();

      expect(provider.quota!.projectsUsed, 0);
      expect(provider.quota!.videosUsed, 0);
    });
  });

  group('PaymentProvider computed getters with data loaded', () {
    test('isFree is true for free plan', () async {
      await provider.loadAll();
      expect(provider.isFree, isTrue);
    });

    test('currentPlanId defaults to free', () async {
      await provider.loadAll();
      expect(provider.currentPlanId, 'free');
    });

    test('canGenerate is true with default quota', () async {
      await provider.loadAll();
      expect(provider.canGenerate, isTrue);
    });

    test('currentPlan returns free plan after loadAll', () async {
      await provider.loadAll();

      final plan = provider.currentPlan;
      expect(plan, isNotNull);
      expect(plan!.id, 'free');
      expect(plan.name, 'Free');
    });

    test('isProcessing is false after loadAll', () async {
      await provider.loadAll();
      expect(provider.isProcessing, isFalse);
    });

    test('error is null after successful loadAll', () async {
      await provider.loadAll();
      expect(provider.error, isNull);
    });
  });
}
