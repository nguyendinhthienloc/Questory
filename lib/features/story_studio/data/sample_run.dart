import '../../../core/domain/run_models.dart';

final RunSummary sampleRunSummary = RunSummary(
  id: 'run-nha-trang-coast-001',
  startedAtUtc: DateTime.utc(2026, 9, 1, 23, 15),
  activeDuration: const Duration(minutes: 31, seconds: 9),
  distanceMeters: 5420,
  averagePaceSecondsPerKilometer: 345,
  locationName: 'Nha Trang, Vietnam',
  track: [
    GeoPoint(
      latitude: 12.2388,
      longitude: 109.1967,
      timestampUtc: DateTime.utc(2026, 9, 1, 23, 15),
    ),
    GeoPoint(
      latitude: 12.2421,
      longitude: 109.1988,
      timestampUtc: DateTime.utc(2026, 9, 1, 23, 25),
    ),
    GeoPoint(
      latitude: 12.2491,
      longitude: 109.1954,
      timestampUtc: DateTime.utc(2026, 9, 1, 23, 35),
    ),
    GeoPoint(
      latitude: 12.2533,
      longitude: 109.2012,
      timestampUtc: DateTime.utc(2026, 9, 1, 23, 46, 9),
    ),
  ],
  landmarks: const ['Tram Huong Tower', 'Tran Phu Beach'],
  quests: const [
    RunQuestResult(
      questId: 'quest-sunrise',
      title: 'Sunrise by the sea',
      completed: true,
    ),
    RunQuestResult(
      questId: 'quest-breakfast',
      title: 'Local breakfast',
      completed: true,
    ),
    RunQuestResult(
      questId: 'quest-architecture',
      title: 'Hidden architecture',
      completed: true,
    ),
  ],
  evidence: [
    QuestEvidence(
      id: 'evidence-sunrise',
      questId: 'quest-sunrise',
      photoPath: 'fixture://nha-trang-sunrise.jpg',
      point: GeoPoint(
        latitude: 12.2388,
        longitude: 109.1967,
        timestampUtc: DateTime.utc(2026, 9, 1, 23, 18),
      ),
      capturedAtUtc: DateTime.utc(2026, 9, 1, 23, 18),
      caption: 'First light along Tran Phu.',
    ),
    QuestEvidence(
      id: 'evidence-breakfast',
      questId: 'quest-breakfast',
      photoPath: 'fixture://nha-trang-breakfast.jpg',
      point: GeoPoint(
        latitude: 12.2421,
        longitude: 109.1988,
        timestampUtc: DateTime.utc(2026, 9, 1, 23, 27),
      ),
      capturedAtUtc: DateTime.utc(2026, 9, 1, 23, 27),
      caption: 'A well-earned local breakfast.',
    ),
  ],
  estimatedCalories: 326,
  cachedWeather: CachedWeather(
    summary: 'Clear',
    temperatureCelsius: 27,
    observedAtUtc: DateTime.utc(2026, 9, 1, 23),
  ),
);
