import 'package:flutter/material.dart';

import '../../../core/domain/destination_models.dart';
import '../../../core/domain/run_models.dart';
import 'explore_screen.dart';

class RouteDetailsScreen extends StatelessWidget {
  const RouteDetailsScreen({
    super.key,
    required this.pack,
    required this.route,
    this.onStart,
  });

  final DestinationPack pack;
  final RoutePlan route;
  final StartRouteCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final quests = [
      for (final id in route.questIds)
        if (pack.questById(id) case final quest?) quest,
    ];
    return Scaffold(
      backgroundColor: QuestoryColors.paper,
      appBar: AppBar(
        backgroundColor: QuestoryColors.paper,
        title: const Text('Route Details'),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton.icon(
          key: const ValueKey('start-curated-run'),
          style: FilledButton.styleFrom(
            backgroundColor: QuestoryColors.coral,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            if (onStart != null) {
              onStart!(pack, route);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Run tracking is being connected.')),
              );
            }
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('START THIS ROUTE'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Text(
            route.name,
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(route.description, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 18),
          _RoutePreview(points: route.expectedPolyline),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Metric(
                icon: Icons.straighten_rounded,
                value: '${(route.distanceMeters / 1000).toStringAsFixed(1)} km',
              ),
              _Metric(
                icon: Icons.schedule_rounded,
                value: '${route.estimatedDuration.inMinutes} min',
              ),
              _Metric(icon: Icons.speed_rounded, value: route.difficulty),
              const _Metric(icon: Icons.offline_bolt_rounded, value: 'Offline'),
            ],
          ),
          const SizedBox(height: 26),
          const _SectionTitle('LANDMARKS'),
          for (final landmark in route.landmarks)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined),
              title: Text(
                landmark.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(landmark.description),
            ),
          const SizedBox(height: 18),
          const _SectionTitle('PHOTO QUESTS'),
          if (quests.isEmpty)
            const Text('No quests are attached to this route.')
          else
            for (final quest in quests)
              Card(
                color: Colors.white,
                child: ExpansionTile(
                  key: ValueKey('quest-${quest.id}'),
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(
                    quest.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${quest.radiusMeters.round()} m radius'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Text(quest.prompt),
                    const SizedBox(height: 8),
                    Text(
                      quest.captionRequired
                          ? 'Photo and caption required'
                          : 'Photo required; caption optional',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text('GPS fallback: ${quest.fallback.instructions}'),
                  ],
                ),
              ),
          const SizedBox(height: 22),
          const _SectionTitle('SAFETY & ACCESS'),
          for (final note in route.safetyNotes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(note)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Pack reviewed ${_localDate(pack.lastReviewedAtUtc)}. '
            'Always follow current signs and local conditions.',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  static String _localDate(DateTime utc) {
    final date = utc.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _RoutePreview extends StatelessWidget {
  const _RoutePreview({required this.points});

  final List<GeoPoint> points;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: QuestoryColors.ink, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: CustomPaint(painter: _RoutePainter(points)),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter(this.points);

  final List<GeoPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final minLat =
        points.map((point) => point.latitude).reduce((a, b) => a < b ? a : b);
    final maxLat =
        points.map((point) => point.latitude).reduce((a, b) => a > b ? a : b);
    final minLon =
        points.map((point) => point.longitude).reduce((a, b) => a < b ? a : b);
    final maxLon =
        points.map((point) => point.longitude).reduce((a, b) => a > b ? a : b);
    const padding = 24.0;
    final latRange = (maxLat - minLat).abs();
    final lonRange = (maxLon - minLon).abs();
    Offset offset(GeoPoint point) => Offset(
          padding +
              (point.longitude - minLon) /
                  (lonRange == 0 ? 1 : lonRange) *
                  (size.width - padding * 2),
          size.height -
              padding -
              (point.latitude - minLat) /
                  (latRange == 0 ? 1 : latRange) *
                  (size.height - padding * 2),
        );
    final first = offset(points.first);
    final path = Path()..moveTo(first.dx, first.dy);
    for (final point in points.skip(1)) {
      final value = offset(point);
      path.lineTo(value.dx, value.dy);
    }
    final paint = Paint()
      ..color = QuestoryColors.cobalt
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      offset(points.first),
      10,
      Paint()..color = QuestoryColors.teal,
    );
    canvas.drawCircle(
      offset(points.last),
      10,
      Paint()..color = QuestoryColors.coral,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.points != points;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(value));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }
}
