import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/features/projects/domain/project.dart';
import 'package:visiobook_mobile/features/projects/presentation/widgets/project_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  Project createProject({
    String title = 'Mon Projet',
    ProjectStatus status = ProjectStatus.draft,
  }) {
    return Project(
      id: 'project-1',
      title: title,
      status: status,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  group('ProjectCard', () {
    testWidgets('renders project title', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          ProjectCard(project: createProject(title: 'Test VisioBook')),
        ),
      );

      expect(find.text('Test VisioBook'), findsOneWidget);
    });

    testWidgets('shows status badge for draft', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          ProjectCard(project: createProject(status: ProjectStatus.draft)),
        ),
      );

      expect(find.text('Brouillon'), findsOneWidget);
    });

    testWidgets('shows status badge for ready', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          ProjectCard(project: createProject(status: ProjectStatus.ready)),
        ),
      );

      expect(find.text('Prêt'), findsOneWidget);
    });

    testWidgets('shows status badge for error', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          ProjectCard(project: createProject(status: ProjectStatus.error)),
        ),
      );

      expect(find.text('Erreur'), findsOneWidget);
    });

    testWidgets('shows progress bar when generationProgress is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          ProjectCard(
            project: createProject(status: ProjectStatus.processing),
            generationProgress: 0.5,
          ),
        ),
      );

      // Should show progress indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      // Should show percentage text
      expect(find.textContaining('50%'), findsOneWidget);
    });

    testWidgets('does not show progress bar for draft project', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          ProjectCard(project: createProject(status: ProjectStatus.draft)),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapWithMaterial(
          ProjectCard(project: createProject(), onTap: () => tapped = true),
        ),
      );

      await tester.tap(find.byType(ProjectCard));
      expect(tapped, isTrue);
    });

    testWidgets('renders placeholder when no cover URL', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(ProjectCard(project: createProject())),
      );

      // Should render without errors and find the widget
      expect(find.byType(ProjectCard), findsOneWidget);
    });
  });
}
