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
import '../screens/home.dart';
import 'app_dependencies.dart';
import 'questory_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({
    super.key,
    required this.dependencies,
    this.tracksScreenBuilder,
  });

  final AppDependencies dependencies;
  final WidgetBuilder? tracksScreenBuilder;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  var _selectedIndex = 0;
  var _historyRevision = 0;
  var _recoveryChecked = false;
  var _tracksHasOpened = false;

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
    final screens = [
      ExploreScreen(
        repository: widget.dependencies.destinations,
        onStartRoute: _openRoute,
        onStartFreeRun: _openFreeRun,
      ),
      if (_tracksHasOpened)
        (widget.tracksScreenBuilder?.call(context) ?? const HomeScreen())
      else
        const SizedBox.shrink(),
      HistoryScreen(
        key: ValueKey('history-$_historyRevision'),
        dependencies: widget.dependencies,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: _MainBottomBar(
        selectedIndex: _selectedIndex,
        onSelected: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 1) _tracksHasOpened = true;
            if (index == 2) _historyRevision++;
          });
        },
      ),
    );
  }
}

class _MainBottomBar extends StatelessWidget {
  const _MainBottomBar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QuestoryColors.white,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 88,
          child: Row(
            children: [
              Expanded(
                child: _DestinationButton(
                  key: const ValueKey('nav-explore'),
                  label: 'Explore',
                  icon: Icons.explore_outlined,
                  selectedIcon: Icons.explore_rounded,
                  selected: selectedIndex == 0,
                  onTap: () => onSelected(0),
                ),
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  selected: selectedIndex == 1,
                  label: 'Open Tracks camera',
                  child: InkWell(
                    key: const ValueKey('nav-tracks'),
                    onTap: () => onSelected(1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: selectedIndex == 1
                                ? QuestoryColors.coral
                                : QuestoryColors.ink,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: QuestoryColors.yellow,
                              width: 4,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: QuestoryColors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tracks',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _DestinationButton(
                  key: const ValueKey('nav-journey'),
                  label: 'Journey',
                  icon: Icons.auto_stories_outlined,
                  selectedIcon: Icons.auto_stories_rounded,
                  selected: selectedIndex == 2,
                  onTap: () => onSelected(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationButton extends StatelessWidget {
  const _DestinationButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              color: selected ? QuestoryColors.cobalt : QuestoryColors.ink,
              size: 27,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? QuestoryColors.cobalt : QuestoryColors.ink,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
