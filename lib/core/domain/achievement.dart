class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    this.unlockedAtUtc,
  });

  final String id;
  final String title;
  final String description;
  final int progress;
  final int target;
  final DateTime? unlockedAtUtc;

  bool get unlocked => unlockedAtUtc != null;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'progress': progress,
        'target': target,
        'unlockedAtUtc': unlockedAtUtc?.toIso8601String(),
      };

  factory Achievement.fromJson(Map<String, Object?> json) => Achievement(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        progress: (json['progress'] as num).round(),
        target: (json['target'] as num).round(),
        unlockedAtUtc: json['unlockedAtUtc'] == null
            ? null
            : DateTime.parse(json['unlockedAtUtc'] as String).toUtc(),
      );
}
