import 'package:flutter/material.dart';

import 'preview.dart';

/// A private, session-scoped history of captured Tracks.
class LocketCaptureHistory extends StatelessWidget {
  const LocketCaptureHistory({
    super.key,
    required this.captures,
    required this.onRemove,
  });

  final List<CapturedQuestPhoto> captures;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT TRACKS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        if (captures.isEmpty)
          const Text(
            'No new captures yet. Take a photo or use a bundled sample.',
            style: TextStyle(color: Color(0xFFBBB6C2)),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: captures.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final capture = captures[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 150,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(capture.bytes, fit: BoxFit.cover),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(10, 24, 6, 6),
                            color: const Color(0x991D1B20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    switch (capture.delivery) {
                                      TrackDelivery.saved => capture.caption,
                                      TrackDelivery.queued =>
                                        '${capture.caption}\nQueued for ${capture.sharedWith.join(', ')}',
                                      TrackDelivery.delivered =>
                                        '${capture.caption}\nSent to ${capture.sharedWith.join(', ')}',
                                    },
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  key: ValueKey('delete-locket-photo-$index'),
                                  tooltip: 'Remove photo',
                                  onPressed: () => onRemove(index),
                                  color: Colors.white,
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
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
    );
  }
}
