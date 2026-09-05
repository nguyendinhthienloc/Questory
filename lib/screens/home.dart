import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'friends.dart';
import 'history.dart';
import 'preview.dart';

typedef CameraDescriptionLoader = Future<List<CameraDescription>> Function();

/// Retains the original Locket-style camera interaction as Questory's photo
/// quest camera, while representing unavailable hardware as a safe demo state.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onPhotoAccepted,
    this.cameraLoader,
    this.forceDemoMode = false,
  });

  final ValueChanged<CapturedQuestPhoto>? onPhotoAccepted;
  final CameraDescriptionLoader? cameraLoader;
  final bool forceDemoMode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  final List<CapturedQuestPhoto> _captures = [];
  final List<TrackFriend> _friends = List.of(starterTrackFriends);
  var _cameraIndex = 0;
  var _loading = true;
  var _capturing = false;
  var _flashEnabled = false;
  var _demoAssetIndex = 0;
  var _mockOnline = true;
  String? _cameraMessage;

  bool get _cameraReady => _controller?.value.isInitialized ?? false;

  @override
  void initState() {
    super.initState();
    _initialiseCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initialiseCamera() async {
    if (widget.forceDemoMode) {
      if (mounted) {
        setState(() {
          _loading = false;
          _cameraMessage =
              'Demo camera is active. Use the sample photo to continue.';
        });
      }
      return;
    }
    try {
      final cameras = await (widget.cameraLoader ?? availableCameras)();
      if (cameras.isEmpty) {
        _showCameraFallback('No camera was found on this device.');
        return;
      }
      _cameras = cameras;
      await _openCamera(0);
    } on CameraException catch (error) {
      _showCameraFallback(_cameraErrorMessage(error.code));
    } catch (_) {
      _showCameraFallback(
        'Camera access is unavailable. You can still use demo evidence.',
      );
    }
  }

  Future<void> _openCamera(int index) async {
    if (_cameras.isEmpty) {
      return;
    }
    setState(() => _loading = true);
    final previous = _controller;
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;
    await previous?.dispose();
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraIndex = index;
        _loading = false;
        _cameraMessage = null;
        _flashEnabled = false;
      });
    } on CameraException catch (error) {
      await controller.dispose();
      if (identical(_controller, controller)) {
        _controller = null;
      }
      _showCameraFallback(_cameraErrorMessage(error.code));
    } catch (_) {
      await controller.dispose();
      if (identical(_controller, controller)) {
        _controller = null;
      }
      _showCameraFallback(
        'The camera could not start. Use demo evidence to keep going.',
      );
    }
  }

  void _showCameraFallback(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _cameraMessage = message;
    });
  }

  Future<void> _capture() async {
    if (_capturing) {
      return;
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      await _useDemoPhoto();
      return;
    }
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() => _capturing = false);
      }
      await _reviewPhoto(bytes: bytes, isDemo: false);
    } on CameraException catch (error) {
      _showMessage(_cameraErrorMessage(error.code));
    } catch (_) {
      _showMessage('The photo could not be captured. Try demo evidence.');
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  Future<void> _useDemoPhoto() async {
    if (_capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final assetPath =
          _legacyLocketAssets[_demoAssetIndex % _legacyLocketAssets.length];
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      _demoAssetIndex++;
      if (mounted) {
        setState(() => _capturing = false);
      }
      await _reviewPhoto(bytes: bytes, isDemo: true);
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  Future<void> _reviewPhoto({
    required Uint8List bytes,
    required bool isDemo,
  }) async {
    if (!mounted) {
      return;
    }
    final photo = await showModalBottomSheet<CapturedQuestPhoto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoReviewSheet(
        bytes: bytes,
        isDemo: isDemo,
        friends: _friends,
        mockOnline: _mockOnline,
      ),
    );
    if (photo == null || !mounted) {
      return;
    }
    setState(() => _captures.insert(0, photo));
    widget.onPhotoAccepted?.call(photo);
    final message = switch (photo.delivery) {
      TrackDelivery.saved => 'Track saved to your Journey.',
      TrackDelivery.queued =>
        'Track saved offline and queued for ${photo.sharedWith.join(', ')}.',
      TrackDelivery.delivered =>
        'Mock delivery sent to ${photo.sharedWith.join(', ')}.',
    };
    _showMessage(message);
  }

  Future<void> _openAddFriend() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddFriendSheet(
        existingNames: {
          for (final friend in _friends) friend.name.toLowerCase(),
        },
      ),
    );
    if (name == null || !mounted) return;
    const colors = [
      Color(0xFF0B7A75),
      Color(0xFFFF6B5E),
      Color(0xFF3157C8),
      Color(0xFF9B51E0),
    ];
    setState(() {
      _friends.add(
        TrackFriend(
          id: 'friend-${_friends.length}-${name.toLowerCase()}',
          name: name,
          username: '@${name.toLowerCase().replaceAll(' ', '.')}',
          color: colors[_friends.length % colors.length],
        ),
      );
    });
    _showMessage('$name was added to your Tracks circle.');
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      _showMessage('Flash needs an active camera.');
      return;
    }
    try {
      final next = !_flashEnabled;
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) {
        setState(() => _flashEnabled = next);
      }
    } on CameraException {
      _showMessage('Flash is not supported by this camera.');
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) {
      _showMessage('Only one camera is available.');
      return;
    }
    await _openCamera((_cameraIndex + 1) % _cameras.length);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1B20),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            _CameraHeader(friendCount: _friends.length),
            const SizedBox(height: 12),
            _FriendCircle(
              friends: _friends,
              mockOnline: _mockOnline,
              onOnlineChanged: (value) => setState(() => _mockOnline = value),
              onAddFriend: _openAddFriend,
            ),
            const SizedBox(height: 18),
            _CameraSurface(
              controller: _cameraReady ? _controller : null,
              loading: _loading,
              message: _cameraMessage,
              captureCount: _captures.length,
            ),
            const SizedBox(height: 18),
            _CameraControls(
              cameraReady: _cameraReady,
              capturing: _capturing,
              flashEnabled: _flashEnabled,
              canFlip: _cameras.length > 1,
              onFlash: _toggleFlash,
              onCapture: _capture,
              onFlip: _flipCamera,
            ),
            if (!_cameraReady) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                key: const ValueKey('use-demo-photo'),
                onPressed: _capturing ? null : _useDemoPhoto,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFFFD447), width: 2),
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('USE DEMO PHOTO'),
              ),
            ],
            const SizedBox(height: 24),
            LocketCaptureHistory(
              captures: _captures,
              onRemove: (index) {
                setState(() => _captures.removeAt(index));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraHeader extends StatelessWidget {
  const _CameraHeader({required this.friendCount});

  final int friendCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD447),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.camera_alt_outlined),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TRACKS',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              Text(
                'Track your Tracks — share moments with your circle',
                style: TextStyle(color: Color(0xFFBBB6C2)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF47444C),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$friendCount FRIENDS',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendCircle extends StatelessWidget {
  const _FriendCircle({
    required this.friends,
    required this.mockOnline,
    required this.onOnlineChanged,
    required this.onAddFriend,
  });

  final List<TrackFriend> friends;
  final bool mockOnline;
  final ValueChanged<bool> onOnlineChanged;
  final VoidCallback onAddFriend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: friends.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (_, index) => FriendAvatar(
                    friend: friends[index],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              key: const ValueKey('add-friends'),
              onPressed: onAddFriend,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Friends'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF343138),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                mockOnline
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: mockOnline
                    ? const Color(0xFF36C76C)
                    : const Color(0xFFFFD447),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mockOnline
                      ? 'Mock friends online'
                      : 'Offline: shares queue locally',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch(
                key: const ValueKey('tracks-online-toggle'),
                value: mockOnline,
                onChanged: onOnlineChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CameraSurface extends StatelessWidget {
  const _CameraSurface({
    required this.controller,
    required this.loading,
    required this.message,
    required this.captureCount,
  });

  final CameraController? controller;
  final bool loading;
  final String? message;
  final int captureCount;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null)
              CameraPreview(controller!)
            else
              const _DemoCameraArtwork(),
            if (loading)
              const ColoredBox(
                color: Color(0x991D1B20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFD447)),
                ),
              ),
            if (!loading && controller == null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xDD1D1B20),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message ?? 'Camera unavailable. Demo evidence is ready.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xCC1D1B20),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$captureCount CAPTURED',
                  key: const ValueKey('camera-capture-count'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoCameraArtwork extends StatelessWidget {
  const _DemoCameraArtwork();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _legacyLocketAssets.first,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFF0B7A75),
        child: Center(
          child: Icon(
            Icons.photo_camera_outlined,
            color: Color(0xFFFFD447),
            size: 72,
          ),
        ),
      ),
    );
  }
}

