import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/features/payment/domain/subscription.dart';
import 'package:visiobook_mobile/features/payment/domain/subscription_plan.dart';
// PlanLimits is exported from subscription_plan.dart
import 'package:visiobook_mobile/features/profile/domain/user_profile.dart';

void main() {
  // -------------------------------------------------------------------------
  // Subscription
  // -------------------------------------------------------------------------
  group('Subscription', () {
    test('fromJson parses full payload', () {
      final sub = Subscription.fromJson({
        'id': 'sub_123',
        'planId': 'pro',
        'status': 'active',
        'interval': 'year',
        'currentPeriodStart': '2025-01-01T00:00:00.000Z',
        'currentPeriodEnd': '2026-01-01T00:00:00.000Z',
        'cancelAt': '2026-06-01T00:00:00.000Z',
        'cancelAtPeriodEnd': true,
      });

      expect(sub.id, equals('sub_123'));
      expect(sub.planId, equals('pro'));
      expect(sub.status, equals('active'));
      expect(sub.interval, equals('year'));
      expect(sub.currentPeriodStart, isNotNull);
      expect(sub.currentPeriodStart!.year, equals(2025));
      expect(sub.currentPeriodEnd, isNotNull);
      expect(sub.currentPeriodEnd!.year, equals(2026));
      expect(sub.cancelAt, isNotNull);
      expect(sub.cancelAtPeriodEnd, isTrue);
    });

    test('fromJson uses defaults for missing fields', () {
      final sub = Subscription.fromJson({});
      expect(sub.id, equals(''));
      expect(sub.planId, equals(''));
      expect(sub.status, equals('inactive'));
      expect(sub.interval, equals('month'));
      expect(sub.currentPeriodStart, isNull);
      expect(sub.currentPeriodEnd, isNull);
      expect(sub.cancelAt, isNull);
      expect(sub.cancelAtPeriodEnd, isFalse);
    });

    test('toJson includes all fields', () {
      final now = DateTime.utc(2025, 6, 15);
      final sub = Subscription(
        id: 's1',
        planId: 'free',
        status: 'active',
        interval: 'month',
        currentPeriodStart: now,
        currentPeriodEnd: now.add(const Duration(days: 30)),
        cancelAt: now.add(const Duration(days: 60)),
        cancelAtPeriodEnd: true,
      );
      final json = sub.toJson();

      expect(json['id'], equals('s1'));
      expect(json['planId'], equals('free'));
      expect(json['status'], equals('active'));
      expect(json['interval'], equals('month'));
      expect(json['currentPeriodStart'], isNotNull);
      expect(json['currentPeriodEnd'], isNotNull);
      expect(json['cancelAt'], isNotNull);
      expect(json['cancelAtPeriodEnd'], isTrue);
    });

    test('toJson omits null date fields', () {
      final sub = Subscription(
        id: 's2',
        planId: 'pro',
        status: 'inactive',
        interval: 'year',
      );
      final json = sub.toJson();
      expect(json.containsKey('currentPeriodStart'), isFalse);
      expect(json.containsKey('currentPeriodEnd'), isFalse);
      expect(json.containsKey('cancelAt'), isFalse);
    });

    test('isActive returns true only for active status', () {
      final active = Subscription(
        id: '1',
        planId: 'p',
        status: 'active',
        interval: 'month',
      );
      final inactive = Subscription(
        id: '2',
        planId: 'p',
        status: 'inactive',
        interval: 'month',
      );
      expect(active.isActive, isTrue);
      expect(inactive.isActive, isFalse);
    });

    test(
      'isCanceled returns true for canceled status or cancelAtPeriodEnd',
      () {
        final canceled = Subscription(
          id: '1',
          planId: 'p',
          status: 'canceled',
          interval: 'month',
        );
        final pendingCancel = Subscription(
          id: '2',
          planId: 'p',
          status: 'active',
          interval: 'month',
          cancelAtPeriodEnd: true,
        );
        final notCanceled = Subscription(
          id: '3',
          planId: 'p',
          status: 'active',
          interval: 'month',
        );
        expect(canceled.isCanceled, isTrue);
        expect(pendingCancel.isCanceled, isTrue);
        expect(notCanceled.isCanceled, isFalse);
      },
    );

    test('isTrialing returns true for trialing status', () {
      final trialing = Subscription(
        id: '1',
        planId: 'p',
        status: 'trialing',
        interval: 'month',
      );
      final active = Subscription(
        id: '2',
        planId: 'p',
        status: 'active',
        interval: 'month',
      );
      expect(trialing.isTrialing, isTrue);
      expect(active.isTrialing, isFalse);
    });

    test('fromJson -> toJson roundtrip preserves data', () {
      final original = {
        'id': 'sub_rt',
        'planId': 'enterprise',
        'status': 'active',
        'interval': 'year',
        'currentPeriodStart': '2025-03-01T00:00:00.000Z',
        'currentPeriodEnd': '2026-03-01T00:00:00.000Z',
        'cancelAtPeriodEnd': false,
      };
      final sub = Subscription.fromJson(original);
      final json = sub.toJson();
      expect(json['id'], equals('sub_rt'));
      expect(json['planId'], equals('enterprise'));
      expect(json['status'], equals('active'));
      expect(json['interval'], equals('year'));
      expect(json['cancelAtPeriodEnd'], isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // SubscriptionPlan
  // -------------------------------------------------------------------------
  group('SubscriptionPlan', () {
    test('fromJson parses full payload', () {
      final plan = SubscriptionPlan.fromJson({
        'id': 'premium',
        'name': 'Premium',
        'description': 'For creators',
        'price': 9.99,
        'priceYearly': 99.99,
        'currency': 'eur',
        'limits': {
          'generationsPerMonth': 50,
          'storageGB': 10,
          'maxProjectSize': 50,
          'exportQuality': '1080p',
          'watermark': false,
        },
        'features': ['Feature A', 'Feature B'],
      });
      expect(plan.id, equals('premium'));
      expect(plan.name, equals('Premium'));
      expect(plan.description, equals('For creators'));
      expect(plan.monthlyPrice, equals(9.99));
      expect(plan.yearlyPrice, equals(99.99));
      expect(plan.currency, equals('eur'));
      expect(plan.limits.generationsPerMonth, equals(50));
      expect(plan.limits.storageGB, equals(10));
      expect(plan.limits.maxProjectSize, equals(50));
      expect(plan.limits.exportQuality, equals('1080p'));
      expect(plan.limits.watermark, isFalse);
      expect(plan.features, equals(['Feature A', 'Feature B']));
    });

    test('fromJson uses defaults for missing fields', () {
      final plan = SubscriptionPlan.fromJson({});
      expect(plan.id, equals(''));
      expect(plan.name, equals(''));
      expect(plan.description, equals(''));
      expect(plan.monthlyPrice, equals(0));
      expect(plan.yearlyPrice, equals(0));
      expect(plan.currency, equals('eur'));
      expect(plan.limits.generationsPerMonth, equals(3));
      expect(plan.features, isNotEmpty);
    });

    test('toJson includes all fields', () {
      final plan = SubscriptionPlan(
        id: 'test',
        name: 'Test Plan',
        description: 'A test',
        monthlyPrice: 9.99,
        yearlyPrice: 99.99,
        currency: 'eur',
        limits: const PlanLimits(
          generationsPerMonth: 10,
          storageGB: 5,
          maxProjectSize: 20,
          exportQuality: '1080p',
          watermark: false,
        ),
        features: ['f1'],
      );
      final json = plan.toJson();
      expect(json['id'], equals('test'));
      expect(json['name'], equals('Test Plan'));
      expect(json['description'], equals('A test'));
      expect(json['price'], equals(9.99));
      expect(json['priceYearly'], equals(99.99));
      expect(json['currency'], equals('eur'));
      expect(json['features'], equals(['f1']));
    });

    test('defaults returns 3 plans', () {
      final plans = SubscriptionPlan.defaults;
      expect(plans.length, equals(3));
      expect(plans[0].id, equals('free'));
      expect(plans[1].id, equals('premium'));
      expect(plans[2].id, equals('enterprise'));
    });

    test('defaults free plan has correct values', () {
      final free = SubscriptionPlan.defaults[0];
      expect(free.monthlyPrice, equals(0));
      expect(free.yearlyPrice, equals(0));
      expect(free.limits.generationsPerMonth, equals(3));
      expect(free.limits.storageGB, equals(1));
      expect(free.limits.watermark, isTrue);
    });

    test('defaults enterprise plan has unlimited markers', () {
      final enterprise = SubscriptionPlan.defaults[2];
      expect(enterprise.limits.generationsPerMonth, equals(-1));
      expect(enterprise.limits.storageGB, equals(100));
    });

    test('fromJson handles int prices cast to double', () {
      final plan = SubscriptionPlan.fromJson({
        'id': 'x',
        'name': 'X',
        'description': '',
        'monthlyPrice': 10,
        'yearlyPrice': 100,
        'features': [],
      });
      expect(plan.monthlyPrice, equals(10.0));
      expect(plan.yearlyPrice, equals(100.0));
    });

    test('fromJson -> toJson roundtrip', () {
      final original = SubscriptionPlan.defaults[1]; // Premium
      final json = original.toJson();
      final restored = SubscriptionPlan.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.monthlyPrice, equals(original.monthlyPrice));
      expect(restored.features.length, equals(original.features.length));
    });
  });

  // -------------------------------------------------------------------------
  // UserProfile
  // -------------------------------------------------------------------------
  group('UserProfile', () {
    test('fromJson parses full payload', () {
      final profile = UserProfile.fromJson({
        'id': 'u123',
        'username': 'johndoe',
        'email': 'john@example.com',
        'role': 'admin',
        'first_name': 'John',
        'last_name': 'Doe',
        'avatar_url': 'https://example.com/avatar.jpg',
        'credits': 500,
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(profile.id, equals('u123'));
      expect(profile.username, equals('johndoe'));
      expect(profile.email, equals('john@example.com'));
      expect(profile.role, equals('admin'));
      expect(profile.firstName, equals('John'));
      expect(profile.lastName, equals('Doe'));
      expect(profile.avatarUrl, equals('https://example.com/avatar.jpg'));
      expect(profile.credits, equals(500));
      expect(profile.createdAt, isNotNull);
      expect(profile.createdAt!.year, equals(2024));
    });

    test('fromJson uses defaults for missing fields', () {
      final profile = UserProfile.fromJson({});
      expect(profile.id, equals(''));
      expect(profile.username, equals(''));
      expect(profile.email, equals(''));
      expect(profile.role, isNull);
      expect(profile.firstName, isNull);
      expect(profile.lastName, isNull);
      expect(profile.avatarUrl, isNull);
      expect(profile.credits, equals(0));
      expect(profile.createdAt, isNull);
    });

    test('fromJson converts numeric id to string', () {
      final profile = UserProfile.fromJson({
        'id': 42,
        'username': 'test',
        'email': 'test@example.com',
      });
      expect(profile.id, equals('42'));
    });

    test('toJson includes all fields', () {
      final now = DateTime.utc(2025, 6, 15);
      final profile = UserProfile(
        id: 'u1',
        username: 'alice',
        email: 'alice@example.com',
        role: 'user',
        firstName: 'Alice',
        lastName: 'Smith',
        avatarUrl: 'https://example.com/a.jpg',
        credits: 100,
        createdAt: now,
      );
      final json = profile.toJson();
      expect(json['id'], equals('u1'));
      expect(json['username'], equals('alice'));
      expect(json['email'], equals('alice@example.com'));
      expect(json['role'], equals('user'));
      expect(json['first_name'], equals('Alice'));
      expect(json['last_name'], equals('Smith'));
      expect(json['avatar_url'], equals('https://example.com/a.jpg'));
      expect(json['credits'], equals(100));
      expect(json['created_at'], isNotNull);
    });

    test('toJson omits null createdAt', () {
      final profile = UserProfile(
        id: 'u1',
        username: 'test',
        email: 'test@example.com',
      );
      final json = profile.toJson();
      expect(json.containsKey('created_at'), isFalse);
    });

    test('displayName returns firstName when available', () {
      final profile = UserProfile(
        id: 'u1',
        username: 'johndoe',
        email: 'john@example.com',
        firstName: 'John',
      );
      expect(profile.displayName, equals('John'));
    });

    test('displayName returns username when firstName is null', () {
      final profile = UserProfile(
        id: 'u1',
        username: 'johndoe',
        email: 'john@example.com',
      );
      expect(profile.displayName, equals('johndoe'));
    });

    test('displayName returns username when firstName is empty', () {
      final profile = UserProfile(
        id: 'u1',
        username: 'johndoe',
        email: 'john@example.com',
        firstName: '',
      );
      expect(profile.displayName, equals('johndoe'));
    });

    test('copyWith overrides specified fields', () {
      final original = UserProfile(
        id: 'u1',
        username: 'old',
        email: 'old@example.com',
        firstName: 'Old',
        credits: 50,
      );
      final updated = original.copyWith(
        username: 'new',
        firstName: 'New',
        credits: 200,
      );
      expect(updated.id, equals('u1')); // unchanged
      expect(updated.username, equals('new'));
      expect(updated.email, equals('old@example.com')); // unchanged
      expect(updated.firstName, equals('New'));
      expect(updated.credits, equals(200));
    });

    test('copyWith preserves all fields when no overrides', () {
      final now = DateTime.utc(2025, 1, 1);
      final original = UserProfile(
        id: 'u1',
        username: 'test',
        email: 'test@example.com',
        role: 'admin',
        firstName: 'Test',
        lastName: 'User',
        avatarUrl: 'https://example.com/a.jpg',
        credits: 100,
        createdAt: now,
      );
      final copy = original.copyWith();
      expect(copy.id, equals(original.id));
      expect(copy.username, equals(original.username));
      expect(copy.email, equals(original.email));
      expect(copy.role, equals(original.role));
      expect(copy.firstName, equals(original.firstName));
      expect(copy.lastName, equals(original.lastName));
      expect(copy.avatarUrl, equals(original.avatarUrl));
      expect(copy.credits, equals(original.credits));
      expect(copy.createdAt, equals(original.createdAt));
    });

    test('fromJson -> toJson roundtrip', () {
      final original = {
        'id': 'u_rt',
        'username': 'roundtrip',
        'email': 'rt@example.com',
        'role': 'user',
        'first_name': 'Round',
        'last_name': 'Trip',
        'avatar_url': 'https://example.com/rt.jpg',
        'credits': 75,
        'created_at': '2025-06-01T12:00:00.000Z',
      };
      final profile = UserProfile.fromJson(original);
      final json = profile.toJson();
      expect(json['id'], equals('u_rt'));
      expect(json['username'], equals('roundtrip'));
      expect(json['email'], equals('rt@example.com'));
      expect(json['first_name'], equals('Round'));
      expect(json['credits'], equals(75));
    });
  });
}
