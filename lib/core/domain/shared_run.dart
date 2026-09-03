import 'run_models.dart';

class ShareLink {
  const ShareLink({
    required this.shareId,
    required this.token,
    required this.expiresAtUtc,
    required this.shareUrl,
  });

  final String shareId;
  final String token;
  final DateTime expiresAtUtc;
  final String shareUrl;

  bool isExpiredAt(DateTime nowUtc) => !expiresAtUtc.isAfter(nowUtc.toUtc());

  factory ShareLink.fromJson(Map<String, Object?> json) => ShareLink(
        shareId: json['shareId'] as String,
        token: json['token'] as String,
        expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String).toUtc(),
        shareUrl: json['shareUrl'] as String,
      );
}

class SharedRunPreview {
  SharedRunPreview({
    required this.id,
    required this.startedAtUtc,
    required this.activeDuration,
    required this.distanceMeters,
    required this.locationName,
    required List<GeoPoint> track,
    required List<String> landmarks,
    required List<RunQuestResult> quests,
    required List<SharedEvidence> evidence,
    required this.expiresAtUtc,
  })  : track = List.unmodifiable(track),
        landmarks = List.unmodifiable(landmarks),
        quests = List.unmodifiable(quests),
        evidence = List.unmodifiable(evidence);

  final String id;
  final DateTime startedAtUtc;
  final Duration activeDuration;
  final double distanceMeters;
  final String locationName;
  final List<GeoPoint> track;
  final List<String> landmarks;
  final List<RunQuestResult> quests;
  final List<SharedEvidence> evidence;
  final DateTime expiresAtUtc;

  factory SharedRunPreview.fromJson(Map<String, Object?> json) =>
      SharedRunPreview(
        id: json['id'] as String,
        startedAtUtc: DateTime.parse(json['startedAtUtc'] as String).toUtc(),
        activeDuration: Duration(
          seconds: (json['activeDurationSeconds'] as num).round(),
        ),
        distanceMeters: (json['distanceMeters'] as num).toDouble(),
        locationName: json['locationName'] as String,
        track: (json['track'] as List)
            .map((item) =>
                GeoPoint.fromJson(Map<String, Object?>.from(item as Map)))
            .toList(),
        landmarks: List<String>.from(json['landmarks'] as List),
        quests: (json['quests'] as List)
            .map((item) =>
                RunQuestResult.fromJson(Map<String, Object?>.from(item as Map)))
            .toList(),
        evidence: (json['evidence'] as List? ?? [])
            .map((item) => SharedEvidence.fromJson(
                  Map<String, Object?>.from(item as Map),
                ))
            .toList(),
        expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String).toUtc(),
      );
}

class SharedEvidence {
  const SharedEvidence({
    required this.id,
    required this.questId,
    required this.caption,
    required this.imageUrl,
  });

  final String id;
  final String questId;
  final String caption;
  final String imageUrl;

  factory SharedEvidence.fromJson(Map<String, Object?> json) => SharedEvidence(
        id: json['id'] as String,
        questId: json['questId'] as String,
        caption: json['caption'] as String? ?? '',
        imageUrl: json['imageUrl'] as String,
      );
}
