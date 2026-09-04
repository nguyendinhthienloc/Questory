import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/questory_theme.dart';
import '../../../core/contracts/clock.dart';
import '../../../core/contracts/location_tracker.dart';
import '../../../core/contracts/photo_store.dart';
import '../../../core/contracts/run_repository.dart';
import '../../../core/domain/destination_models.dart';
import '../../../core/domain/run_session.dart';
import '../../../core/domain/run_models.dart';
import '../../destinations/application/quest_location_checker.dart';
import '../../quest_camera/presentation/quest_camera_screen.dart';
import '../application/run_tracker_controller.dart';

class RunTrackerScreen extends StatefulWidget {
  const RunTrackerScreen({
    super.key,
    required this.pack,
    required this.route,
    required this.repository,
    required this.locationTracker,
    required this.photoStore,
    required this.clock,
    required this.onFinished,
    this.initialSession,
  });

  final DestinationPack pack;
  final RoutePlan? route;
  final RunRepository repository;
  final LocationTracker locationTracker;
  final PhotoStore photoStore;
  final Clock clock;
  final ValueChanged<RunSummary> onFinished;
  final RunSession? initialSession;

  @override
  State<RunTrackerScreen> createState() => _RunTrackerScreenState();
}

class _RunTrackerScreenState extends State<RunTrackerScreen> {
  late final RunTrackerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RunTrackerController(
      pack: widget.pack,
      route: widget.route,
      repository: widget.repository,
      locationTracker: widget.locationTracker,
      clock: widget.clock,
    )..addListener(_refresh);
    if (widget.initialSession case final session?) {
      _controller.restore(session);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  Future<void> _begin() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record this run?'),
        content: const Text(
          'Questory uses your precise location to record the route, calculate '
          'distance, and unlock nearby photo quests. A visible notification '
          'remains while tracking is active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NOT NOW'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );
    if (accepted == true) await _controller.start();
  }

  Future<void> _finish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish run?'),
        content:
            const Text('The current track and quest progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('KEEP RUNNING'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('FINISH'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final summary = await _controller.finish();
    if (summary != null && mounted) widget.onFinished(summary);
  }

