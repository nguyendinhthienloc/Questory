import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/domain/achievement.dart';
import '../../../core/domain/run_models.dart';
import '../../../core/domain/story_project.dart';
import '../../destinations/presentation/explore_screen.dart';
import '../../story_studio/presentation/story_studio_screen.dart';
import '../../tracking/presentation/run_summary_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<_HistoryData> _data;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _data = Future.wait([
      widget.dependencies.runs.listSummaries(),
      widget.dependencies.stories.list(),
      widget.dependencies.achievements.list(),
    ]).then(
      (values) => _HistoryData(
        runs: values[0] as List<RunSummary>,
        stories: values[1] as List<StoryDocument>,
        achievements: values[2] as List<Achievement>,
      ),
    );
  }

  void _refresh() => setState(_reload);

  Future<void> _deleteRun(RunSummary run) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this run?'),
        content: const Text(
          'The saved route and its retained quest photos will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    for (final evidence in run.evidence) {
      await widget.dependencies.photoStore.delete(evidence.photoPath);
    }
    await widget.dependencies.runs.deleteSummary(run.id);
    if (mounted) _refresh();
  }

  Future<void> _openStory(StoryDocument story) async {
    final runId = story.sourceRunId;
    if (runId == null) return;
    final run = await widget.dependencies.runs.getSummary(runId);
    if (!mounted) return;
    if (run == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The source run is no longer available.')),
      );
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => StoryStudioScreen(
          runSummary: run,
          repository: widget.dependencies.stories,
          shareService: widget.dependencies.shareService,
          initialDocument: story,
        ),
      ),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestoryColors.paper,
      appBar: AppBar(
        backgroundColor: QuestoryColors.paper,
        title: const Text(
          'YOUR JOURNEY',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<_HistoryData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _HistoryMessage(
              icon: Icons.error_outline_rounded,
              title: 'History could not be loaded',
              message: '${snapshot.error}',
              onRetry: _refresh,
            );
          }
          final data = snapshot.data!;
          if (data.runs.isEmpty &&
              data.stories.isEmpty &&
              data.achievements.isEmpty) {
            return const _HistoryMessage(
              icon: Icons.directions_run_rounded,
              title: 'Your first story starts outside',
              message: 'Complete a route or Free Run to build your diary.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
              children: [
                _SectionTitle('RUNS', count: data.runs.length),
                if (data.runs.isEmpty)
                  const Text('No completed runs yet.')
                else
                  for (final run in data.runs)
                    Card(
                      color: Colors.white,
                      child: ListTile(
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RunSummaryScreen(
                              summary: run,
                              storyRepository: widget.dependencies.stories,
                              shareService: widget.dependencies.shareService,
                              achievements: data.achievements,
                            ),
                          ),
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: QuestoryColors.coral,
                          child: Icon(
                            Icons.route_rounded,
                            color: QuestoryColors.ink,
                          ),
                        ),
                        title: Text(
                          run.locationName,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          '${(run.distanceMeters / 1000).toStringAsFixed(2)} km • ${_date(run.startedAtUtc)}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Delete run',
                          onPressed: () => _deleteRun(run),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
                _SectionTitle('STORY PROJECTS', count: data.stories.length),
                if (data.stories.isEmpty)
                  const Text('Create a story from a completed run.')
                else
                  for (final story in data.stories)
                    Card(
                      color: Colors.white,
                      child: ListTile(
                        onTap: story.sourceRunId == null
                            ? null
                            : () => _openStory(story),
                        leading: const Icon(Icons.auto_awesome_rounded),
                        title: Text(story.title),
                        subtitle: const Text('Editable 1080 × 1920 story'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    ),
                const SizedBox(height: 24),
                _SectionTitle('ACHIEVEMENTS', count: data.achievements.length),
                if (data.achievements.isEmpty)
                  const Text('Achievements appear after your first run.')
                else
                  for (final item in data.achievements)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        item.unlocked
                            ? Icons.emoji_events_rounded
                            : Icons.lock_outline_rounded,
                        color: item.unlocked ? QuestoryColors.yellow : null,
                      ),
                      title: Text(item.title),
                      subtitle: Text(
                        '${item.description}\n${item.progress}/${item.target}',
                      ),
                      isThreeLine: true,
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$title  $count',
        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryData {
  const _HistoryData({
    required this.runs,
    required this.stories,
    required this.achievements,
  });

  final List<RunSummary> runs;
  final List<StoryDocument> stories;
  final List<Achievement> achievements;
}
