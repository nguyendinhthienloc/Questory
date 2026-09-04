import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questory/app/questory_app.dart';
import 'package:questory/core/fixtures/fake_story_services.dart';

void main() {
  testWidgets('launches Questory and connects a completed run to Story Studio',
      (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      QuestoryStoryDemoApp(storyRepository: FakeStoryRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('QUESTORY'), findsOneWidget);
    expect(find.text('Turn one city run\ninto a story.'), findsOneWidget);
    expect(find.text('Add Friends'), findsNothing);
    expect(tester.takeException(), isNull);

    final openRun = find.byKey(const ValueKey('open-demo-run'));
    await tester.scrollUntilVisible(
      openRun,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(openRun);
    await tester.pumpAndSettle();

    expect(find.text('Run recap'), findsOneWidget);
    expect(find.text('5.42 km'), findsOneWidget);
    expect(find.text('QUESTS COMPLETED'), findsOneWidget);

    final createStory = find.byKey(const ValueKey('create-story-from-run'));
    await tester.scrollUntilVisible(
      createStory,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(createStory);
    await tester.pumpAndSettle();

    expect(find.text('Story Studio'), findsOneWidget);
    expect(find.text('City Sprint'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shares one mock repository across navigation and editor saves', (
    tester,
  ) async {
    final repository = FakeStoryRepository();
    await tester.pumpWidget(QuestoryStoryDemoApp(storyRepository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-studio')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(find.textContaining('No draft saved yet'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('open-story-studio')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-story-studio')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('save-story')));
    await tester.tap(find.byKey(const ValueKey('save-story')));
    await tester.pumpAndSettle();
    expect(find.text('Editable project saved locally.'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(find.text('1 editable draft saved for this demo session.'),
        findsOneWidget);
    expect((await repository.list()).length, 1);
  });

  testWidgets('bottom navigation exposes Studio and Runs on a small screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      QuestoryStoryDemoApp(storyRepository: FakeStoryRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-runs')));
    await tester.pumpAndSettle();
    expect(find.text('Runs ready\nfor stories.'), findsOneWidget);
    expect(find.byKey(const ValueKey('history-demo-run')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('nav-studio')));
    await tester.pumpAndSettle();
    expect(find.text('Your run,\nyour layout.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
