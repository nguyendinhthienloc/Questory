import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/domain/story_project.dart';

enum StoryGuideAxis { horizontal, vertical }

class StoryAlignmentGuide {
  const StoryAlignmentGuide(this.axis, this.position);

  final StoryGuideAxis axis;
  final double position;
}

class StoryEditorController extends ChangeNotifier {
  StoryEditorController(StoryDocument document) : _document = document;

  StoryDocument _document;
  String? _selectedElementId;
  final List<StoryDocument> _undoStack = [];
  final List<StoryDocument> _redoStack = [];
  List<StoryAlignmentGuide> _guides = const [];
  StoryDocument? _interactionStart;
  var _copySequence = 1;

  StoryDocument get document => _document;
  String? get selectedElementId => _selectedElementId;
  StoryElement? get selectedElement =>
      _document.elementById(_selectedElementId);
  List<StoryAlignmentGuide> get guides => List.unmodifiable(_guides);
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void select(String? elementId) {
    if (elementId != null && _document.elementById(elementId) == null) {
      return;
    }
    _selectedElementId = elementId;
    _guides = const [];
    notifyListeners();
  }

  void replaceDocument(StoryDocument document, {bool clearHistory = true}) {
    _document = document;
    _selectedElementId = null;
    _guides = const [];
    _interactionStart = null;
    if (clearHistory) {
      _undoStack.clear();
      _redoStack.clear();
    }
    notifyListeners();
  }

  void beginInteraction() {
    if (selectedElement == null || _interactionStart != null) {
      return;
    }
    _interactionStart = _document;
  }

  void updateInteraction({
    required double deltaX,
    required double deltaY,
    double scale = 1,
    double rotation = 0,
  }) {
    final element = selectedElement;
    if (element == null || element.locked) {
      return;
    }
    final transform = element.transform;
    final nextWidth =
        (transform.width * scale).clamp(80, _document.canvasWidth).toDouble();
    final nextHeight =
        (transform.height * scale).clamp(80, _document.canvasHeight).toDouble();
    final centeredX = transform.x - ((nextWidth - transform.width) / 2);
    final centeredY = transform.y - ((nextHeight - transform.height) / 2);
    final snapped = _snap(
      element,
      transform.copyWith(
        x: centeredX + deltaX,
        y: centeredY + deltaY,
        width: nextWidth,
        height: nextHeight,
        rotation: transform.rotation + rotation,
      ),
    );
    _document = _document.replaceElement(
      element.copyWith(transform: snapped.transform),
    );
    _guides = snapped.guides;
    notifyListeners();
  }

  void endInteraction() {
    final start = _interactionStart;
    _interactionStart = null;
    _guides = const [];
    if (start != null && !_sameDocument(start, _document)) {
      _undoStack.add(start);
      _redoStack.clear();
    }
    notifyListeners();
  }

  void moveSelected(double deltaX, double deltaY) {
    _commitElementTransform(
      (transform) => transform.copyWith(
        x: transform.x + deltaX,
        y: transform.y + deltaY,
      ),
      snap: true,
    );
  }

  void resizeSelected(double scale) {
    _commitElementTransform(
      (transform) {
        final width =
            (transform.width * scale).clamp(80, _document.canvasWidth);
        final height =
            (transform.height * scale).clamp(80, _document.canvasHeight);
        return transform.copyWith(
          x: transform.x - ((width - transform.width) / 2),
          y: transform.y - ((height - transform.height) / 2),
          width: width.toDouble(),
          height: height.toDouble(),
        );
      },
      snap: false,
    );
  }

  void rotateSelected(double radians) {
    _commitElementTransform(
      (transform) => transform.copyWith(
        rotation: transform.rotation + radians,
      ),
      snap: false,
    );
  }

  void duplicateSelected() {
    final selected = selectedElement;
    if (selected == null) {
      return;
    }
    final nextId = '${selected.id}-copy-${_copySequence++}';
    final transform = selected.transform;
    final duplicate = selected.copyWith(
      id: nextId,
      zIndex: _nextZIndex(),
      transform: transform.copyWith(
        x: (transform.x + 36)
            .clamp(0, _document.canvasWidth - transform.width)
            .toDouble(),
        y: (transform.y + 36)
            .clamp(0, _document.canvasHeight - transform.height)
            .toDouble(),
      ),
    );
    _commit(
      _document.copyWith(elements: [..._document.elements, duplicate]),
      selectedElementId: nextId,
    );
  }

  void deleteSelected() {
    final id = _selectedElementId;
    if (id == null) {
      return;
    }
    _commit(
      _document.removeElement(id),
      selectedElementId: null,
      replaceSelection: true,
    );
  }

  void bringForward() => _reorderSelected(1);
  void sendBackward() => _reorderSelected(-1);

  void updateSelectedContent(String content) {
    _updateSelected((element) => element.copyWith(content: content));
  }

  void updateSelectedFont(String fontFamily) {
    _updateSelected(
      (element) => element.copyWith(
        style: element.style.copyWith(fontFamily: fontFamily),
      ),
    );
  }

  void updateSelectedForeground(int color) {
    _updateSelected(
      (element) => element.copyWith(
        style: element.style.copyWith(foregroundColor: color),
      ),
    );
  }

  void updateBackground(int color) {
    _commit(_document.copyWith(backgroundColor: color));
  }

  void updatePhotoCrop({double? focalX, double? focalY, double? zoom}) {
    final element = selectedElement;
    if (element?.type != StoryElementType.photo) {
      return;
    }
    _updateSelected(
      (current) => current.copyWith(
        photoCrop: current.photoCrop.copyWith(
          focalX: focalX,
          focalY: focalY,
          zoom: zoom,
        ),
      ),
    );
  }

