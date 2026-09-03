import 'package:flutter/material.dart';

import '../core/domain/achievement.dart';
import '../core/domain/destination_models.dart';
import '../core/domain/run_session.dart';
import '../core/domain/run_models.dart';
import '../features/destinations/presentation/explore_screen.dart';
import '../features/destinations/presentation/free_run_screen.dart';
import '../features/history/application/achievement_checker.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/tracking/presentation/run_summary_screen.dart';
import '../features/tracking/presentation/run_tracker_screen.dart';
import 'app_dependencies.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  var _selectedIndex = 0;
  var _historyRevision = 0;
  var _recoveryChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerRecovery());
  }

  Future<void> _offerRecovery() async {
    if (_recoveryChecked) return;
    _recoveryChecked = true;
    RunSession? session;
    try {
      session = await widget.dependencies.runs.loadActive();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved-run recovery is unavailable: $error')),
        );
      }
      return;
    }
    if (session == null || !mounted) return;
    final recoveredSession = session;
    DestinationPack? pack;
    try {
      pack = await widget.dependencies.destinations.getPack(
        recoveredSession.cityId,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('The saved route could not be loaded: $error')),
        );
      }
      return;
    }
    if (pack == null || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The saved route is unavailable. The checkpoint was kept.',
            ),
          ),
        );
      }
      return;
    }
    RoutePlan? route;
    for (final candidate in pack.routes) {
      if (candidate.id == recoveredSession.routeId) route = candidate;
    }
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Paused run found'),
        content: Text(
          'Questory saved your ${recoveredSession.locationName} run. '
          'Resume from its '
          'last checkpoint or discard it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('DISCARD'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RESUME'),
          ),
        ],
      ),
    );
    if (resume == true && mounted) {
      _openTracker(pack: pack, route: route, initialSession: recoveredSession);
    } else {
      try {
        await widget.dependencies.runs.clearActive();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('The saved run could not be discarded: $error')),
          );
        }
      }
    }
  }

  void _openRoute(DestinationPack pack, RoutePlan route) {
    _openTracker(pack: pack, route: route);
  }

  void _openFreeRun(DestinationPack pack) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => FreeRunDiscoveryScreen(
          pack: pack,
          onStart: () => _openTracker(pack: pack),
        ),
      ),
    );
  }

  void _openTracker({
    required DestinationPack pack,
    RoutePlan? route,
    RunSession? initialSession,
  }) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => RunTrackerScreen(
          pack: pack,
          route: route,
          repository: widget.dependencies.runs,
          locationTracker: widget.dependencies.locationTracker,
          photoStore: widget.dependencies.photoStore,
          clock: widget.dependencies.clock,
          initialSession: initialSession,
          onFinished: _finishRun,
        ),
      ),
    );
  }

  Future<void> _finishRun(RunSummary summary) async {
    var achievements = <Achievement>[];
    try {
      final runs = await widget.dependencies.runs.listSummaries();
      final previous = await widget.dependencies.achievements.list();
      final evaluated = const AchievementChecker().evaluate(
        runs: runs,
        nowUtc: widget.dependencies.clock.nowUtc(),
      );
      final previousById = {for (final item in previous) item.id: item};
      achievements = [
        for (final item in evaluated)
          if (previousById[item.id]?.unlockedAtUtc case final unlockedAt?)
            Achievement(
              id: item.id,
              title: item.title,
              description: item.description,
              progress: item.progress,
              target: item.target,
              unlockedAtUtc: unlockedAt,
            )
          else
            item,
      ];
      await widget.dependencies.achievements.saveAll(achievements);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'The run was saved, but achievements could not be updated: $error',
            ),
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() => _historyRevision++);
    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute(
        builder: (_) => RunSummaryScreen(
          summary: summary,
          storyRepository: widget.dependencies.stories,
          shareService: widget.dependencies.shareService,
          liveShareService: widget.dependencies.liveShareService,
          achievements: achievements,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = _selectedIndex == 0
        ? ExploreScreen(
            repository: widget.dependencies.destinations,
            onStartRoute: _openRoute,
            onStartFreeRun: _openFreeRun,
          )
        : HistoryScreen(
            key: ValueKey('history-$_historyRevision'),
            dependencies: widget.dependencies,
          );
    return Scaffold(
      body: screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 1) _historyRevision++;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Journey',
          ),
        ],
      ),
    );
  }
}
