import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/contracts/share_service.dart';
import '../../../core/contracts/story_renderer.dart';
import '../../../core/contracts/story_repository.dart';
import '../../../core/domain/run_models.dart';
import '../../../core/domain/story_project.dart';
import '../../../core/fixtures/fake_story_services.dart';
import '../application/story_editor_controller.dart';
import '../application/story_builder.dart';
import '../application/story_export_services.dart';
import '../data/sample_run.dart';
import '../data/story_templates.dart';
import 'story_canvas.dart';

class StoryStudioScreen extends StatefulWidget {
  const StoryStudioScreen({
    super.key,
    this.runSummary,
    this.repository,
    this.renderer,
    this.shareService,
    this.initialDocument,
  });

  final RunSummary? runSummary;
  final StoryRepository? repository;
  final StoryRenderer? renderer;
  final ShareService? shareService;
  final StoryDocument? initialDocument;

  @override
  State<StoryStudioScreen> createState() => _StoryStudioScreenState();
}

class _StoryStudioScreenState extends State<StoryStudioScreen> {
  final GlobalKey _exportBoundaryKey = GlobalKey();
  final StoryBuilder _storyBuilder = const StoryBuilder();
  late final RunSummary _summary;
  late final StoryRepository _repository;
  late final ShareService _shareService;
  late final StoryRenderer _renderer;
  late StoryEditorController _editor;
  late StoryTemplate _template;
  var _status = 'Tap an element, then drag, pinch, or twist to edit it.';
  var _isExporting = false;

  @override
  void initState() {
    super.initState();
    _summary = widget.runSummary ?? sampleRunSummary;
    _repository = widget.repository ?? FakeStoryRepository();
    _shareService = widget.shareService ?? const AndroidShareService();
    _renderer = widget.renderer ??
        BoundaryStoryRenderer(boundaryKey: _exportBoundaryKey);
    _template = storyTemplates.first;
    _editor = StoryEditorController(
      widget.initialDocument ?? _documentFor(_template),
    )..addListener(_refresh);
  }