  Future<void> _discard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this run?'),
        content: const Text('The active checkpoint will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DISCARD'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final evidence = [...?_controller.session?.evidence];
      try {
        await _controller.discard();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not discard the run: $error')),
          );
        }
        return;
      }
      var cleanupFailed = false;
      for (final item in evidence) {
        try {
          await widget.photoStore.delete(item.photoPath);
        } catch (_) {
          cleanupFailed = true;
        }
      }
      if (mounted) {
        if (cleanupFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Run discarded. Some retained photos could not be removed.',
              ),
            ),
          );
        }
        Navigator.pop(context);
      }
    }
  }

  Future<void> _captureQuest(Quest quest) async {
    var point = _controller.currentPoint;
    if (point == null) {
      if (quest.fallback.type != QuestFallbackType.manualConfirmation) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Use GPS fallback?'),
          content: Text(
            '${quest.fallback.instructions}\n\nOnly continue if you are '
            'physically at the quest location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("I'M HERE"),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      point = GeoPoint(
        latitude: quest.point.latitude,
        longitude: quest.point.longitude,
        timestampUtc: widget.clock.nowUtc(),
        // A large finite value marks evidence completed through the fallback
        // while remaining safe to serialize in the local JSON checkpoint.
        accuracyMeters: 9999,
      );
    }
    final evidence = await Navigator.push<QuestEvidence>(
      context,
      MaterialPageRoute(
        builder: (_) => QuestCameraScreen(
          quest: quest,
          point: point!,
          photoStore: widget.photoStore,
          clock: widget.clock,
        ),
      ),
    );
    if (evidence != null) await _controller.addEvidence(evidence);
  }

  @override
  Widget build(BuildContext context) {
    final lifecycle = _controller.lifecycle;
    return Scaffold(
      backgroundColor: QuestoryColors.paper,
      appBar: AppBar(
        backgroundColor: QuestoryColors.paper,
        title: Text(widget.route?.name ?? '${widget.pack.cityName} Free Run'),
        actions: [
          if (lifecycle == RunLifecycle.active ||
              lifecycle == RunLifecycle.paused)
            IconButton(
              tooltip: 'Discard run',
              onPressed: _discard,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            _TrackerStatus(lifecycle: lifecycle),
            if (_controller.session?.errorMessage case final message?) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: message),
            ],
            const SizedBox(height: 14),
            _TrackSurface(
              track: _controller.track,
              expected: widget.route?.expectedPolyline ?? const [],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'TIME',
                    value: _duration(_controller.activeDuration),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'DISTANCE',
                    value:
                        '${(_controller.distanceMeters / 1000).toStringAsFixed(2)} km',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'PACE',
                    value: _pace(_controller.paceSecondsPerKilometer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Controls(
              lifecycle: lifecycle,
              onStart: _begin,
              onPause: _controller.pause,
              onResume: _controller.resume,
              onFinish: _finish,
            ),
            const SizedBox(height: 28),
            const Text(
              'PHOTO QUESTS',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            if (_controller.availableQuests.isEmpty)
              const Text('No nearby bundled quests are available.')
            else
              for (final quest in _controller.availableQuests)
                _QuestCard(
                  quest: quest,
                  point: _controller.currentPoint,
                  completed: _controller.session?.completedQuestIds
                          .contains(quest.id) ??
                      false,
                  skipped:
                      _controller.session?.skippedQuestIds.contains(quest.id) ??
                          false,
                  trackingStarted: lifecycle == RunLifecycle.active ||
                      lifecycle == RunLifecycle.paused,
                  onCapture: () => _captureQuest(quest),
                  onSkip: () => _controller.skipQuest(quest.id),
                ),
          ],
        ),
      ),
    );
  }

  static String _duration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  static String _pace(double? seconds) {
    if (seconds == null || !seconds.isFinite) return '—';
    final minutes = seconds ~/ 60;
    final remainder = (seconds.round() % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }
}

class _TrackerStatus extends StatelessWidget {
  const _TrackerStatus({required this.lifecycle});

  final RunLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (lifecycle) {
      RunLifecycle.idle => ('READY', QuestoryColors.cobalt),
      RunLifecycle.acquiring => ('ACQUIRING GPS', QuestoryColors.yellow),
      RunLifecycle.active => ('RECORDING', QuestoryColors.coral),
      RunLifecycle.paused => ('PAUSED', QuestoryColors.yellow),
      RunLifecycle.finishing => ('SAVING', QuestoryColors.teal),
      RunLifecycle.completed => ('COMPLETED', QuestoryColors.teal),
      RunLifecycle.failed => ('NEEDS ATTENTION', QuestoryColors.coral),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: Icon(
          lifecycle == RunLifecycle.active
              ? Icons.fiber_manual_record_rounded
              : Icons.directions_run_rounded,
          size: 17,
        ),
        label: Text(label),
        backgroundColor: color,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFD8D4),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.lifecycle,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
  });

  final RunLifecycle lifecycle;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    if (lifecycle == RunLifecycle.idle || lifecycle == RunLifecycle.failed) {
      return FilledButton.icon(
        key: const ValueKey('begin-tracking'),
        onPressed: onStart,
        icon: const Icon(Icons.play_arrow_rounded),
        label:
            Text(lifecycle == RunLifecycle.failed ? 'RETRY' : 'BEGIN TRACKING'),
      );
    }
    if (lifecycle == RunLifecycle.acquiring ||
        lifecycle == RunLifecycle.finishing) {
      return const Center(child: CircularProgressIndicator());
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: ValueKey(
              lifecycle == RunLifecycle.active ? 'pause-run' : 'resume-run',
            ),
            onPressed: lifecycle == RunLifecycle.active ? onPause : onResume,
            icon: Icon(
              lifecycle == RunLifecycle.active
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
            ),
            label: Text(
              lifecycle == RunLifecycle.active ? 'PAUSE' : 'RESUME',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            key: const ValueKey('finish-run'),
            onPressed: onFinish,
            icon: const Icon(Icons.flag_rounded),
            label: const Text('FINISH'),
          ),
        ),
      ],
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.quest,
    required this.point,
    required this.completed,
    required this.skipped,
    required this.trackingStarted,
    required this.onCapture,
    required this.onSkip,
  });

  final Quest quest;
  final GeoPoint? point;
  final bool completed;
  final bool skipped;
  final bool trackingStarted;
  final VoidCallback onCapture;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final result = point == null
        ? null
        : const QuestLocationChecker().evaluate(
            quest: quest,
            userPoint: point!,
          );
    final canCapture = trackingStarted &&
        !completed &&
        !skipped &&
        ((point == null &&
                quest.fallback.type == QuestFallbackType.manualConfirmation) ||
            result?.status == QuestLocationStatus.nearby ||
            result?.status == QuestLocationStatus.fallbackAvailable);
    final status = completed
        ? 'Completed'
        : skipped
            ? 'Skipped'
            : !trackingStarted
                ? 'Start tracking to unlock'
                : result == null
                    ? quest.fallback.type ==
                            QuestFallbackType.manualConfirmation
                        ? 'GPS unavailable • fallback available'
                        : 'Waiting for GPS • skip available'
                    : switch (result.status) {
                        QuestLocationStatus.nearby => 'Nearby • ready',
                        QuestLocationStatus.fallbackAvailable =>
                          'GPS inaccurate • fallback available',
                        QuestLocationStatus.inaccurateGps => 'GPS inaccurate',
                        QuestLocationStatus.tooFar =>
                          '${result.distanceMeters.round()} m away',
                      };
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.photo_camera_outlined,
                  color: completed ? QuestoryColors.teal : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    quest.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(quest.prompt),
            const SizedBox(height: 8),
            Text(status, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canCapture ? onCapture : null,
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('CAPTURE'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: completed || skipped ? null : onSkip,
                  child: const Text('SKIP'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackSurface extends StatelessWidget {
  const _TrackSurface({required this.track, required this.expected});

  final List<GeoPoint> track;
  final List<GeoPoint> expected;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE8E3D8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: QuestoryColors.ink, width: 2),
        ),
        child: CustomPaint(
          painter: _TrackPainter(expected: expected, track: track),
          child: track.isEmpty
              ? const Center(
                  child: Text(
                    'OFFLINE ROUTE SURFACE\nWaiting for recorded points',
                    textAlign: TextAlign.center,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter({required this.expected, required this.track});

  final List<GeoPoint> expected;
  final List<GeoPoint> track;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [...expected, ...track];
    if (points.length < 2) return;
    final minLat = points.map((p) => p.latitude).reduce(math.min);
    final maxLat = points.map((p) => p.latitude).reduce(math.max);
    final minLon = points.map((p) => p.longitude).reduce(math.min);
    final maxLon = points.map((p) => p.longitude).reduce(math.max);
    const padding = 22.0;
    Offset map(GeoPoint point) => Offset(
          padding +
              (point.longitude - minLon) /
                  math.max(maxLon - minLon, 0.000001) *
                  (size.width - padding * 2),
          size.height -
              padding -
              (point.latitude - minLat) /
                  math.max(maxLat - minLat, 0.000001) *
                  (size.height - padding * 2),
        );
    void draw(List<GeoPoint> line, Color color, double width) {
      if (line.length < 2) return;
      final first = map(line.first);
      final path = Path()..moveTo(first.dx, first.dy);
      for (final point in line.skip(1)) {
        final value = map(point);
        path.lineTo(value.dx, value.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    draw(expected, const Color(0x553157C8), 7);
    draw(track, QuestoryColors.coral, 8);
    if (track.isNotEmpty) {
      canvas.drawCircle(
          map(track.last), 9, Paint()..color = QuestoryColors.teal);
    }
  }

  @override
  bool shouldRepaint(covariant _TrackPainter oldDelegate) =>
      oldDelegate.expected != expected || oldDelegate.track != track;
}
