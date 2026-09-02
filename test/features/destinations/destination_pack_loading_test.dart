import 'package:flutter_test/flutter_test.dart';
import 'package:questory/data/local/bundled_destination_repository.dart';
import 'package:questory/features/destinations/application/quest_location_checker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads both versioned offline city packs', () async {
    final packs = await BundledDestinationRepository().listPacks();

    expect(packs, hasLength(2));
    expect(
        packs.map((pack) => pack.id),
        containsAll([
          'nha-trang',
          'ho-chi-minh-city',
        ]));
    for (final pack in packs) {
      expect(pack.schemaVersion, 1);
      expect(pack.routes, isNotEmpty);
      expect(pack.quests, isNotEmpty);
      expect(pack.pointsOfInterest, isNotEmpty);
      expect(
        pack.routes.expand((route) => route.questIds),
        everyElement(isIn(pack.quests.map((quest) => quest.id))),
      );
      for (final route in pack.routes) {
        var polylineMeters = 0.0;
        for (var index = 1; index < route.expectedPolyline.length; index++) {
          polylineMeters += QuestLocationChecker.distanceBetween(
            route.expectedPolyline[index - 1],
            route.expectedPolyline[index],
          );
        }
        expect(
          route.distanceMeters,
          closeTo(polylineMeters, polylineMeters * 0.15),
          reason: '${route.name} should match its bundled offline polyline.',
        );
      }
    }
  });
}
