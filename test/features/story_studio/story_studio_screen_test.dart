import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questory/features/story_studio/presentation/story_studio_screen.dart';

void main() {
  testWidgets('switches templates and selects a rendered element', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: StoryStudioScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Story Studio'), findsOneWidget);
    expect(find.text('City Sprint'), findsOneWidget);
    expect(find.text('Film Roll'), findsOneWidget);
    expect(find.text('Postcard Trail'), findsOneWidget);

    await tester.tap(find.text('Film Roll'));
    await tester.pumpAndSettle();

    expect(find.text('THE CITY, ON FILM'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('draft-film-roll-photo-one')));
    await tester.pump();

    expect(find.text('Selected: draft-film-roll-photo-one'), findsOneWidget);
  });
}
