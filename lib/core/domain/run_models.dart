/// Shared models for recorded runs, GPS points, and quest evidence.
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

  Map<String, Object?> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestampUtc': timestampUtc.toIso8601String(),
        'accuracyMeters': accuracyMeters,
        'altitudeMeters': altitudeMeters,
      };

  factory GeoPoint.fromJson(Map<String, Object?> json) => GeoPoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timestampUtc: DateTime.parse(json['timestampUtc'] as String).toUtc(),
        accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
        altitudeMeters: (json['altitudeMeters'] as num?)?.toDouble(),
      );
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

  Map<String, Object?> toJson() => {
        'id': id,
        'questId': questId,
        'photoPath': photoPath,
        'point': point.toJson(),
        'capturedAtUtc': capturedAtUtc.toIso8601String(),
        'caption': caption,
      };

  factory QuestEvidence.fromJson(Map<String, Object?> json) => QuestEvidence(
        id: json['id'] as String,
        questId: json['questId'] as String,
        photoPath: json['photoPath'] as String,
        point: GeoPoint.fromJson(
          Map<String, Object?>.from(json['point'] as Map),
        ),
        capturedAtUtc: DateTime.parse(json['capturedAtUtc'] as String).toUtc(),
        caption: json['caption'] as String? ?? '',
      );
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

  Map<String, Object?> toJson() => {
        'questId': questId,
        'title': title,
        'completed': completed,
        'skipped': skipped,
      };

  factory RunQuestResult.fromJson(Map<String, Object?> json) => RunQuestResult(
        questId: json['questId'] as String,
        title: json['title'] as String,
        completed: json['completed'] as bool? ?? false,
        skipped: json['skipped'] as bool? ?? false,
      );
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

  Map<String, Object?> toJson() => {
        'summary': summary,
        'temperatureCelsius': temperatureCelsius,
        'observedAtUtc': observedAtUtc.toIso8601String(),
      };

  factory CachedWeather.fromJson(Map<String, Object?> json) => CachedWeather(
        summary: json['summary'] as String,
        temperatureCelsius: (json['temperatureCelsius'] as num).toDouble(),
        observedAtUtc: DateTime.parse(json['observedAtUtc'] as String).toUtc(),
      );
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

  Map<String, Object?> toJson() => {
        'id': id,
        'startedAtUtc': startedAtUtc.toIso8601String(),
        'activeDurationSeconds': activeDuration.inSeconds,
        'distanceMeters': distanceMeters,
        'averagePaceSecondsPerKilometer': averagePaceSecondsPerKilometer,
        'locationName': locationName,
        'track': track.map((point) => point.toJson()).toList(),
        'landmarks': landmarks,
        'quests': quests.map((quest) => quest.toJson()).toList(),
        'evidence': evidence.map((item) => item.toJson()).toList(),
        'estimatedCalories': estimatedCalories,
        'cachedWeather': cachedWeather?.toJson(),
      };

  factory RunSummary.fromJson(Map<String, Object?> json) => RunSummary(
        id: json['id'] as String,
        startedAtUtc: DateTime.parse(json['startedAtUtc'] as String).toUtc(),
        activeDuration: Duration(
          seconds: (json['activeDurationSeconds'] as num).round(),
        ),
        distanceMeters: (json['distanceMeters'] as num).toDouble(),
        averagePaceSecondsPerKilometer:
            (json['averagePaceSecondsPerKilometer'] as num?)?.toDouble(),
        locationName: json['locationName'] as String,
        track: (json['track'] as List)
            .map(
              (item) => GeoPoint.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList(),
        landmarks: List<String>.from(json['landmarks'] as List),
        quests: (json['quests'] as List)
            .map(
              (item) => RunQuestResult.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList(),
        evidence: (json['evidence'] as List)
            .map(
              (item) => QuestEvidence.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList(),
        estimatedCalories: (json['estimatedCalories'] as num?)?.round(),
        cachedWeather: json['cachedWeather'] == null
            ? null
            : CachedWeather.fromJson(
                Map<String, Object?>.from(json['cachedWeather'] as Map),
              ),
      );
}
