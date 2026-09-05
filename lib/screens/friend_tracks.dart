import 'package:flutter/material.dart';

import 'friends.dart';
import 'preview.dart';

class MockFriendTrack {
  const MockFriendTrack({
    required this.id,
    required this.friend,
    required this.assetPath,
    required this.caption,
    required this.locationLabel,
    required this.timeLabel,
    required this.reactionCount,
  });

  final String id;
  final TrackFriend friend;
  final String assetPath;
  final String caption;
  final String locationLabel;
  final String timeLabel;
  final int reactionCount;
}

final starterFriendTracks = [
  MockFriendTrack(
    id: 'minh-sunrise',
    friend: starterTrackFriends[0],
    assetPath: 'assets/tracks/friends/minh-sunrise.jpg',
    caption: 'Sunrise miles before the city wakes up.',
    locationLabel: 'Tran Phu Beach, Nha Trang',
    timeLabel: '12 min ago',
    reactionCount: 8,
  ),
  MockFriendTrack(
    id: 'an-nguyen-hue',
    friend: starterTrackFriends[1],
    assetPath: 'assets/tracks/friends/an-nguyen-hue.jpg',
    caption: 'Quick lace check, then one more city loop.',
    locationLabel: 'Nguyen Hue, Ho Chi Minh City',
    timeLabel: '28 min ago',
    reactionCount: 5,
  ),
  MockFriendTrack(
    id: 'linh-riverside',
    friend: starterTrackFriends[2],
    assetPath: 'assets/tracks/friends/linh-riverside.jpg',
    caption: 'Post-run iced tea tastes better by the river.',
    locationLabel: 'Bach Dang Park, Ho Chi Minh City',
    timeLabel: '1 hr ago',
    reactionCount: 11,
  ),
  MockFriendTrack(
    id: 'minh-coastal-run',
    friend: starterTrackFriends[0],
    assetPath: 'assets/tracks/friends/minh-coastal-run.jpg',
    caption: 'Found the best curve on today\'s coastal Track.',
    locationLabel: 'Nha Trang coast',
    timeLabel: 'Yesterday',
    reactionCount: 14,
  ),
];

class FriendTrackPage extends StatelessWidget {
  const FriendTrackPage({
    super.key,
    required this.post,
    required this.liked,
    required this.onToggleLike,
    required this.positionLabel,
  });

  final MockFriendTrack post;
  final bool liked;
  final VoidCallback onToggleLike;
  final String positionLabel;

  @override
  Widget build(BuildContext context) {
    return _TrackPostPage(
      key: ValueKey('track-friend-post-${post.id}'),
      image: AssetImage(post.assetPath),
      friend: post.friend,
      caption: post.caption,
      locationLabel: post.locationLabel,
      timeLabel: post.timeLabel,
      badgeLabel: 'FRIEND TRACK',
      positionLabel: positionLabel,
      reactionCount: post.reactionCount,
      liked: liked,
      onToggleLike: onToggleLike,
    );
  }
}

class CapturedTrackPage extends StatelessWidget {
  const CapturedTrackPage({
    super.key,
    required this.capture,
    required this.positionLabel,
    required this.onDelete,
  });

  final CapturedQuestPhoto capture;
  final String positionLabel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    const you = TrackFriend(
      id: 'you',
      name: 'You',
      username: '@your.tracks',
      color: Color(0xFFFFD447),
    );
    return _TrackPostPage(
      key:
          ValueKey('captured-track-${capture.capturedAtUtc.toIso8601String()}'),
      image: MemoryImage(capture.bytes),
      friend: you,
      caption: capture.caption,
      locationLabel: 'Saved on this device',
      timeLabel: 'Just now',
      badgeLabel: switch (capture.delivery) {
        TrackDelivery.saved => 'PRIVATE TRACK',
        TrackDelivery.queued => 'QUEUED OFFLINE',
        TrackDelivery.delivered => 'SHARED TRACK',
      },
      positionLabel: positionLabel,
      trailingAction: IconButton.filledTonal(
        key: const ValueKey('delete-current-track'),
        tooltip: 'Delete this Track',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }
}

class _TrackPostPage extends StatelessWidget {
  const _TrackPostPage({
    super.key,
    required this.image,
    required this.friend,
    required this.caption,
    required this.locationLabel,
    required this.timeLabel,
    required this.badgeLabel,
    required this.positionLabel,
    this.reactionCount,
    this.liked = false,
    this.onToggleLike,
    this.trailingAction,
  });

  final ImageProvider<Object> image;
  final TrackFriend friend;
  final String caption;
  final String locationLabel;
  final String timeLabel;
  final String badgeLabel;
  final String positionLabel;
  final int? reactionCount;
  final bool liked;
  final VoidCallback? onToggleLike;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1D1B20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD447),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badgeLabel,
                    style: const TextStyle(
                      color: Color(0xFF1D1B20),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  positionLabel,
                  style: const TextStyle(
                    color: Color(0xFFBBB6C2),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(image: image, fit: BoxFit.cover),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(14),
                        padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
                        decoration: BoxDecoration(
                          color: const Color(0xD91D1B20),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FriendAvatar(friend: friend),
                            const SizedBox(width: 9),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friend.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  friend.username,
                                  style: const TextStyle(
                                    color: Color(0xFFD7D2DB),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                        color: const Color(0xD91D1B20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    caption,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        color: Color(0xFFFFD447),
                                        size: 17,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '$locationLabel  •  $timeLabel',
                                          style: const TextStyle(
                                            color: Color(0xFFD7D2DB),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (onToggleLike != null)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton.filled(
                                    key: ValueKey('react-to-${friend.id}'),
                                    tooltip: liked
                                        ? 'Remove reaction'
                                        : 'React to this Track',
                                    onPressed: onToggleLike,
                                    style: IconButton.styleFrom(
                                      backgroundColor: liked
                                          ? const Color(0xFFFF6B5E)
                                          : Colors.white,
                                      foregroundColor: liked
                                          ? Colors.white
                                          : const Color(0xFFFF6B5E),
                                    ),
                                    icon: Icon(
                                      liked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                    ),
                                  ),
                                  Text(
                                    '${(reactionCount ?? 0) + (liked ? 1 : 0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              )
                            else if (trailingAction != null)
                              trailingAction!,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Color(0xFFFFD447),
                ),
                SizedBox(width: 4),
                Text(
                  'SWIPE FOR NEXT TRACK',
                  style: TextStyle(
                    color: Color(0xFFBBB6C2),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
