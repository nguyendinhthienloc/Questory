import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questory/screens/friend_tracks.dart';
import 'package:questory/screens/home.dart';
import 'package:questory/screens/preview.dart';

void main() {
  testWidgets('adds a mock friend and delivers a Track while online', (
    tester,
  ) async {
    CapturedQuestPhoto? accepted;
    await _pumpTracks(tester, onAccepted: (photo) => accepted = photo);

    expect(find.text('TRACKS'), findsOneWidget);
    expect(find.text('3 FRIENDS'), findsOneWidget);
    expect(find.text('Mock friends online'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('add-friends')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('friend-name')),
      'Mai',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-add-friend')));
    await tester.pumpAndSettle();
    expect(find.text('4 FRIENDS'), findsOneWidget);

    await _captureAndAccept(tester, caption: 'Sunset with the crew');

    expect(accepted, isNotNull);
    expect(accepted!.delivery, TrackDelivery.delivered);
    expect(accepted!.sharedWith, containsAll(['Minh', 'An', 'Linh', 'Mai']));
    expect(find.byType(CapturedTrackPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipes through bundled friend Tracks and reacts', (
    tester,
  ) async {
    await _pumpTracks(tester, onAccepted: (_) {});

    expect(
        find.byKey(const ValueKey('view-friend-tracks-hint')), findsOneWidget);
    expect(find.text('SWIPE UP TO VIEW 4 TRACKS'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('tracks-page-view')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('track-friend-post-minh-sunrise')),
      findsOneWidget,
    );
    expect(
        find.text('Sunrise miles before the city wakes up.'), findsOneWidget);
    expect(
        find.text('Tran Phu Beach, Nha Trang  •  12 min ago'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('react-to-minh')));
    await tester.pumpAndSettle();
    expect(find.text('9'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('tracks-page-view')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('track-friend-post-an-nguyen-hue')),
      findsOneWidget,
    );
    expect(find.text('Quick lace check, then one more city loop.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps an offline Track and queues friend sharing', (
    tester,
  ) async {
    CapturedQuestPhoto? accepted;
    await _pumpTracks(tester, onAccepted: (photo) => accepted = photo);

    await tester.tap(find.byKey(const ValueKey('tracks-online-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Offline: shares queue locally'), findsOneWidget);

    await _captureAndAccept(tester, caption: 'Offline coastal Track');

    expect(accepted, isNotNull);
    expect(accepted!.caption, 'Offline coastal Track');
    expect(accepted!.delivery, TrackDelivery.queued);
    expect(accepted!.bytes, isNotEmpty);
    expect(find.byType(CapturedTrackPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpTracks(
  WidgetTester tester, {
  required ValueChanged<CapturedQuestPhoto> onAccepted,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(
        forceDemoMode: true,
        onPhotoAccepted: onAccepted,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _captureAndAccept(
  WidgetTester tester, {
  required String caption,
}) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  final demoButton = find.byKey(const ValueKey('use-demo-photo'));
  await tester.scrollUntilVisible(
    demoButton,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(demoButton);
  await tester.pumpAndSettle();

  expect(find.text('Share a Track'), findsOneWidget);
  await tester.enterText(
    find.byKey(const ValueKey('quest-photo-caption')),
    caption,
  );
  final accept = find.byKey(const ValueKey('accept-quest-photo'));
  final reviewScroll = find.descendant(
    of: find.byType(PhotoReviewSheet),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(
    accept,
    220,
    scrollable: reviewScroll.first,
  );
  await tester.pumpAndSettle();
  await tester.tap(accept);
  await tester.pumpAndSettle();
}
