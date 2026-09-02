import 'run_models.dart';

const Object _unset = Object();

enum RunLifecycle {
  idle,
  acquiring,
  active,
  paused,
  finishing,
  completed,
  failed,
}

class RunSession {
  RunSession({
    required this.id,
    required this.cityId,
    required this.locationName,
    required this.startedAtUtc,
    required this.updatedAtUtc,
    required this.lifecycle,
    required this.accumulatedActiveDuration,
    required List<GeoPoint> track,
    required List<QuestEvidence> evidence,
    required Set<String> completedQuestIds,
    required Set<String> skippedQuestIds,
    this.routeId,
    this.activeSegmentStartedAtUtc,
    this.errorMessage,
  })  : track = List.unmodifiable(track),
        evidence = List.unmodifiable(evidence),
        completedQuestIds = Set.unmodifiable(completedQuestIds),
        skippedQuestIds = Set.unmodifiable(skippedQuestIds);

  final String id;
  final String cityId;
  final String locationName;
  final String? routeId;
  final DateTime startedAtUtc;
  final DateTime updatedAtUtc;
  final RunLifecycle lifecycle;
  final DateTime? activeSegmentStartedAtUtc;
  final Duration accumulatedActiveDuration;
  final List<GeoPoint> track;
  final List<QuestEvidence> evidence;
  final Set<String> completedQuestIds;
  final Set<String> skippedQuestIds;
  final String? errorMessage;

  Duration activeDurationAt(DateTime nowUtc) {
    final segmentStart = activeSegmentStartedAtUtc;
    if (lifecycle != RunLifecycle.active || segmentStart == null) {
      return accumulatedActiveDuration;
    }
    final currentSegment = nowUtc.difference(segmentStart);
    return accumulatedActiveDuration +
        (currentSegment.isNegative ? Duration.zero : currentSegment);
  }

  RunSession copyWith({
    String? id,
    String? cityId,
    String? locationName,
    Object? routeId = _unset,
    DateTime? startedAtUtc,
    DateTime? updatedAtUtc,
    RunLifecycle? lifecycle,
    Object? activeSegmentStartedAtUtc = _unset,
    Duration? accumulatedActiveDuration,
    List<GeoPoint>? track,
    List<QuestEvidence>? evidence,
    Set<String>? completedQuestIds,
    Set<String>? skippedQuestIds,
    Object? errorMessage = _unset,
  }) {
    return RunSession(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      locationName: locationName ?? this.locationName,
      routeId: identical(routeId, _unset) ? this.routeId : routeId as String?,
      startedAtUtc: startedAtUtc ?? this.startedAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      lifecycle: lifecycle ?? this.lifecycle,
      activeSegmentStartedAtUtc: identical(activeSegmentStartedAtUtc, _unset)
          ? this.activeSegmentStartedAtUtc
          : activeSegmentStartedAtUtc as DateTime?,
      accumulatedActiveDuration:
          accumulatedActiveDuration ?? this.accumulatedActiveDuration,
      track: track ?? this.track,
      evidence: evidence ?? this.evidence,
      completedQuestIds: completedQuestIds ?? this.completedQuestIds,
      skippedQuestIds: skippedQuestIds ?? this.skippedQuestIds,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'cityId': cityId,
        'locationName': locationName,
        'routeId': routeId,
        'startedAtUtc': startedAtUtc.toIso8601String(),
        'updatedAtUtc': updatedAtUtc.toIso8601String(),
        'lifecycle': lifecycle.name,
        'activeSegmentStartedAtUtc':
            activeSegmentStartedAtUtc?.toIso8601String(),
        'accumulatedActiveSeconds': accumulatedActiveDuration.inSeconds,
        'track': track.map((point) => point.toJson()).toList(),
        'evidence': evidence.map((item) => item.toJson()).toList(),
        'completedQuestIds': completedQuestIds.toList(),
        'skippedQuestIds': skippedQuestIds.toList(),
        'errorMessage': errorMessage,
      };

  factory RunSession.fromJson(Map<String, Object?> json) => RunSession(
        id: json['id'] as String,
        cityId: json['cityId'] as String,
        locationName: json['locationName'] as String,
        routeId: json['routeId'] as String?,
        startedAtUtc: DateTime.parse(json['startedAtUtc'] as String).toUtc(),
        updatedAtUtc: DateTime.parse(json['updatedAtUtc'] as String).toUtc(),
        lifecycle: RunLifecycle.values.firstWhere(
          (value) => value.name == json['lifecycle'],
        ),
        activeSegmentStartedAtUtc: json['activeSegmentStartedAtUtc'] == null
            ? null
            : DateTime.parse(
                json['activeSegmentStartedAtUtc'] as String,
              ).toUtc(),
        accumulatedActiveDuration: Duration(
          seconds: (json['accumulatedActiveSeconds'] as num).round(),
        ),
        track: (json['track'] as List)
            .map(
              (item) => GeoPoint.fromJson(
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
        completedQuestIds: Set<String>.from(json['completedQuestIds'] as List),
        skippedQuestIds: Set<String>.from(json['skippedQuestIds'] as List),
        errorMessage: json['errorMessage'] as String?,
      );
}
