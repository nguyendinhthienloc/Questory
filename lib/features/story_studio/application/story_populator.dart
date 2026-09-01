import '../../../core/domain/run_summary.dart';
import '../../../core/domain/story_project.dart';
import '../data/story_templates.dart';

class StoryPopulator {
  const StoryPopulator();

  StoryDocument fromRun({
    required StoryTemplate template,
    required RunSummary summary,
    required String documentId,
  }) {
    final base = template.createDocument(
      documentId: documentId,
      sourceRunId: summary.id,
    );
    var photoIndex = 0;
    return base.copyWith(
      title: '${summary.locationName} run story',
      elements: [
        for (final element in base.elements)
          if (element.type == StoryElementType.photo)
            _photo(element, summary, photoIndex++)
          else
            _populateElement(element, summary),
      ],
    );
  }

  StoryElement _populateElement(StoryElement element, RunSummary summary) {
    switch (element.type) {
      case StoryElementType.route:
        return element.copyWith(
          content: 'RECORDED ROUTE',
          routePoints: _normaliseTrack(summary.track),
        );
      case StoryElementType.statistic:
        return element.copyWith(content: _statistics(summary));
      case StoryElementType.questList:
        return element.copyWith(content: _questRecap(summary));
      case StoryElementType.locationStamp:
        return element.copyWith(content: _location(summary));
      case StoryElementType.text:
        if (element.id.contains('caption')) {
          return element.copyWith(content: _caption(summary));
        }
        return element.copyWith(
          content: '${summary.locationName.toUpperCase()}\nRUN STORY',
        );
      case StoryElementType.sticker:
        if (element.id.contains('date')) {
          return element.copyWith(content: _formatDate(summary.startedAtUtc));
        }
        return element.copyWith(
          content: 'QUESTORY / ${_formatDate(summary.startedAtUtc)}',
        );
      case StoryElementType.photo:
        return element;
    }
  }

  StoryElement _photo(
    StoryElement element,
    RunSummary summary,
    int photoIndex,
  ) {
    if (photoIndex >= summary.evidence.length) {
      return element.copyWith(assetPath: null, content: 'ADD A RUN PHOTO');
    }
    final evidence = summary.evidence[photoIndex];
    return element.copyWith(
      assetPath: evidence.photoPath,
      content: evidence.caption.isEmpty ? 'RUN PHOTO' : evidence.caption,
    );
  }

  String _statistics(RunSummary summary) {
    final lines = <String>[
      '${(summary.distanceMeters / 1000).toStringAsFixed(2)} KM',
      _formatDuration(summary.activeDuration),
      summary.averagePaceSecondsPerKilometer == null
          ? 'PACE —'
          : '${_formatPace(summary.averagePaceSecondsPerKilometer!)} /KM',
    ];
    if (summary.estimatedCalories != null) {
      lines.add('EST. CALORIES ${summary.estimatedCalories} KCAL');
    }
    return lines.join('\n');
  }

  String _questRecap(RunSummary summary) {
    final lines = <String>['PHOTO QUESTS'];
    for (final quest in summary.quests) {
      final marker = quest.completed ? '✓' : (quest.skipped ? '–' : '○');
      lines.add('$marker ${quest.title}');
    }
    if (summary.landmarks.isNotEmpty) {
      lines
        ..add('LANDMARKS')
        ..add(summary.landmarks.join(' • '));
    }
    return lines.join('\n');
  }

  String _location(RunSummary summary) {
    final weather = summary.cachedWeather;
    if (weather == null) {
      return summary.locationName.toUpperCase();
    }
    return '${summary.locationName.toUpperCase()}\n'
        'CACHED ${weather.temperatureCelsius.round()}°C • '
        '${weather.summary.toUpperCase()}';
  }

  String _caption(RunSummary summary) {
    final captions = summary.evidence
        .map((evidence) => evidence.caption.trim())
        .where((caption) => caption.isNotEmpty)
        .toList();
    if (captions.isEmpty) {
      return 'A city is best remembered one stride at a time.';
    }
    return captions.join(' • ');
  }

  List<StoryCanvasPoint> _normaliseTrack(List<GeoPoint> track) {
    if (track.isEmpty) {
      return const [];
    }
    final minLatitude =
        track.map((point) => point.latitude).reduce((a, b) => a < b ? a : b);
    final maxLatitude =
        track.map((point) => point.latitude).reduce((a, b) => a > b ? a : b);
    final minLongitude =
        track.map((point) => point.longitude).reduce((a, b) => a < b ? a : b);
    final maxLongitude =
        track.map((point) => point.longitude).reduce((a, b) => a > b ? a : b);
    final latitudeRange = maxLatitude - minLatitude;
    final longitudeRange = maxLongitude - minLongitude;
    return List.unmodifiable([
      for (final point in track)
        StoryCanvasPoint(
          longitudeRange == 0
              ? 0.5
              : (point.longitude - minLongitude) / longitudeRange,
          latitudeRange == 0
              ? 0.5
              : 1 - ((point.latitude - minLatitude) / latitudeRange),
        ),
    ]);
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours == 0 ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
}

String _formatPace(double secondsPerKilometer) {
  final seconds = secondsPerKilometer.round();
  final minutes = seconds ~/ 60;
  return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
}

String _formatDate(DateTime utcDate) {
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  final date = utcDate.toLocal();
  return '${months[date.month - 1]} '
      '${date.day.toString().padLeft(2, '0')} / ${date.year}';
}
