import 'run_models.dart';

enum QuestFallbackType { manualConfirmation, skip }

class Landmark {
  const Landmark({
    required this.id,
    required this.name,
    required this.description,
    required this.point,
  });

  final String id;
  final String name;
  final String description;
  final GeoPoint point;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'point': point.toJson(),
      };

  factory Landmark.fromJson(Map<String, Object?> json) => Landmark(
        id: _string(json, 'id'),
        name: _string(json, 'name'),
        description: _string(json, 'description'),
        point: GeoPoint.fromJson(_map(json, 'point')),
      );
}

class QuestFallback {
  const QuestFallback({
    required this.type,
    required this.instructions,
    this.allowedWhenAccuracyExceedsMeters = 50,
  });

  final QuestFallbackType type;
  final String instructions;
  final double allowedWhenAccuracyExceedsMeters;

  Map<String, Object?> toJson() => {
        'type': type.name,
        'instructions': instructions,
        'allowedWhenAccuracyExceedsMeters': allowedWhenAccuracyExceedsMeters,
      };

  factory QuestFallback.fromJson(Map<String, Object?> json) => QuestFallback(
        type: QuestFallbackType.values.firstWhere(
          (value) => value.name == _string(json, 'type'),
          orElse: () => throw const FormatException(
            'Unsupported quest fallback type.',
          ),
        ),
        instructions: _string(json, 'instructions'),
        allowedWhenAccuracyExceedsMeters: _number(
          json,
          'allowedWhenAccuracyExceedsMeters',
          fallback: 50,
        ),
      );
}

class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.prompt,
    required this.point,
    required this.radiusMeters,
    required this.captionRequired,
    required this.fallback,
    this.landmarkId,
  });

  final String id;
  final String title;
  final String prompt;
  final GeoPoint point;
  final double radiusMeters;
  final bool captionRequired;
  final QuestFallback fallback;
  final String? landmarkId;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'prompt': prompt,
        'point': point.toJson(),
        'radiusMeters': radiusMeters,
        'captionRequired': captionRequired,
        'fallback': fallback.toJson(),
        'landmarkId': landmarkId,
      };

  factory Quest.fromJson(Map<String, Object?> json) => Quest(
        id: _string(json, 'id'),
        title: _string(json, 'title'),
        prompt: _string(json, 'prompt'),
        point: GeoPoint.fromJson(_map(json, 'point')),
        radiusMeters: _number(json, 'radiusMeters'),
        captionRequired: json['captionRequired'] as bool? ?? false,
        fallback: QuestFallback.fromJson(_map(json, 'fallback')),
        landmarkId: json['landmarkId'] as String?,
      );
}

class PointOfInterest {
  PointOfInterest({
    required this.id,
    required this.name,
    required this.description,
    required this.point,
    required List<String> questIds,
  }) : questIds = List.unmodifiable(questIds);

  final String id;
  final String name;
  final String description;
  final GeoPoint point;
  final List<String> questIds;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'point': point.toJson(),
        'questIds': questIds,
      };

  factory PointOfInterest.fromJson(Map<String, Object?> json) =>
      PointOfInterest(
        id: _string(json, 'id'),
        name: _string(json, 'name'),
        description: _string(json, 'description'),
        point: GeoPoint.fromJson(_map(json, 'point')),
        questIds: _strings(json, 'questIds'),
      );
}

class RoutePlan {
  RoutePlan({
    required this.id,
    required this.name,
    required this.description,
    required this.distanceMeters,
    required this.estimatedDuration,
    required this.difficulty,
    required List<GeoPoint> expectedPolyline,
    required List<Landmark> landmarks,
    required List<String> questIds,
    required List<String> safetyNotes,
  })  : expectedPolyline = List.unmodifiable(expectedPolyline),
        landmarks = List.unmodifiable(landmarks),
        questIds = List.unmodifiable(questIds),
        safetyNotes = List.unmodifiable(safetyNotes);

