import 'package:flutter/material.dart';

class TrackFriend {
  const TrackFriend({
    required this.id,
    required this.name,
    required this.username,
    required this.color,
    this.isOnline = true,
  });

  final String id;
  final String name;
  final String username;
  final Color color;
  final bool isOnline;
}

const starterTrackFriends = [
  TrackFriend(
    id: 'minh',
    name: 'Minh',
    username: '@minh.runs',
    color: Color(0xFFFF6B5E),
  ),
  TrackFriend(
    id: 'an',
    name: 'An',
    username: '@an.explores',
    color: Color(0xFF3157C8),
  ),
  TrackFriend(
    id: 'linh',
    name: 'Linh',
    username: '@linh.tracks',
    color: Color(0xFF0B7A75),
  ),
];

class FriendAvatar extends StatelessWidget {
  const FriendAvatar({
    super.key,
    required this.friend,
    this.selected = false,
  });

  final TrackFriend friend;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: friend.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? const Color(0xFFFFD447) : Colors.white,
              width: selected ? 4 : 2,
            ),
          ),
          child: Text(
            friend.name.characters.first.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (friend.isOnline)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFF36C76C),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class AddFriendSheet extends StatefulWidget {
  const AddFriendSheet({
    super.key,
    required this.existingNames,
  });

  final Set<String> existingNames;

  @override
  State<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<AddFriendSheet> {
  final _nameController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _add() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a friend name.');
      return;
    }
    if (widget.existingNames.contains(name.toLowerCase())) {
      setState(() => _error = '$name is already in your circle.');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add Friends',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add someone to your local Tracks circle for this demo.',
            ),
            const SizedBox(height: 18),
            TextField(
              key: const ValueKey('friend-name'),
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _add(),
              decoration: InputDecoration(
                labelText: 'Friend name',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('confirm-add-friend'),
              onPressed: _add,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('ADD TO CIRCLE'),
            ),
          ],
        ),
      ),
    );
  }
}
