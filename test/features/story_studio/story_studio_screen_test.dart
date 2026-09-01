import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/fixtures/fake_story_services.dart';
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
}
