import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient apiClient;

  setUp(() {
    // Mock the flutter_secure_storage platform channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'read') {
              return null; // No token stored
            }
            if (methodCall.method == 'write') {
              return null;
            }
            if (methodCall.method == 'delete') {
              return null;
            }
            if (methodCall.method == 'deleteAll') {
              return null;
            }
            return null;
          },
        );

    EnvironmentConfig.setEnvironment(Environment.prod);
    apiClient = ApiClient(storage: SecureStorageService());
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          null,
        );
  });

  group('ApiClient constructor', () {
    test('creates instance with Dio', () {
      expect(apiClient, isNotNull);
      expect(apiClient.dio, isA<Dio>());
    });

    test('Dio has correct base options', () {
      final options = apiClient.dio.options;
      expect(options.connectTimeout, const Duration(seconds: 30));
      expect(options.receiveTimeout, const Duration(seconds: 30));
      expect(options.headers['Content-Type'], 'application/json');
      expect(options.headers['Accept'], 'application/json');
    });

    test('Dio has auth interceptor', () {
      expect(apiClient.dio.interceptors, isNotEmpty);
    });
  });

  group('ApiClient auth endpoints', () {
    test('authRegister calls correct URL', () async {
      try {
        await apiClient.authRegister({'email': 'a@b.c', 'password': '123'});
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/auth/register'));
      }
    });

    test('authLogin calls correct URL', () async {
      try {
        await apiClient.authLogin({'email': 'a@b.c', 'password': '123'});
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/auth/login'));
      }
    });

    test('authRefresh calls correct URL', () async {
      try {
        await apiClient.authRefresh('fake-token');
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/auth/refresh'));
      }
    });

    test('authVerify calls correct URL', () async {
      try {
        await apiClient.authVerify('fake-token');
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/auth/verify'));
      }
    });
  });

  group('ApiClient project endpoints', () {
    test('getProjects calls correct URL', () async {
      try {
        await apiClient.getProjects();
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/projects'));
      }
    });

    test('getRecentProjects calls correct URL', () async {
      try {
        await apiClient.getRecentProjects();
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/projects/recent'));
      }
    });

    test('getProject calls correct URL with id', () async {
      try {
        await apiClient.getProject('test-id');
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/projects/test-id'));
      }
    });

    test('createProject calls correct URL', () async {
      try {
        await apiClient.createProject({'name': 'test'});
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/projects'));
      }
    });

    test('generateProject calls correct URL', () async {
      try {
        await apiClient.generateProject({'id': 'test'});
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/projects/generate'));
      }
    });

    test('updateProject calls correct URL with id', () async {
      try {
        await apiClient.updateProject('test-id', {'name': 'updated'});
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/projects/test-id'));
      }
    });

    test('deleteProject calls correct URL with id', () async {
      try {
        await apiClient.deleteProject('test-id');
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/projects/test-id'));
      }
    });
  });

  group('ApiClient version & workflow endpoints', () {
    test('createVersion calls correct URL', () async {
      try {
        await apiClient.createVersion('proj-1');
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/projects/proj-1/versions'));
      }
    });

    test('startWorkflow calls correct URL', () async {
      try {
        await apiClient.startWorkflow('proj-1', 'ver-1');
      } on DioException catch (e) {
        expect(
          e.requestOptions.path,
          contains('/projects/proj-1/versions/ver-1/workflow/start'),
        );
      }
    });

    test('getWorkflowStatus calls correct URL', () async {
      try {
        await apiClient.getWorkflowStatus('proj-1', 'ver-1', 'exec-1');
      } on DioException catch (e) {
        expect(
          e.requestOptions.path,
          contains('/projects/proj-1/versions/ver-1/workflow/status/exec-1'),
        );
      }
    });

    test('cancelWorkflow calls correct URL', () async {
      try {
        await apiClient.cancelWorkflow('proj-1', 'ver-1', 'exec-1');
      } on DioException catch (e) {
        expect(
          e.requestOptions.path,
          contains('/projects/proj-1/versions/ver-1/workflow/cancel/exec-1'),
        );
      }
    });

    test('retryWorkflow calls correct URL', () async {
      try {
        await apiClient.retryWorkflow('proj-1', 'ver-1', 'exec-1');
      } on DioException catch (e) {
        expect(
          e.requestOptions.path,
          contains('/projects/proj-1/versions/ver-1/workflow/retry/exec-1'),
        );
      }
    });
  });

  group('ApiClient content endpoints', () {
    test('getContent calls correct URL', () async {
      try {
        await apiClient.getContent('proj-1');
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/projects/proj-1/content'));
      }
    });

    test('updateContent calls correct URL', () async {
      try {
        await apiClient.updateContent('proj-1', {'text': 'hello'});
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/projects/proj-1/content'));
      }
    });

    test('getScenes calls correct URL', () async {
      try {
        await apiClient.getScenes('proj-1');
      } on DioException catch (e) {
        expect(
          e.requestOptions.path,
          contains('/projects/proj-1/content/scenes'),
        );
      }
    });

    test('getContentSummary calls correct URL', () async {
      try {
        await apiClient.getContentSummary('proj-1');
      } on DioException catch (e) {
        expect(
          e.requestOptions.path,
          contains('/projects/proj-1/content/summary'),
        );
      }
    });

    test('updateScene calls correct URL', () async {
      try {
        await apiClient.updateScene('proj-1', 'scene-1', {'text': 'hi'});
      } on DioException catch (e) {
        expect(
          e.requestOptions.path,
          contains('/projects/proj-1/content/scenes/scene-1'),
        );
      }
    });

    test('getCharacters calls correct URL', () async {
      try {
        await apiClient.getCharacters('proj-1');
      } on DioException catch (e) {
        expect(
          e.requestOptions.path,
          contains('/projects/proj-1/content/characters'),
        );
      }
    });
  });

  group('ApiClient share endpoints', () {
    test('shareProject calls correct URL', () async {
      try {
        await apiClient.shareProject('proj-1', {'email': 'a@b.c'});
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/projects/proj-1/share'));
      }
    });

    test('getShareLinks calls correct URL', () async {
      try {
        await apiClient.getShareLinks('proj-1');
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/projects/proj-1/share'));
      }
    });

    test('deleteShareLinks calls correct URL', () async {
      try {
        await apiClient.deleteShareLinks('proj-1');
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/projects/proj-1/share'));
      }
    });
  });

  group('ApiClient visiobook endpoint', () {
    test('getVisioBook calls correct URL', () async {
      try {
        await apiClient.getVisioBook('proj-1');
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/projects/proj-1/visiobook'));
      }
    });
  });

  group('ApiClient ingestion endpoints', () {
    test('getFilesByToken calls correct URL', () async {
      try {
        await apiClient.getFilesByToken();
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/folders/files'));
      }
    });

    test('uploadFile calls correct URL', () async {
      try {
        await apiClient.uploadFile(FormData());
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/upload/'));
      }
    });

    test('startIngestion calls correct URL', () async {
      try {
        await apiClient.startIngestion({'file': 'test'});
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/ingest/'));
      }
    });

    test('getIngestionStatus calls correct URL', () async {
      try {
        await apiClient.getIngestionStatus('job-1');
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/ingest/status/job-1'));
      }
    });

    test('extractText calls correct URL', () async {
      try {
        await apiClient.extractText(FormData());
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/extract/text'));
      }
    });

    test('extractMetadata calls correct URL', () async {
      try {
        await apiClient.extractMetadata(FormData());
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/extract/metadata'));
      }
    });

    test('getDownloadUrl calls correct URL', () async {
      try {
        await apiClient.getDownloadUrl('vid-1');
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/storage/download/vid-1'));
      }
    });
  });

  group('ApiClient profile endpoints', () {
    test('getProfile calls correct URL', () async {
      try {
        await apiClient.getProfile();
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/users/me'));
      }
    });

    test('updateProfile calls correct URL', () async {
      try {
        await apiClient.updateProfile({'name': 'test'});
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/users/me'));
      }
    });

    test('deleteAccount calls correct URL', () async {
      try {
        await apiClient.deleteAccount();
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/users/me'));
      }
    });
  });

  group('ApiClient payment endpoints', () {
    test('getSubscriptionPlans calls correct URL', () async {
      try {
        await apiClient.getSubscriptionPlans();
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/subscriptions/plans'));
      }
    });

    test('getCurrentSubscription calls correct URL', () async {
      try {
        await apiClient.getCurrentSubscription();
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/subscriptions/current'));
      }
    });

    test('createCheckoutSession calls correct URL', () async {
      try {
        await apiClient.createCheckoutSession({'plan': 'pro'});
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/subscriptions/checkout'));
      }
    });

    test('cancelSubscription calls correct URL', () async {
      try {
        await apiClient.cancelSubscription();
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/subscriptions/cancel'));
      }
    });

    test('cancelSubscription with reason calls correct URL', () async {
      try {
        await apiClient.cancelSubscription(reason: 'too expensive');
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/subscriptions/cancel'));
      }
    });

    test('upgradeSubscription calls correct URL', () async {
      try {
        await apiClient.upgradeSubscription('plan-pro');
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/subscriptions/upgrade'));
      }
    });

    test('downgradeSubscription calls correct URL', () async {
      try {
        await apiClient.downgradeSubscription('plan-free');
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/subscriptions/downgrade'));
      }
    });

    test('getStripePortalUrl calls correct URL', () async {
      try {
        await apiClient.getStripePortalUrl();
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/subscriptions/portal'));
      }
    });

    test('getStripePortalUrl with returnUrl calls correct URL', () async {
      try {
        await apiClient.getStripePortalUrl(returnUrl: 'https://example.com');
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/subscriptions/portal'));
      }
    });

    test('getQuota calls correct URL', () async {
      try {
        await apiClient.getQuota();
      } on DioException catch (e) {
        expect(e.requestOptions.path, contains('/quotas'));
      }
    });

    test('createPaymentIntent calls correct URL', () async {
      try {
        await apiClient.createPaymentIntent({'amount': 1000});
      } on DioException catch (e) {
        expect(
          e.requestOptions.path,
          contains('/subscriptions/payment-intent'),
        );
      }
    });
  });
}
