import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'friends.dart';

enum TrackDelivery { saved, queued, delivered }

class CapturedQuestPhoto {
  CapturedQuestPhoto({
    required Uint8List bytes,
    required this.caption,
    required this.capturedAtUtc,
    required this.isDemo,
    this.sharedWith = const [],
    this.delivery = TrackDelivery.saved,
  })  : bytes = Uint8List.fromList(bytes),
        dataUri = 'data:${_imageMimeType(bytes)};base64,${base64Encode(bytes)}';

  final Uint8List bytes;
  final String dataUri;
  final String caption;
  final DateTime capturedAtUtc;
  final bool isDemo;
  final List<String> sharedWith;
  final TrackDelivery delivery;
}

String _imageMimeType(Uint8List bytes) {
  final isPng = bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47;
  return isPng ? 'image/png' : 'image/jpeg';
}

/// The legacy Locket preview, adapted to return an immutable photo result.
class PhotoReviewSheet extends StatefulWidget {
  const PhotoReviewSheet({
    super.key,
    required this.bytes,
    required this.isDemo,
    this.friends = starterTrackFriends,
    this.mockOnline = true,
  });

  final Uint8List bytes;
  final bool isDemo;
  final List<TrackFriend> friends;
  final bool mockOnline;

  @override
  State<PhotoReviewSheet> createState() => _PhotoReviewSheetState();
}

class _PhotoReviewSheetState extends State<PhotoReviewSheet> {
  final _captionController = TextEditingController(
    text: 'A bright moment along the Nha Trang coast.',
  );
  final Set<String> _selectedFriendIds = {};

  @override
  void initState() {
    super.initState();
    _selectedFriendIds.addAll(widget.friends.map((friend) => friend.id));
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight = MediaQuery.sizeOf(context).height - bottomInset;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: availableHeight * 0.92,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F1E3),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Share a Track',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (widget.isDemo) const DemoEvidenceBadge(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.memory(widget.bytes, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('quest-photo-caption'),
                    controller: _captionController,
                    maxLength: 120,
                    decoration: const InputDecoration(
                      labelText: 'Caption',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'SEND TO',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        widget.mockOnline
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          widget.mockOnline
                              ? 'Mock accounts online'
                              : 'Offline — sharing will be queued',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (widget.friends.isEmpty)
                    const Text(
                      'No friends yet. This Track will stay in your Journey.',
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final friend in widget.friends)
                          FilterChip(
                            key: ValueKey('share-friend-${friend.id}'),
                            selected: _selectedFriendIds.contains(friend.id),
                            avatar: FriendAvatar(
                              friend: friend,
                              selected: _selectedFriendIds.contains(friend.id),
                            ),
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(friend.name),
                                Text(
                                  friend.username,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedFriendIds.add(friend.id);
                                } else {
                                  _selectedFriendIds.remove(friend.id);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('RETAKE'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey('accept-quest-photo'),
                          onPressed: () {
                            final caption = _captionController.text.trim();
                            if (caption.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Add a caption for this photo.'),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(
                              context,
                              CapturedQuestPhoto(
                                bytes: widget.bytes,
                                caption: caption,
                                capturedAtUtc: DateTime.now().toUtc(),
                                isDemo: widget.isDemo,
                                sharedWith: [
                                  for (final friend in widget.friends)
                                    if (_selectedFriendIds.contains(friend.id))
                                      friend.name,
                                ],
                                delivery: _selectedFriendIds.isEmpty
                                    ? TrackDelivery.saved
                                    : widget.mockOnline
                                        ? TrackDelivery.delivered
                                        : TrackDelivery.queued,
                              ),
                            );
                          },
                          child: Text(
                            _selectedFriendIds.isEmpty
                                ? 'SAVE TRACK'
                                : 'SHARE TRACK',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DemoEvidenceBadge extends StatelessWidget {
  const DemoEvidenceBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD447),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'DEMO',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}