  @override
  void dispose() {
    _editor
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  StoryDocument _documentFor(StoryTemplate template) {
    final prefix = widget.runSummary == null ? 'draft' : 'story-${_summary.id}';
    return _storyBuilder.fromRun(
      template: template,
      summary: _summary,
      documentId: '$prefix-${template.id}',
    );
  }

  void _selectTemplate(StoryTemplate template) {
    setState(() {
      _template = template;
      _status = template.description;
    });
    _editor.replaceDocument(_documentFor(template));
  }

  Future<void> _save() async {
    try {
      await _repository.save(_editor.document);
      _setStatus('Editable project saved locally.');
    } catch (error) {
      _setStatus('Save failed: $error');
    }
  }

  Future<void> _reopen() async {
    try {
      final saved = await _repository.load(_editor.document.id);
      if (saved == null) {
        _setStatus('No saved copy exists for this template yet.');
        return;
      }
      _editor.replaceDocument(saved);
      _setStatus('Saved project reopened with its edits and layer order.');
    } catch (error) {
      _setStatus('Open failed: $error');
    }
  }

  Future<void> _exportAndShare() async {
    if (_isExporting) {
      return;
    }
    setState(() {
      _isExporting = true;
      _status = 'Rendering the 1080 x 1920 PNG…';
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      final export = await _renderer.renderPng(_editor.document);
      if (export.width != storyCanvasWidth.toInt() ||
          export.height != storyCanvasHeight.toInt()) {
        throw StateError('The renderer returned incorrect export dimensions.');
      }
      await _shareService.sharePng(
        path: export.path,
        title: _editor.document.title,
      );
      _setStatus('Export ready: 1080 x 1920 PNG. Android share sheet opened.');
    } catch (error) {
      _setStatus('Export failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _setStatus(String value) {
    if (mounted) {
      setState(() => _status = value);
    }
  }

  Future<void> _editText() async {
    final element = _editor.selectedElement;
    if (element == null) {
      return;
    }
    final textController = TextEditingController(text: element.content);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit element text'),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Story text'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (result != null) {
      _editor.updateSelectedContent(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(StoryPalette.ink),
      appBar: AppBar(
        backgroundColor: const Color(StoryPalette.ink),
        foregroundColor: const Color(StoryPalette.paper),
        title: const Text('Story Studio'),
        actions: [
          IconButton(
            key: const ValueKey('undo-story'),
            tooltip: 'Undo',
            onPressed: _editor.canUndo ? _editor.undo : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            key: const ValueKey('redo-story'),
            tooltip: 'Redo',
            onPressed: _editor.canRedo ? _editor.redo : null,
            icon: const Icon(Icons.redo_rounded),
          ),
          TextButton(
            key: const ValueKey('export-story'),
            onPressed: _isExporting ? null : _exportAndShare,
            child: Text(
              _isExporting ? 'EXPORTING…' : 'EXPORT',
              style: const TextStyle(color: Color(StoryPalette.yellow)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _TemplatePicker(
              selectedTemplate: _template,
              onSelected: _selectTemplate,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: StoryCanvas(
                  document: _editor.document,
                  boundaryKey: _exportBoundaryKey,
                  selectedElementId: _editor.selectedElementId,
                  guides: _editor.guides,
                  showEditorChrome: !_isExporting,
                  onElementTap: (element) {
                    _editor.select(element.id);
                    _setStatus('Selected: ${element.content}');
                  },
                  onInteractionStart: _editor.beginInteraction,
                  onInteractionUpdate: (
                    dx,
                    dy,
                    scale,
                    rotation,
                  ) {
                    _editor.updateInteraction(
                      deltaX: dx,
                      deltaY: dy,
                      scale: scale,
                      rotation: rotation,
                    );
                  },
                  onInteractionEnd: _editor.endInteraction,
                ),
              ),
            ),
            _EditorPanel(
              editor: _editor,
              status: _status,
              onEditText: _editText,
              onSave: _save,
              onReopen: _reopen,
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({
    required this.selectedTemplate,
    required this.onSelected,
  });

  final StoryTemplate selectedTemplate;
  final ValueChanged<StoryTemplate> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: storyTemplates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final template = storyTemplates[index];
          return ChoiceChip(
            label: Text(template.name),
            selected: template.id == selectedTemplate.id,
            onSelected: (_) => onSelected(template),
            selectedColor: const Color(StoryPalette.yellow),
            backgroundColor: const Color(0xFF2C2C2C),
            labelStyle: TextStyle(
              color: template.id == selectedTemplate.id
                  ? const Color(StoryPalette.ink)
                  : const Color(StoryPalette.paper),
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide.none,
          );
        },
      ),
    );
  }
}

class _EditorPanel extends StatelessWidget {
  const _EditorPanel({
    required this.editor,
    required this.status,
    required this.onEditText,
    required this.onSave,
    required this.onReopen,
  });

  final StoryEditorController editor;
  final String status;
  final VoidCallback onEditText;
  final VoidCallback onSave;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final element = editor.selectedElement;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 230),
      child: ColoredBox(
        color: const Color(0xFF232323),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                key: const ValueKey('story-status'),
                style: const TextStyle(
                  color: Color(StoryPalette.paper),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 2,
                runSpacing: 2,
                children: [
                  _tool(
                    key: 'save-story',
                    icon: Icons.save_outlined,
                    label: 'Save',
                    onPressed: onSave,
                  ),
                  _tool(
                    key: 'reopen-story',
                    icon: Icons.folder_open_outlined,
                    label: 'Open saved',
                    onPressed: onReopen,
                  ),
                  _tool(
                    key: 'edit-story-text',
                    icon: Icons.edit_outlined,
                    label: 'Edit text',
                    onPressed: element == null ? null : onEditText,
                  ),
                  _tool(
                    key: 'duplicate-story-element',
                    icon: Icons.copy_outlined,
                    label: 'Duplicate',
                    onPressed:
                        element == null ? null : editor.duplicateSelected,
                  ),
                  _tool(
                    key: 'story-layer-back',
                    icon: Icons.flip_to_back_outlined,
                    label: 'Backward',
                    onPressed: element == null ? null : editor.sendBackward,
                  ),
                  _tool(
                    key: 'story-layer-front',
                    icon: Icons.flip_to_front_outlined,
                    label: 'Forward',
                    onPressed: element == null ? null : editor.bringForward,
                  ),
                  _tool(
                    key: 'story-rotate-left',
                    icon: Icons.rotate_left_rounded,
                    label: 'Rotate',
                    onPressed: element == null
                        ? null
                        : () => editor.rotateSelected(-math.pi / 18),
                  ),
                  _tool(
                    key: 'delete-story-element',
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    onPressed: element == null ? null : editor.deleteSelected,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _StyleControls(editor: editor, element: element),
              if (element?.type == StoryElementType.photo) ...[
                const SizedBox(height: 8),
                _PhotoCropControls(editor: editor, element: element!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tool({
    required String key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      key: ValueKey(key),
      tooltip: label,
      onPressed: onPressed,
      color: const Color(StoryPalette.paper),
      disabledColor: const Color(0xFF777777),
      icon: Icon(icon),
    );
  }
}

class _StyleControls extends StatelessWidget {
  const _StyleControls({required this.editor, required this.element});

  final StoryEditorController editor;
  final StoryElement? element;

  @override
  Widget build(BuildContext context) {
    const colors = [
      StoryPalette.paper,
      StoryPalette.ink,
      StoryPalette.coral,
      StoryPalette.cobalt,
      StoryPalette.teal,
      StoryPalette.yellow,
      StoryPalette.white,
    ];
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        const Text(
          'CANVAS',
          style: TextStyle(
            color: Color(StoryPalette.paper),
            fontWeight: FontWeight.w700,
          ),
        ),
        for (final color in colors)
          InkWell(
            key: ValueKey('canvas-color-$color'),
            onTap: () => editor.updateBackground(color),
            borderRadius: BorderRadius.circular(18),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Color(color),
            ),
          ),
        if (element != null) ...[
          const SizedBox(width: 8),
          DropdownButton<String>(
            key: const ValueKey('story-font'),
            value: element!.style.fontFamily,
            dropdownColor: const Color(StoryPalette.ink),
            style: const TextStyle(color: Color(StoryPalette.paper)),
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(
                value: 'Noto Sans',
                child: Text('Noto Sans'),
              ),
              DropdownMenuItem(
                value: 'Space Grotesk',
                child: Text('Space Grotesk'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                editor.updateSelectedFont(value);
              }
            },
          ),
        ],
      ],
    );
  }
}

class _PhotoCropControls extends StatelessWidget {
  const _PhotoCropControls({required this.editor, required this.element});

  final StoryEditorController editor;
  final StoryElement element;

  @override
  Widget build(BuildContext context) {
    final crop = element.photoCrop;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PHOTO CROP • FOCAL POSITION',
          style: TextStyle(
            color: Color(StoryPalette.paper),
            fontWeight: FontWeight.w700,
          ),
        ),
        _slider(
          key: 'photo-focal-x',
          label: 'Horizontal',
          value: crop.focalX,
          min: -1,
          max: 1,
          onChanged: (value) => editor.updatePhotoCrop(focalX: value),
        ),
        _slider(
          key: 'photo-focal-y',
          label: 'Vertical',
          value: crop.focalY,
          min: -1,
          max: 1,
          onChanged: (value) => editor.updatePhotoCrop(focalY: value),
        ),
        _slider(
          key: 'photo-zoom',
          label: 'Zoom',
          value: crop.zoom,
          min: 1,
          max: 4,
          onChanged: (value) => editor.updatePhotoCrop(zoom: value),
        ),
      ],
    );
  }

  Widget _slider({
    required String key,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(color: Color(StoryPalette.paper)),
          ),
        ),
        Expanded(
          child: Slider(
            key: ValueKey(key),
            value: value,
            min: min,
            max: max,
            activeColor: const Color(StoryPalette.yellow),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
