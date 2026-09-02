import 'package:flutter/material.dart';

import '../../../core/domain/run_models.dart';
import '../../questory_theme.dart';
import '../widgets/demo_widgets.dart';

class RunsDemoScreen extends StatelessWidget {
  const RunsDemoScreen({
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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          children: [
            const PageHeading(
              eyebrow: 'OFFLINE HISTORY',
              title: 'Runs ready\nfor stories.',
              description:
                  'The demo keeps one deterministic completed run available on every platform.',
            ),
            const SizedBox(height: 24),
            InkWell(
              key: const ValueKey('history-demo-run'),
              onTap: onOpenRun,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: QuestoryColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: QuestoryColors.ink, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: QuestoryColors.teal,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.route,
                        color: QuestoryColors.yellow,
                        size: 38,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nha Trang Coast Quest',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${formatDistance(summary)} • ${formatDuration(summary)}',
                          ),
                          const SizedBox(height: 4),
                          const Text('3 quests • Completed offline'),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
