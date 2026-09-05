import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/fixtures/fake_story_services.dart';
import 'package:questory/features/story_studio/data/story_templates.dart';
import 'package:questory/features/story_studio/presentation/story_studio_screen.dart';

void main() {
  testWidgets('edits, saves, reopens, exports, and shares a fixture story', (
    tester,
  ) async {
    final repository = FakeStoryRepository();
    final renderer = FakeStoryRenderer(path: '/cache/story.png');
    final shareService = FakeShareService();
    await tester.pumpWidget(
      MaterialApp(
        home: StoryStudioScreen(
          repository: repository,
          renderer: renderer,
          shareService: shareService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Story Studio'), findsOneWidget);
    expect(find.text('City Sprint'), findsOneWidget);
    expect(find.text('Film Roll'), findsOneWidget);
    expect(find.text('Postcard Trail'), findsOneWidget);

    await tester.tap(find.text('Film Roll'));
    await tester.pumpAndSettle();

    const photoKey = ValueKey('draft-film-roll-photo-one');
    expect(find.byKey(photoKey), findsOneWidget);
    await tester.tap(find.byKey(photoKey));
    await tester.pump();
    expect(find.textContaining('Selected:'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('story-rotate-left')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-story')));
    await tester.pumpAndSettle();
    expect(find.text('Editable project saved locally.'), findsOneWidget);

    final saved = await repository.load('draft-film-roll');
    expect(saved, isNotNull);
    final savedRotation =
        saved!.elementById('draft-film-roll-photo-one')!.transform.rotation;

    await tester.tap(find.byKey(const ValueKey('story-rotate-left')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('reopen-story')));
    await tester.pumpAndSettle();
    expect(
      find.text('Saved project reopened with its edits and layer order.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('export-story')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Export ready: 1080 x 1920 PNG. Android share sheet opened.',
      ),
      findsOneWidget,
    );
    expect(renderer.lastDocument, isNotNull);
    expect(
      renderer.lastDocument!
          .elementById('draft-film-roll-photo-one')!
          .transform
          .rotation,
      savedRotation,
    );
    expect(shareService.sharedPath, '/cache/story.png');
  });

  testWidgets('supports duplicate, delete, undo, and export error feedback', (
    tester,
  ) async {
    final renderer = FakeStoryRenderer(
      failure: StateError('encoder unavailable'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StoryStudioScreen(
          renderer: renderer,
          shareService: FakeShareService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const heroKey = ValueKey('draft-city-sprint-hero-photo');
    await tester.tap(find.byKey(heroKey));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('duplicate-story-element')),
    );
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('draft-city-sprint-hero-photo-copy-1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('delete-story-element')));
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('draft-city-sprint-hero-photo-copy-1'),
      ),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('undo-story')));
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('draft-city-sprint-hero-photo-copy-1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('export-story')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Export failed:'), findsOneWidget);
    expect(find.textContaining('encoder unavailable'), findsOneWidget);
  });

  testWidgets('cancelling text edits keeps the editor stable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StoryStudioScreen(
          repository: FakeStoryRepository(),
          renderer: FakeStoryRenderer(),
          shareService: FakeShareService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const titleKey = ValueKey('draft-city-sprint-title');
    await tester.tap(find.byKey(titleKey));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('edit-story-text')));
    await tester.pumpAndSettle();

    expect(find.text('Edit element text'), findsOneWidget);
    final originalText = tester
        .widget<TextField>(find.byKey(const ValueKey('story-text-field')))
        .controller!
        .text;
    await tester.enterText(find.byType(TextField), 'This should be discarded');
    await tester.tap(find.text('CANCEL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Edit element text'), findsNothing);
    expect(find.text('This should be discarded'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('edit-story-text')));
    await tester.pumpAndSettle();
    final reopenedField = tester.widget<TextField>(
      find.byKey(const ValueKey('story-text-field')),
    );
    expect(reopenedField.controller!.text, originalText);
    await tester.tap(find.byKey(const ValueKey('cancel-story-text')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('story-rotate-left')));
    await tester.pump();
    expect(find.byKey(titleKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remains usable on a small Android-sized screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: StoryStudioScreen(
          repository: FakeStoryRepository(),
          renderer: FakeStoryRenderer(),
          shareService: FakeShareService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Story Studio'), findsOneWidget);
    expect(find.text('City Sprint'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Film Roll'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('draft-film-roll-photo-one')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selects an initial document template and protects unsaved edits',
      (
    tester,
  ) async {
    final initial = storyTemplates[1].createDocument(
      documentId: 'story-run-film-roll',
      sourceRunId: 'run',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StoryStudioScreen(
          initialDocument: initial,
          repository: FakeStoryRepository(),
          renderer: FakeStoryRenderer(),
          shareService: FakeShareService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final filmRoll = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Film Roll'),
    );
    expect(filmRoll.selected, isTrue);

    await tester
        .tap(find.byKey(const ValueKey('story-run-film-roll-photo-one')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('story-rotate-left')));
    await tester.pump();
    await tester.tap(find.text('City Sprint'));
    await tester.pumpAndSettle();

    expect(find.text('Switch template?'), findsOneWidget);
    await tester.tap(find.text('KEEP EDITING'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Film Roll'))
          .selected,
      isTrue,
    );
  });
}
