import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/contracts/clock.dart';
import '../../../core/contracts/photo_store.dart';
import '../../../core/domain/destination_models.dart';
import '../../../core/domain/run_models.dart';
import '../../destinations/presentation/explore_screen.dart';

class QuestCameraScreen extends StatefulWidget {
  const QuestCameraScreen({
    super.key,
    required this.quest,
    required this.point,
    required this.photoStore,
    required this.clock,
  });

  final Quest quest;
  final GeoPoint point;
  final PhotoStore photoStore;
  final Clock clock;

  @override
  State<QuestCameraScreen> createState() => _QuestCameraScreenState();
}

class _QuestCameraScreenState extends State<QuestCameraScreen> {
  CameraController? _controller;
  Object? _error;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _error = null);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera is available on this device.');
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on CameraException catch (error) {
      if (mounted) setState(() => _error = _cameraMessage(error));
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  String _cameraMessage(CameraException error) {
    if (error.code == 'CameraAccessDenied' ||
        error.code == 'CameraAccessDeniedWithoutPrompt') {
      return 'Camera permission was denied. Enable it in Android settings to '
          'capture quest evidence.';
    }
    return 'Camera unavailable: ${error.description ?? error.code}';
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy) return;
    setState(() => _busy = true);
    try {
      final capture = await controller.takePicture();
      if (!mounted) return;
      final caption = await _requestCaption(capture.path);
      if (caption == null || !mounted) return;
      final now = widget.clock.nowUtc();
      final evidenceId = 'evidence-${now.microsecondsSinceEpoch}';
      final retainedPath = await widget.photoStore.retain(
        temporaryPath: capture.path,
        evidenceId: evidenceId,
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        QuestEvidence(
          id: evidenceId,
          questId: widget.quest.id,
          photoPath: retainedPath,
          point: widget.point,
          capturedAtUtc: now,
          caption: caption,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo could not be saved: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _requestCaption(String path) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => QuestCaptionSheet(
        path: path,
        quest: widget.quest,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: QuestoryColors.ink,
      appBar: AppBar(
        backgroundColor: QuestoryColors.ink,
        foregroundColor: Colors.white,
        title: const Text('Quest Camera'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    widget.quest.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.quest.prompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: ColoredBox(
                    color: const Color(0xFF2B292E),
                    child: Center(
                      child: _error != null
                          ? _CameraError(error: '$_error', onRetry: _initialize)
                          : controller == null ||
                                  !controller.value.isInitialized
                              ? const CircularProgressIndicator()
                              : CameraPreview(controller),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Semantics(
                button: true,
                label: 'Capture quest photo',
                child: InkWell(
                  key: const ValueKey('capture-quest-photo'),
                  onTap: _error == null ? _capture : null,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: _busy ? Colors.grey : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: QuestoryColors.yellow,
                        width: 6,
                      ),
                    ),
                    child: _busy
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          )
                        : const Icon(Icons.camera_alt_rounded, size: 36),
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

class QuestCaptionSheet extends StatefulWidget {
  const QuestCaptionSheet({super.key, required this.path, required this.quest});

  final String path;
  final Quest quest;

  @override
  State<QuestCaptionSheet> createState() => _QuestCaptionSheetState();
}

class _QuestCaptionSheetState extends State<QuestCaptionSheet> {
  final TextEditingController _captionController = TextEditingController();
  String? _validation;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _save() {
    final caption = _captionController.text.trim();
    if (widget.quest.captionRequired && caption.isEmpty) {
      setState(() => _validation = 'Add a short caption.');
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.pop(context, caption);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(widget.path),
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 180,
                    child: ColoredBox(
                      color: Color(0xFFE5E1D8),
                      child: Center(
                        child: Icon(Icons.broken_image_outlined, size: 42),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.quest.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('quest-caption'),
                controller: _captionController,
                maxLength: 140,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  labelText: widget.quest.captionRequired
                      ? 'Caption (required)'
                      : 'Caption (optional)',
                  errorText: _validation,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const ValueKey('save-quest-evidence'),
                onPressed: _save,
                child: const Text('SAVE QUEST PHOTO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined,
              color: Colors.white, size: 58),
          const SizedBox(height: 14),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('TRY AGAIN'),
          ),
        ],
      ),
    );
  }
}