  final String id;
  final String name;
  final String description;
  final double distanceMeters;
  final Duration estimatedDuration;
  final String difficulty;
  final List<GeoPoint> expectedPolyline;
  final List<Landmark> landmarks;
  final List<String> questIds;
  final List<String> safetyNotes;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'distanceMeters': distanceMeters,
        'estimatedDurationSeconds': estimatedDuration.inSeconds,
        'difficulty': difficulty,
        'expectedPolyline':
            expectedPolyline.map((point) => point.toJson()).toList(),
        'landmarks': landmarks.map((item) => item.toJson()).toList(),
        'questIds': questIds,
        'safetyNotes': safetyNotes,
      };

  factory RoutePlan.fromJson(Map<String, Object?> json) => RoutePlan(
        id: _string(json, 'id'),
        name: _string(json, 'name'),
        description: _string(json, 'description'),
        distanceMeters: _number(json, 'distanceMeters'),
        estimatedDuration: Duration(
          seconds: _number(json, 'estimatedDurationSeconds').round(),
        ),
        difficulty: _string(json, 'difficulty'),
        expectedPolyline:
            _maps(json, 'expectedPolyline').map(GeoPoint.fromJson).toList(),
        landmarks: _maps(json, 'landmarks').map(Landmark.fromJson).toList(),
        questIds: _strings(json, 'questIds'),
        safetyNotes: _strings(json, 'safetyNotes'),
      );
}

class DestinationPack {
  DestinationPack({
    required this.schemaVersion,
    required this.packVersion,
    required this.id,
    required this.cityName,
    required this.countryCode,
    required this.description,
    required this.lastReviewedAtUtc,
    required List<RoutePlan> routes,
    required List<Quest> quests,
    required List<PointOfInterest> pointsOfInterest,
  })  : routes = List.unmodifiable(routes),
        quests = List.unmodifiable(quests),
        pointsOfInterest = List.unmodifiable(pointsOfInterest) {
    if (!lastReviewedAtUtc.isUtc) {
      throw ArgumentError('Destination review timestamps must be UTC.');
    }
  }

  final int schemaVersion;
  final String packVersion;
  final String id;
  final String cityName;
  final String countryCode;
  final String description;
  final DateTime lastReviewedAtUtc;
  final List<RoutePlan> routes;
  final List<Quest> quests;
  final List<PointOfInterest> pointsOfInterest;

  Quest? questById(String id) {
    for (final quest in quests) {
      if (quest.id == id) return quest;
    }
    return null;
  }

  RoutePlan? routeById(String id) {
    for (final route in routes) {
      if (route.id == id) return route;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'packVersion': packVersion,
        'id': id,
        'cityName': cityName,
        'countryCode': countryCode,
        'description': description,
        'lastReviewedAtUtc': lastReviewedAtUtc.toIso8601String(),
        'routes': routes.map((item) => item.toJson()).toList(),
        'quests': quests.map((item) => item.toJson()).toList(),
        'pointsOfInterest':
            pointsOfInterest.map((item) => item.toJson()).toList(),
      };

  factory DestinationPack.fromJson(Map<String, Object?> json) {
    final pack = DestinationPack(
      schemaVersion: _number(json, 'schemaVersion').round(),
      packVersion: _string(json, 'packVersion'),
      id: _string(json, 'id'),
      cityName: _string(json, 'cityName'),
      countryCode: _string(json, 'countryCode'),
      description: _string(json, 'description'),
      lastReviewedAtUtc: DateTime.parse(
        _string(json, 'lastReviewedAtUtc'),
      ).toUtc(),
      routes: _maps(json, 'routes').map(RoutePlan.fromJson).toList(),
      quests: _maps(json, 'quests').map(Quest.fromJson).toList(),
      pointsOfInterest: _maps(json, 'pointsOfInterest')
          .map(PointOfInterest.fromJson)
          .toList(),
    );
    if (pack.schemaVersion != 1) {
      throw FormatException(
        'Unsupported destination schema version: ${pack.schemaVersion}',
      );
    }
    final questIds = pack.quests.map((quest) => quest.id).toSet();
    for (final route in pack.routes) {
      if (!route.questIds.every(questIds.contains)) {
        throw FormatException('Route ${route.id} references an unknown quest.');
      }
    }
    return pack;
  }
}

Map<String, Object?> _map(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! Map) throw FormatException('$key must be an object.');
  return Map<String, Object?>.from(value);
}

List<Map<String, Object?>> _maps(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value is! List) throw FormatException('$key must be a list.');
  return value.map((item) => Map<String, Object?>.from(item as Map)).toList();
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

double _number(
  Map<String, Object?> json,
  String key, {
  double? fallback,
}) {
  final value = json[key];
  if (value == null && fallback != null) return fallback;
  if (value is! num) throw FormatException('$key must be a number.');
  return value.toDouble();
}

List<String> _strings(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$key must be a string list.');
  }
  return List<String>.from(value);
}
