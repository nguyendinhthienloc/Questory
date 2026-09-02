import 'package:flutter/material.dart';

import '../../../core/domain/run_summary.dart';
import '../../questory_theme.dart';
import '../widgets/demo_widgets.dart';

class ExploreDemoScreen extends StatelessWidget {
  const ExploreDemoScreen({
    super.key,
    required this.summary,
    required this.onOpenRun,
  });

  final RunSummary summary;
  final VoidCallback onOpenRun;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DemoPageWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const _BrandHeader(),
            const SizedBox(height: 30),
            const PageHeading(
              eyebrow: 'YOUR DEMO IS READY',
              title: 'Turn one city run\ninto a story.',
              description:
                  'A completed offline Nha Trang run is bundled so you can show the full Story Studio flow without GPS or camera hardware.',
            ),
            const SizedBox(height: 24),
            _FeaturedRunCard(summary: summary, onOpenRun: onOpenRun),
            const SizedBox(height: 28),
            const SectionTitle('THE 3-STEP STORY'),
            const SizedBox(height: 12),
            const _FlowSteps(),
            const SizedBox(height: 24),
            const _BrowserNote(),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        QuestoryMark(),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUESTORY',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              Text('Run the city. Capture the story.'),
            ],
          ),
        ),
        OfflineBadge(),
      ],
    );
  }
}

class _FeaturedRunCard extends StatelessWidget {
  const _FeaturedRunCard({required this.summary, required this.onOpenRun});

  final RunSummary summary;
  final VoidCallback onOpenRun;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QuestoryColors.cobalt,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            height: 190,
            child: CustomPaint(
              painter: RoutePreviewPainter(),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: DemoLabel(text: 'COMPLETED RUN'),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.locationName,
                  style: const TextStyle(
                    color: QuestoryColors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Nha Trang Coast Quest',
                  style: TextStyle(
                    color: QuestoryColors.white,
                    fontFamily: 'Space Grotesk',
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _RunFact(
                        value: formatDistance(summary),
                        label: 'DISTANCE',
                      ),
                    ),
                    Expanded(
                      child: _RunFact(
                        value: formatDuration(summary),
                        label: 'TIME',
                      ),
                    ),
                    Expanded(
                      child: _RunFact(
                        value: '${summary.quests.length}',
                        label: 'QUESTS',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const ValueKey('open-demo-run'),
                  onPressed: onOpenRun,
                  style: FilledButton.styleFrom(
                    backgroundColor: QuestoryColors.yellow,
                    foregroundColor: QuestoryColors.ink,
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('VIEW RUN RECAP'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RunFact extends StatelessWidget {
  const _RunFact({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: QuestoryColors.white,
            fontFamily: 'Space Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: QuestoryColors.white,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _FlowSteps extends StatelessWidget {
  const _FlowSteps();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _FlowStep(number: '1', label: 'Review run')),
        SizedBox(width: 8),
        Expanded(child: _FlowStep(number: '2', label: 'Create')),
        SizedBox(width: 8),
        Expanded(child: _FlowStep(number: '3', label: 'Export')),
      ],
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      decoration: BoxDecoration(
        color: QuestoryColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuestoryColors.ink),
      ),
      child: Column(
        children: [
          Text(number, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _BrowserNote extends StatelessWidget {
  const _BrowserNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: QuestoryColors.yellow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.camera_alt_outlined),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Edge DevTools cannot emulate a camera. Demo photo evidence is already included, so camera access never blocks Story Studio.',
            ),
          ),
        ],
      ),
    );
  }
}
