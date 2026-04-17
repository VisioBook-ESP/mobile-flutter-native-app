import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/projects/data/project_service.dart';
import 'package:visiobook_mobile/features/projects/domain/project.dart';
import 'package:visiobook_mobile/features/projects/presentation/providers/project_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProjectProvider provider;

  setUp(() {
    EnvironmentConfig.useMockData = true;
    final storage = SecureStorageService();
    final apiClient = ApiClient(storage: storage);
    final projectService = ProjectService(apiClient: apiClient);
    provider = ProjectProvider(projectService: projectService);
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
    provider.dispose();
  });

  group('ProjectProvider', () {
    test('initial state is correct', () {
      expect(provider.state, ProjectsState.initial);
      expect(provider.projects, isEmpty);
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('loadProjects in mock mode returns mock projects', () async {
      await provider.loadProjects();

      expect(provider.state, ProjectsState.loaded);
      expect(provider.projects, isNotEmpty);
      // Mock data has 9 projects total
      expect(provider.projects.length, 9);
    });

    test('readyProjects filters correctly', () async {
      await provider.loadProjects();

      final ready = provider.readyProjects;
      expect(ready, isNotEmpty);
      for (final project in ready) {
        expect(project.status, ProjectStatus.ready);
      }
      // Mock data has 5 ready projects (ids 1, 2, 5, 6, 7)
      expect(ready.length, 5);
    });

    test('draftProjects filters correctly', () async {
      await provider.loadProjects();

      final drafts = provider.draftProjects;
      expect(drafts, isNotEmpty);
      for (final project in drafts) {
        expect(project.status, isNot(ProjectStatus.ready));
      }
      // Mock data has 4 non-ready projects (ids 3, 4, 8, 9)
      expect(drafts.length, 4);
    });

    test('recentProjects returns max 4, sorted by date', () async {
      await provider.loadProjects();

      final recent = provider.recentProjects;
      expect(recent.length, 4);

      // Verify sorted by updatedAt descending
      for (int i = 0; i < recent.length - 1; i++) {
        expect(
          recent[i].updatedAt.isAfter(recent[i + 1].updatedAt) ||
              recent[i].updatedAt.isAtSameMomentAs(recent[i + 1].updatedAt),
          isTrue,
        );
      }
    });

    test('textsCount returns correct count', () async {
      await provider.loadProjects();

      expect(provider.textsCount, 9);
    });

    test('clearError resets error', () {
      // Provider error is null initially, set it indirectly is hard,
      // but we can verify clearError calls notifyListeners and sets null
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('loadProjects sorts projects correctly in mock mode', () async {
      await provider.loadProjects();

      // Verify all 9 mock projects are loaded
      expect(provider.projects.length, 9);

      // recentProjects should be sorted by updatedAt descending
      final recent = provider.recentProjects;
      for (int i = 0; i < recent.length - 1; i++) {
        expect(
          recent[i].updatedAt.isAfter(recent[i + 1].updatedAt) ||
              recent[i].updatedAt.isAtSameMomentAs(recent[i + 1].updatedAt),
          isTrue,
        );
      }
    });

    test('loadProjects notifies listeners', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadProjects();

      // At least 2: loading + loaded
      expect(notifyCount, greaterThanOrEqualTo(2));
    });

    test('clearError notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearError();

      expect(notifyCount, 1);
    });

    test('projects list updates correctly after multiple loads', () async {
      await provider.loadProjects();
      final count1 = provider.projects.length;

      await provider.loadProjects();
      final count2 = provider.projects.length;

      // Mock data is deterministic; reloading should yield the same result
      expect(count1, count2);
    });

    test('draftProjects returns non-ready projects', () async {
      await provider.loadProjects();

      final drafts = provider.draftProjects;
      for (final p in drafts) {
        expect(p.status, isNot(ProjectStatus.ready));
      }
    });
  });
}
