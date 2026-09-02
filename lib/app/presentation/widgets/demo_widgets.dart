import 'package:flutter/material.dart';

import '../../../core/domain/run_summary.dart';
import '../../questory_theme.dart';

class DemoPageWidth extends StatelessWidget {
  const DemoPageWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: child,
      ),
    );
  }
}

class QuestoryMark extends StatelessWidget {
  const QuestoryMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: QuestoryColors.yellow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuestoryColors.ink, width: 2),
      ),
      child: const Icon(Icons.route_rounded, color: QuestoryColors.ink),
    );
  }
}

class OfflineBadge extends StatelessWidget {
  const OfflineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: QuestoryColors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: QuestoryColors.ink),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.offline_bolt_outlined, size: 16),
          SizedBox(width: 4),
          Text('OFFLINE', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class DemoLabel extends StatelessWidget {
  const DemoLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: QuestoryColors.yellow,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: QuestoryColors.ink,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: QuestoryColors.cobalt,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 36,
            height: 1.05,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(description, style: const TextStyle(fontSize: 16, height: 1.4)),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1),
    );
  }
}

class RoutePreviewPainter extends CustomPainter {
  const RoutePreviewPainter({
    this.background = QuestoryColors.teal,
    this.route = QuestoryColors.yellow,
  });

  final Color background;
  final Color route;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(background, BlendMode.src);
    final street = Paint()
      ..color = QuestoryColors.white.withValues(alpha: 0.16)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(-20, size.height * 0.2),
      Offset(size.width + 20, size.height * 0.65),
      street,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, -20),
      Offset(size.width * 0.72, size.height + 20),
      street,
    );
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.72)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.12,
        size.width * 0.53,
        size.height * 0.88,
        size.width * 0.9,
        size.height * 0.28,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = route
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.72),
      10,
      Paint()..color = QuestoryColors.white,
    );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.28),
      12,
      Paint()..color = QuestoryColors.coral,
    );
  }

  @override
  bool shouldRepaint(covariant RoutePreviewPainter oldDelegate) {
    return oldDelegate.background != background || oldDelegate.route != route;
  }
}

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.summary});

  final RunSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            DemoMetric(
                width: width,
                value: formatDistance(summary),
                label: 'DISTANCE'),
            DemoMetric(
                width: width,
                value: formatDuration(summary),
                label: 'ACTIVE TIME'),
            DemoMetric(
                width: width, value: formatPace(summary), label: 'AVG PACE'),
            DemoMetric(
              width: width,
              value: '${summary.estimatedCalories ?? 0}',
              label: 'EST. CALORIES',
            ),
          ],
        );
      },
    );
  }
}

class DemoMetric extends StatelessWidget {
  const DemoMetric(
      {super.key,
      required this.width,
      required this.value,
      required this.label});

  final double width;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuestoryColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: QuestoryColors.ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class QuestResultRow extends StatelessWidget {
  const QuestResultRow(
      {super.key, required this.title, required this.completed});

  final String title;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: QuestoryColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: completed ? QuestoryColors.teal : QuestoryColors.ink,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
      ),
    );
  }
}

class EvidenceStrip extends StatelessWidget {
  const EvidenceStrip({super.key, required this.summary});

  final RunSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = [QuestoryColors.coral, QuestoryColors.cobalt];
    return SizedBox(
      height: 154,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: summary.evidence.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final evidence = summary.evidence[index];
          return Container(
            width: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors[index % colors.length],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.photo_camera, color: QuestoryColors.white),
                const Spacer(),
                Text(
                  evidence.caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: QuestoryColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String formatDistance(RunSummary summary) {
  return '${(summary.distanceMeters / 1000).toStringAsFixed(2)} km';
}

String formatDuration(RunSummary summary) {
  final minutes = summary.activeDuration.inMinutes;
  final seconds = summary.activeDuration.inSeconds.remainder(60);
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String formatPace(RunSummary summary) {
  final pace = summary.averagePaceSecondsPerKilometer;
  if (pace == null) {
    return '—';
  }
  final minutes = pace ~/ 60;
  final seconds = pace.round().remainder(60);
  return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
}
