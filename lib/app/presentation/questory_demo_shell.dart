import 'package:flutter/material.dart';

import '../../core/contracts/story_repository.dart';
import '../../core/domain/run_models.dart';
import '../../features/story_studio/story_studio.dart';
import 'screens/explore_demo_screen.dart';
import 'screens/run_recap_screen.dart';
import 'screens/runs_demo_screen.dart';
import 'screens/studio_home_screen.dart';

class QuestoryDemoShell extends StatefulWidget {
  const QuestoryDemoShell({
    super.key,
    required this.repository,
    this.summary,
  });

  final StoryRepository repository;
  final RunSummary? summary;

  @override
  State<QuestoryDemoShell> createState() => _QuestoryDemoShellState();
}

class _QuestoryDemoShellState extends State<QuestoryDemoShell> {
  var _selectedIndex = 0;
  var _studioRevision = 0;

  RunSummary get _summary => widget.summary ?? sampleRunSummary;

  Future<void> _openStudio() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => StoryStudioScreen(
          runSummary: _summary,
          repository: widget.repository,
        ),
      ),
    );
    if (mounted) {
      setState(() => _studioRevision++);
    }
  }

  Future<void> _openRunRecap() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RunRecapScreen(
          summary: _summary,
          onCreateStory: _openStudio,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ExploreDemoScreen(summary: _summary, onOpenRun: _openRunRecap),
      StudioHomeScreen(
        key: ValueKey(_studioRevision),
        repository: widget.repository,
        onOpenStudio: _openStudio,
      ),
      RunsDemoScreen(summary: _summary, onOpenRun: _openRunRecap),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            key: ValueKey('nav-explore'),
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            key: ValueKey('nav-studio'),
            icon: Icon(Icons.auto_awesome_mosaic_outlined),
            selectedIcon: Icon(Icons.auto_awesome_mosaic),
            label: 'Studio',
          ),
          NavigationDestination(
            key: ValueKey('nav-runs'),
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Runs',
          ),
        ],
      ),
    );
  }
}
