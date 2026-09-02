import 'package:flutter/material.dart';

import '../../../core/domain/run_models.dart';
import '../../questory_theme.dart';
import '../widgets/demo_widgets.dart';

class RunRecapScreen extends StatelessWidget {
  const RunRecapScreen({
    super.key,
    required this.summary,
    required this.onCreateStory,
  });

  final RunSummary summary;
  final VoidCallback onCreateStory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Run recap')),
      body: DemoPageWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: QuestoryColors.teal,
                borderRadius: BorderRadius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: const CustomPaint(
                painter: RoutePreviewPainter(),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Text(
                      'COAST QUEST / NHA TRANG',
                      style: TextStyle(
                        color: QuestoryColors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'A run worth remembering.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            MetricGrid(summary: summary),
            const SizedBox(height: 26),
            const SectionTitle('QUESTS COMPLETED'),
            const SizedBox(height: 10),
            for (final quest in summary.quests)
              QuestResultRow(
                title: quest.title,
                completed: quest.completed,
              ),
            const SizedBox(height: 22),
            const SectionTitle('PHOTO EVIDENCE'),
            const SizedBox(height: 10),
            EvidenceStrip(summary: summary),
            const SizedBox(height: 28),
            FilledButton.icon(
              key: const ValueKey('create-story-from-run'),
              onPressed: onCreateStory,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('CREATE STORY'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Uses the real editor with this run pre-filled. No network required.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
