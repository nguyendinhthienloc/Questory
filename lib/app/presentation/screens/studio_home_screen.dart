import 'package:flutter/material.dart';

import '../../../core/contracts/story_repository.dart';
import '../../../features/story_studio/story_studio.dart';
import '../../questory_theme.dart';
import '../widgets/demo_widgets.dart';

class StudioHomeScreen extends StatelessWidget {
  const StudioHomeScreen({
    super.key,
    required this.repository,
    required this.onOpenStudio,
  });

  final StoryRepository repository;
  final VoidCallback onOpenStudio;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DemoPageWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          children: [
            const PageHeading(
              eyebrow: 'STORY STUDIO',
              title: 'Your run,\nyour layout.',
              description:
                  'Start with an original template, then move, crop, recolor, and rewrite every piece.',
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 164,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: storyTemplates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final template = storyTemplates[index];
                  const colors = [
                    QuestoryColors.cobalt,
                    QuestoryColors.coral,
                    QuestoryColors.teal,
                  ];
                  return Container(
                    width: 128,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors[index],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          color: QuestoryColors.white,
                        ),
                        const Spacer(),
                        Text(
                          template.name,
                          style: const TextStyle(
                            color: QuestoryColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${index + 1} / ${storyTemplates.length}',
                          style: const TextStyle(color: QuestoryColors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              key: const ValueKey('open-story-studio'),
              onPressed: onOpenStudio,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('OPEN STORY STUDIO'),
            ),
            const SizedBox(height: 28),
            const SectionTitle('MOCK BACKEND'),
            const SizedBox(height: 10),
            FutureBuilder(
              future: repository.list(),
              builder: (context, snapshot) {
                final documents = snapshot.data ?? const [];
                final suffix = documents.length == 1 ? '' : 's';
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: QuestoryColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: QuestoryColors.ink, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        documents.isEmpty
                            ? Icons.inventory_2_outlined
                            : Icons.cloud_done_outlined,
                        color: QuestoryColors.cobalt,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          documents.isEmpty
                              ? 'No draft saved yet. Save inside the editor to create one.'
                              : '${documents.length} editable draft$suffix saved for this demo session.',
                          key: const ValueKey('saved-draft-status'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