class _CameraControls extends StatelessWidget {
  const _CameraControls({
    required this.cameraReady,
    required this.capturing,
    required this.flashEnabled,
    required this.canFlip,
    required this.onFlash,
    required this.onCapture,
    required this.onFlip,
  });

  final bool cameraReady;
  final bool capturing;
  final bool flashEnabled;
  final bool canFlip;
  final VoidCallback onFlash;
  final VoidCallback onCapture;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton.filledTonal(
          tooltip: 'Flash',
          onPressed: cameraReady ? onFlash : null,
          icon: Icon(flashEnabled ? Icons.flash_on : Icons.flash_off),
        ),
        Semantics(
          button: true,
          label: cameraReady ? 'Take photo' : 'Create demo photo',
          child: InkWell(
            key: const ValueKey('quest-shutter'),
            onTap: capturing ? null : onCapture,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              width: 88,
              height: 88,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD447), width: 5),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: capturing ? const Color(0xFF77727C) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: capturing
                    ? const Padding(
                        padding: EdgeInsets.all(18),
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : null,
              ),
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Flip camera',
          onPressed: canFlip ? onFlip : null,
          icon: const Icon(Icons.flip_camera_ios_outlined),
        ),
      ],
    );
  }
}

String _cameraErrorMessage(String code) {
  return switch (code) {
    'CameraAccessDenied' =>
      'Camera permission was denied. Use demo evidence or allow camera access in settings.',
    'CameraAccessDeniedWithoutPrompt' ||
    'CameraAccessRestricted' =>
      'Camera access is blocked by browser or device settings. Demo evidence is available.',
    _ => 'The camera is unavailable right now. Use demo evidence to continue.',
  };
}

const _legacyLocketAssets = [
  'images/i1.JPG',
  'images/i2.JPG',
  'images/i3.JPG',
  'images/i4.JPG',
];
