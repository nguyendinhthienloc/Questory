import 'package:flutter/material.dart';

import '../../../app/questory_theme.dart';
import '../../../core/contracts/destination_repository.dart';
import '../../../core/domain/destination_models.dart';
import '../../../data/local/bundled_destination_repository.dart';
import 'route_details_screen.dart';

typedef StartRouteCallback = void Function(
  DestinationPack pack,
  RoutePlan route,
);
typedef StartFreeRunCallback = void Function(DestinationPack pack);

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    this.repository,
    this.onStartRoute,
    this.onStartFreeRun,
  });

  final DestinationRepository? repository;
  final StartRouteCallback? onStartRoute;
  final StartFreeRunCallback? onStartFreeRun;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final DestinationRepository _repository;
  late Future<List<DestinationPack>> _packs;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BundledDestinationRepository();
    _packs = _repository.listPacks();
  }

  void _retry() => setState(() => _packs = _repository.listPacks());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestoryColors.paper,
      appBar: AppBar(
        backgroundColor: QuestoryColors.paper,
        foregroundColor: QuestoryColors.ink,
        title: const Text(
          'QUESTORY',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
      ),
      body: FutureBuilder<List<DestinationPack>>(
        future: _packs,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.cloud_off_rounded,
              title: 'City packs could not be loaded',
              message: '${snapshot.error}',
              actionLabel: 'TRY AGAIN',
              onAction: _retry,
            );
          }
          final packs = snapshot.data ?? const [];
          if (packs.isEmpty) {
            return const _MessageState(
              icon: Icons.map_outlined,
              title: 'No city packs available',
              message: 'Bundled destinations will appear here.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const _OfflineLabel(),
              const SizedBox(height: 18),
              const Text(
                'Explore Vietnam',
                style: TextStyle(
                  color: QuestoryColors.ink,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose a city to discover running routes and photo quests.',
                style: TextStyle(
                  color: Color(0xFF4D4A46),
                  fontSize: 17,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              for (var index = 0; index < packs.length; index++) ...[
                _DestinationCard(
                  pack: packs[index],
                  accentColor:
                      index.isEven ? QuestoryColors.coral : QuestoryColors.teal,
                  onTap: () => _openPack(packs[index]),
                ),
                if (index != packs.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openPack(DestinationPack pack) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationDetailsScreen(
          pack: pack,
          onStartRoute: widget.onStartRoute,
          onStartFreeRun: widget.onStartFreeRun,
        ),
      ),
    );
  }
}

class DestinationDetailsScreen extends StatelessWidget {
  const DestinationDetailsScreen({
    super.key,
    required this.pack,
    this.onStartRoute,
    this.onStartFreeRun,
  });

  final DestinationPack pack;
  final StartRouteCallback? onStartRoute;
  final StartFreeRunCallback? onStartFreeRun;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestoryColors.paper,
      appBar: AppBar(
        backgroundColor: QuestoryColors.paper,
        title: Text(pack.cityName),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Text(
            pack.description,
            style: const TextStyle(fontSize: 17, height: 1.45),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.offline_bolt_rounded, size: 19),
              const SizedBox(width: 6),
              Text(
                'OFFLINE • PACK ${pack.packVersion}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const ValueKey('start-free-run'),
            style: FilledButton.styleFrom(
              backgroundColor: QuestoryColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => _startFreeRun(context),
            icon: const Icon(Icons.explore_rounded),
            label: const Text('START FREE RUN'),
          ),
          const SizedBox(height: 28),
          const Text(
            'CURATED ROUTES',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (pack.routes.isEmpty)
            const _MessageState(
              icon: Icons.route_outlined,
              title: 'No curated routes yet',
              message: 'Free Run remains available offline.',
            )
          else
            for (final route in pack.routes)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _RouteCard(
                  route: route,
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteDetailsScreen(
                        pack: pack,
                        route: route,
                        onStart: onStartRoute,
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  void _startFreeRun(BuildContext context) {
    if (onStartFreeRun != null) {
      onStartFreeRun!(pack);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Free Run tracking is being connected.')),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.pack,
    required this.accentColor,
    required this.onTap,
  });

  final DestinationPack pack;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final artworkPath = switch (pack.id) {
      'nha-trang' => 'assets/destinations/artwork/nha_trang_coast.png',
      'ho-chi-minh-city' => 'assets/destinations/artwork/ho_chi_minh_city.png',
      _ => null,
    };
    return Semantics(
      button: true,
      label: 'Open ${pack.cityName}',
      child: InkWell(
        key: ValueKey('destination-${pack.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: QuestoryColors.ink, width: 2),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: QuestoryColors.ink,
                offset: Offset(5, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: artworkPath == null
                      ? ColoredBox(
                          color: accentColor,
                          child: const Icon(
                            Icons.explore_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        )
                      : Image.asset(
                          artworkPath,
                          fit: BoxFit.cover,
                          cacheWidth: 256,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: accentColor,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.cityName,
                      style: const TextStyle(
                        color: QuestoryColors.ink,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pack.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${pack.routes.length} ROUTE • '
                      '${pack.quests.length} QUESTS',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, required this.onTap});

  final RoutePlan route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: ListTile(
        key: ValueKey('route-${route.id}'),
        contentPadding: const EdgeInsets.all(16),
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: QuestoryColors.yellow,
          child: Icon(Icons.directions_run_rounded),
        ),
        title: Text(
          route.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${(route.distanceMeters / 1000).toStringAsFixed(1)} km • '
            '${route.estimatedDuration.inMinutes} min • ${route.difficulty}\n'
            '${route.landmarks.length} landmarks • '
            '${route.questIds.length} quests',
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _OfflineLabel extends StatelessWidget {
  const _OfflineLabel();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: QuestoryColors.yellow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.offline_bolt_rounded, size: 18),
              SizedBox(width: 7),
              Text(
                'OFFLINE CITY PACKS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
