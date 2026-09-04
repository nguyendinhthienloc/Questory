import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/questory_theme.dart';
import '../../../core/contracts/live_share_service.dart';
import '../../../core/contracts/share_service.dart';
import '../../../core/contracts/story_repository.dart';
import '../../../core/domain/achievement.dart';
import '../../../core/domain/run_models.dart';
import '../../story_studio/presentation/story_studio_screen.dart';

class RunSummaryScreen extends StatelessWidget {
  const RunSummaryScreen({
    super.key,
    required this.summary,
    required this.storyRepository,
    required this.shareService,
    this.liveShareService,
    this.achievements = const [],
  });

  final RunSummary summary;
  final StoryRepository storyRepository;
  final ShareService shareService;
  final LiveShareService? liveShareService;
  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    final completed = summary.quests.where((quest) => quest.completed).length;
    return Scaffold(
      backgroundColor: QuestoryColors.paper,
      appBar: AppBar(
        backgroundColor: QuestoryColors.paper,
        title: const Text('Run summary'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: QuestoryColors.cobalt,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RUN COMPLETE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  summary.locationName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Metric(label: 'DISTANCE', value: _distance)),
              const SizedBox(width: 8),
              Expanded(child: _Metric(label: 'TIME', value: _duration)),
              const SizedBox(width: 8),
              Expanded(child: _Metric(label: 'PACE', value: _pace)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '$completed/${summary.quests.length} PHOTO QUESTS',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (summary.quests.isEmpty)
            const Text('No quests were included in this run.')
          else
            for (final quest in summary.quests)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  quest.completed
                      ? Icons.check_circle_rounded
                      : quest.skipped
                          ? Icons.skip_next_rounded
                          : Icons.radio_button_unchecked_rounded,
                  color: quest.completed ? QuestoryColors.teal : null,
                ),
                title: Text(quest.title),
                subtitle: Text(
                  quest.completed
                      ? 'Completed'
                      : quest.skipped
                          ? 'Skipped'
                          : 'Not completed',
                ),
              ),
          if (summary.evidence.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'PHOTO DIARY',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: summary.evidence.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final evidence = summary.evidence[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 118,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(evidence.photoPath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: Color(0xFFE5E1D8),
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: ColoredBox(
                              color: const Color(0xCC171717),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  evidence.caption,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (achievements.any((item) => item.unlocked)) ...[
            const SizedBox(height: 24),
            const Text(
              'ACHIEVEMENTS',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            for (final item in achievements.where((item) => item.unlocked))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.emoji_events_rounded,
                  color: QuestoryColors.yellow,
                ),
                title: Text(item.title),
                subtitle: Text(item.description),
              ),
          ],
          const SizedBox(height: 24),
          if (liveShareService != null) ...[
            _ShareRouteButton(service: liveShareService!, summary: summary),
            const SizedBox(height: 10),
          ],
          FilledButton.icon(
            key: const ValueKey('open-story-studio'),
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => StoryStudioScreen(
                  runSummary: summary,
                  repository: storyRepository,
                  shareService: shareService,
                ),
              ),
            ),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('CREATE STORY'),
          ),
        ],
      ),
    );
  }

  String get _distance =>
      '${(summary.distanceMeters / 1000).toStringAsFixed(2)} km';

  String get _duration {
    final hours = summary.activeDuration.inHours;
    final minutes = summary.activeDuration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = summary.activeDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  String get _pace {
    final seconds = summary.averagePaceSecondsPerKilometer;
    if (seconds == null || !seconds.isFinite) return '—';
    final minutes = seconds ~/ 60;
    final remainder = (seconds.round() % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder /km';
  }
}

class _ShareRouteButton extends StatefulWidget {
  const _ShareRouteButton({required this.service, required this.summary});

  final LiveShareService service;
  final RunSummary summary;

  @override
  State<_ShareRouteButton> createState() => _ShareRouteButtonState();
}

class _ShareRouteButtonState extends State<_ShareRouteButton> {
  bool _sharing = false;

  Future<void> _share() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share this route online?'),
        content: const Text(
          'This uploads your route coordinates, run time, quest captions, '
          'and evidence photos. Anyone with the private link can view it for '
          '24 hours.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('cancel-online-share'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            key: const ValueKey('confirm-online-share'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('SHARE'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;

    setState(() => _sharing = true);
    try {
      final link = await widget.service.createShare(widget.summary);
      for (final evidence in widget.summary.evidence) {
        await widget.service.uploadEvidence(share: link, evidence: evidence);
      }
      await Clipboard.setData(ClipboardData(text: link.shareUrl));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Share link copied. It expires in 24 hours.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create share link: $error')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        key: const ValueKey('share-route-online'),
        onPressed: _sharing ? null : _share,
        icon: _sharing
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.link_rounded),
        label: Text(_sharing ? 'CREATING LINK...' : 'SHARE ROUTE ONLINE'),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
