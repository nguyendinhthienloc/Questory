import '../core/contracts/achievement_repository.dart';
import '../core/contracts/clock.dart';
import '../core/contracts/destination_repository.dart';
import '../core/contracts/location_tracker.dart';
import '../core/contracts/photo_store.dart';
import '../core/contracts/run_repository.dart';
import '../core/contracts/share_service.dart';
import '../core/contracts/story_repository.dart';
import '../data/local/app_photo_store.dart';
import '../data/local/bundled_destination_repository.dart';
import '../data/local/questory_database.dart';
import '../data/repositories/geolocator_location_tracker.dart';
import '../data/repositories/sqlite_achievement_repository.dart';
import '../data/repositories/sqlite_run_repository.dart';
import '../data/repositories/sqlite_story_repository.dart';
import '../features/story_studio/application/story_export_services.dart';

class AppDependencies {
  const AppDependencies({
    required this.destinations,
    required this.runs,
    required this.stories,
    required this.achievements,
    required this.locationTracker,
    required this.photoStore,
    required this.clock,
    required this.shareService,
  });

  final DestinationRepository destinations;
  final RunRepository runs;
  final StoryRepository stories;
  final AchievementRepository achievements;
  final LocationTracker locationTracker;
  final PhotoStore photoStore;
  final Clock clock;
  final ShareService shareService;

  static Future<AppDependencies> create() async {
    final database = await QuestoryDatabase.open();
    return AppDependencies(
      destinations: BundledDestinationRepository(),
      runs: SqliteRunRepository(database),
      stories: SqliteStoryRepository(database),
      achievements: SqliteAchievementRepository(database),
      locationTracker: const GeolocatorLocationTracker(),
      photoStore: const AppPhotoStore(),
      clock: const SystemClock(),
      shareService: const AndroidShareService(),
    );
  }
}
