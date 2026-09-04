import 'package:flutter_test/flutter_test.dart';
import 'package:questory/app/app_dependencies.dart';
import 'package:questory/app/main_navigation.dart';
import 'package:questory/core/fixtures/fake_destination_repository.dart';
import 'package:questory/core/fixtures/fake_run_dependencies.dart';
import 'package:questory/core/fixtures/fake_story_services.dart';
import 'package:questory/main.dart';

void main() {
  testWidgets('startup failure is recoverable through the injected loader', (
    tester,
  ) async {
    var attempts = 0;
    Future<AppDependencies> load() async {
      attempts += 1;
      if (attempts == 1) {
        throw StateError('database unavailable');
      }
      return _dependencies();
    }

    await tester.pumpWidget(QuestoryBootstrap(loadDependencies: load));
    await tester.pumpAndSettle();

    expect(find.text('Questory could not open local storage'), findsOneWidget);
    expect(find.textContaining('database unavailable'), findsOneWidget);

    await tester.tap(find.text('TRY AGAIN'));
    await tester.pumpAndSettle();

    expect(find.byType(MainNavigation), findsOneWidget);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });
}

AppDependencies _dependencies() => AppDependencies(
      destinations: FakeDestinationRepository(),
      runs: FakeRunRepository(),
      stories: FakeStoryRepository(),
      achievements: FakeAchievementRepository(),
      locationTracker: FakeLocationTracker(),
      photoStore: FakePhotoStore(),
      clock: FakeClock(DateTime.utc(2026, 9, 4)),
      shareService: FakeShareService(),
    );
