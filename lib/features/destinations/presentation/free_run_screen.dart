import 'package:flutter/material.dart';

import '../../../core/domain/destination_models.dart';
import 'explore_screen.dart';

class FreeRunDiscoveryScreen extends StatelessWidget {
  const FreeRunDiscoveryScreen({
    super.key,
    required this.pack,
    required this.onStart,
  });

  final DestinationPack pack;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestoryColors.paper,
      appBar: AppBar(
        backgroundColor: QuestoryColors.paper,
        title: Text('${pack.cityName} Free Run'),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(18),
        child: FilledButton.icon(
          key: const ValueKey('begin-free-run'),
          onPressed: onStart,
          icon: const Icon(Icons.directions_run_rounded),
          label: const Text('BEGIN FREE RUN'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const _OfflineNotice(),
          const SizedBox(height: 20),
          const Text(
            'Discover as you run',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Questory uses bundled points of interest. No map connection is '
            'required, and nearby quests unlock from your recorded position.',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 22),
          if (pack.pointsOfInterest.isEmpty)
            const Text('No bundled discovery points are available.')
          else
            for (final point in pack.pointsOfInterest)
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: QuestoryColors.yellow,
                    child: Icon(Icons.place_rounded, color: QuestoryColors.ink),
                  ),
                  title: Text(
                    point.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${point.description}\n${point.questIds.length} photo quest${point.questIds.length == 1 ? '' : 's'}',
                  ),
                  isThreeLine: true,
                ),
              ),
        ],
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QuestoryColors.teal,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.offline_bolt_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'OFFLINE DISCOVERY PACK READY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
