class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    required this.timestampUtc,
    this.accuracyMeters,
    this.altitudeMeters,
  });

  final double latitude;
  final double longitude;
  final DateTime timestampUtc;
  final double? accuracyMeters;
  final double? altitudeMeters;
}

class QuestEvidence {
  const QuestEvidence({
    required this.id,
    required this.questId,
    required this.photoPath,
    required this.point,
    required this.capturedAtUtc,
    required this.caption,
  });

  final String id;
  final String questId;
  final String photoPath;
  final GeoPoint point;
  final DateTime capturedAtUtc;
  final String caption;
}

class RunQuestResult {
  const RunQuestResult({
    required this.questId,
    required this.title,
    required this.completed,
    this.skipped = false,
  });

  final String questId;
  final String title;
  final bool completed;
  final bool skipped;
}

class CachedWeather {
  const CachedWeather({
    required this.summary,
    required this.temperatureCelsius,
    required this.observedAtUtc,
  });

  final String summary;
  final double temperatureCelsius;
  final DateTime observedAtUtc;
}

class RunSummary {
  RunSummary({
    required this.id,
    required this.startedAtUtc,
    required this.activeDuration,
    required this.distanceMeters,
    required this.locationName,
    required List<GeoPoint> track,
    required List<String> landmarks,
    required List<RunQuestResult> quests,
    required List<QuestEvidence> evidence,
    this.averagePaceSecondsPerKilometer,
    this.estimatedCalories,
    this.cachedWeather,
  })  : track = List.unmodifiable(track),
        landmarks = List.unmodifiable(landmarks),
        quests = List.unmodifiable(quests),
        evidence = List.unmodifiable(evidence) {
    if (!startedAtUtc.isUtc) {
      throw ArgumentError.value(
        startedAtUtc,
        'startedAtUtc',
        'Run timestamps must use UTC.',
      );
    }
    if (distanceMeters < 0 || activeDuration.isNegative) {
      throw ArgumentError('Run distance and duration cannot be negative.');
    }
  }

  final String id;
  final DateTime startedAtUtc;
  final Duration activeDuration;
  final double distanceMeters;
  final double? averagePaceSecondsPerKilometer;
  final String locationName;
  final List<GeoPoint> track;
  final List<String> landmarks;
  final List<RunQuestResult> quests;
  final List<QuestEvidence> evidence;
  final int? estimatedCalories;
  final CachedWeather? cachedWeather;
}