  void undo() {
    if (!canUndo) {
      return;
    }
    _redoStack.add(_document);
    _document = _undoStack.removeLast();
    if (_document.elementById(_selectedElementId) == null) {
      _selectedElementId = null;
    }
    _guides = const [];
    notifyListeners();
  }

  void redo() {
    if (!canRedo) {
      return;
    }
    _undoStack.add(_document);
    _document = _redoStack.removeLast();
    if (_document.elementById(_selectedElementId) == null) {
      _selectedElementId = null;
    }
    _guides = const [];
    notifyListeners();
  }

  void _commitElementTransform(
    StoryTransform Function(StoryTransform transform) transformUpdate, {
    required bool snap,
  }) {
    final element = selectedElement;
    if (element == null || element.locked) {
      return;
    }
    var transform = transformUpdate(element.transform);
    if (snap) {
      transform = _snap(element, transform).transform;
    } else {
      transform = _withinCanvas(transform);
    }
    _commit(_document.replaceElement(element.copyWith(transform: transform)));
  }

  void _updateSelected(StoryElement Function(StoryElement) update) {
    final element = selectedElement;
    if (element == null || element.locked) {
      return;
    }
    _commit(_document.replaceElement(update(element)));
  }

  void _reorderSelected(int direction) {
    final selected = selectedElement;
    if (selected == null) {
      return;
    }
    final ordered = _document.elementsInPaintOrder.toList();
    final currentIndex =
        ordered.indexWhere((element) => element.id == selected.id);
    final targetIndex = currentIndex + direction;
    if (targetIndex < 0 || targetIndex >= ordered.length) {
      return;
    }
    final normalized = <StoryElement>[
      for (var index = 0; index < ordered.length; index++)
        ordered[index].copyWith(zIndex: index),
    ];
    final currentNormalized = normalized[currentIndex];
    final targetNormalized = normalized[targetIndex];
    normalized[currentIndex] = currentNormalized.copyWith(
      zIndex: targetNormalized.zIndex,
    );
    normalized[targetIndex] = targetNormalized.copyWith(
      zIndex: currentNormalized.zIndex,
    );
    _commit(_document.copyWith(elements: normalized));
  }

  void _commit(
    StoryDocument next, {
    String? selectedElementId,
    bool replaceSelection = false,
  }) {
    if (_sameDocument(next, _document)) {
      return;
    }
    _undoStack.add(_document);
    _redoStack.clear();
    _document = next;
    if (replaceSelection || selectedElementId != null) {
      _selectedElementId = selectedElementId;
    }
    _guides = const [];
    notifyListeners();
  }

  int _nextZIndex() {
    if (_document.elements.isEmpty) {
      return 0;
    }
    return _document.elements
            .map((element) => element.zIndex)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  _SnapResult _snap(StoryElement selected, StoryTransform raw) {
    final transform = _withinCanvas(raw);
    final xTargets = <double>[
      0,
      _document.canvasWidth / 2,
      _document.canvasWidth,
    ];
    final yTargets = <double>[
      0,
      _document.canvasHeight / 2,
      _document.canvasHeight,
    ];
    for (final element in _document.elements) {
      if (element.id == selected.id) {
        continue;
      }
      final other = element.transform;
      xTargets.addAll([
        other.x,
        other.x + other.width / 2,
        other.x + other.width,
      ]);
      yTargets.addAll([
        other.y,
        other.y + other.height / 2,
        other.y + other.height,
      ]);
    }

    final xSnap = _nearestSnap(
      [
        transform.x,
        transform.x + transform.width / 2,
        transform.x + transform.width,
      ],
      xTargets,
    );
    final ySnap = _nearestSnap(
      [
        transform.y,
        transform.y + transform.height / 2,
        transform.y + transform.height,
      ],
      yTargets,
    );
    final guides = <StoryAlignmentGuide>[];
    if (xSnap != null) {
      guides.add(StoryAlignmentGuide(StoryGuideAxis.vertical, xSnap.target));
    }
    if (ySnap != null) {
      guides.add(StoryAlignmentGuide(StoryGuideAxis.horizontal, ySnap.target));
    }
    return _SnapResult(
      _withinCanvas(
        transform.copyWith(
          x: transform.x + (xSnap?.delta ?? 0),
          y: transform.y + (ySnap?.delta ?? 0),
        ),
      ),
      guides,
    );
  }

  StoryTransform _withinCanvas(StoryTransform transform) {
    final width = transform.width.clamp(80, _document.canvasWidth).toDouble();
    final height =
        transform.height.clamp(80, _document.canvasHeight).toDouble();
    return transform.copyWith(
      width: width,
      height: height,
      x: transform.x.clamp(0, _document.canvasWidth - width).toDouble(),
      y: transform.y.clamp(0, _document.canvasHeight - height).toDouble(),
    );
  }

  _AxisSnap? _nearestSnap(List<double> candidates, List<double> targets) {
    const tolerance = 12.0;
    _AxisSnap? best;
    for (final candidate in candidates) {
      for (final target in targets) {
        final delta = target - candidate;
        if (delta.abs() <= tolerance &&
            (best == null || delta.abs() < best.delta.abs())) {
          best = _AxisSnap(delta, target);
        }
      }
    }
    return best;
  }
}

class _SnapResult {
  const _SnapResult(this.transform, this.guides);

  final StoryTransform transform;
  final List<StoryAlignmentGuide> guides;
}

class _AxisSnap {
  const _AxisSnap(this.delta, this.target);

  final double delta;
  final double target;
}

bool _sameDocument(StoryDocument left, StoryDocument right) {
  return jsonEncode(left.toJson()) == jsonEncode(right.toJson());
}
