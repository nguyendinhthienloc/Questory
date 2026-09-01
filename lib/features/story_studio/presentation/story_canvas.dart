import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/domain/story_project.dart';
import '../application/story_editor_controller.dart';
import '../data/story_templates.dart';

class StoryCanvas extends StatelessWidget {
  const StoryCanvas({
    super.key,
    required this.document,
    required this.boundaryKey,
    this.selectedElementId,
    this.guides = const [],
    this.showEditorChrome = true,
    this.onElementTap,
    this.onInteractionStart,
    this.onInteractionUpdate,
    this.onInteractionEnd,
  });

  final StoryDocument document;
  final GlobalKey boundaryKey;
  final String? selectedElementId;
  final List<StoryAlignmentGuide> guides;
  final bool showEditorChrome;
  final ValueChanged<StoryElement>? onElementTap;
  final VoidCallback? onInteractionStart;
  final void Function(double dx, double dy, double scale, double rotation)?
      onInteractionUpdate;
  final VoidCallback? onInteractionEnd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: document.canvasWidth / document.canvasHeight,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.fill,
              child: RepaintBoundary(
                key: boundaryKey,
                child: SizedBox(
                  width: document.canvasWidth,
                  height: document.canvasHeight,
                  child: ColoredBox(
                    color: Color(document.backgroundColor),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final element in document.elementsInPaintOrder)
                          _StoryElementView(
                            element: element,
                            selected: showEditorChrome &&
                                element.id == selectedElementId,
                            interactive: showEditorChrome,
                            onTap: onElementTap == null
                                ? null
                                : () => onElementTap!(element),
                            onInteractionStart: onInteractionStart,
                            onInteractionUpdate: onInteractionUpdate,
                            onInteractionEnd: onInteractionEnd,
                          ),
                        if (showEditorChrome)
                          for (final guide in guides) _GuideView(guide: guide),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryElementView extends StatefulWidget {
  const _StoryElementView({
    required this.element,
    required this.selected,
    required this.interactive,
    this.onTap,
    this.onInteractionStart,
    this.onInteractionUpdate,
    this.onInteractionEnd,
  });

  final StoryElement element;
  final bool selected;
  final bool interactive;
  final VoidCallback? onTap;
  final VoidCallback? onInteractionStart;
  final void Function(double dx, double dy, double scale, double rotation)?
      onInteractionUpdate;
  final VoidCallback? onInteractionEnd;

  @override
  State<_StoryElementView> createState() => _StoryElementViewState();
}

class _StoryElementViewState extends State<_StoryElementView> {
  var _lastScale = 1.0;
  var _lastRotation = 0.0;

  @override
  Widget build(BuildContext context) {
    final transform = widget.element.transform;
    return Positioned(
      left: transform.x,
      top: transform.y,
      width: transform.width,
      height: transform.height,
      child: Transform.rotate(
        angle: transform.rotation,
        child: GestureDetector(
          key: ValueKey(widget.element.id),
          behavior: HitTestBehavior.opaque,
          onTap: widget.interactive ? widget.onTap : null,
          onScaleStart: widget.interactive
              ? (_) {
                  _lastScale = 1;
                  _lastRotation = 0;
                  widget.onTap?.call();
                  widget.onInteractionStart?.call();
                }
              : null,
          onScaleUpdate: widget.interactive
              ? (details) {
                  final scaleDelta = details.scale / _lastScale;
                  final rotationDelta = details.rotation - _lastRotation;
                  _lastScale = details.scale;
                  _lastRotation = details.rotation;
                  widget.onInteractionUpdate?.call(
                    details.focalPointDelta.dx,
                    details.focalPointDelta.dy,
                    scaleDelta,
                    rotationDelta,
                  );
                }
              : null,
          onScaleEnd: widget.interactive
              ? (_) => widget.onInteractionEnd?.call()
              : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: widget.selected
                  ? Border.all(
                      color: const Color(StoryPalette.yellow),
                      width: 8,
                    )
                  : null,
            ),
            child: Opacity(
              opacity: widget.element.style.opacity.clamp(0, 1).toDouble(),
              child: _content(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (widget.element.type == StoryElementType.route) {
      return CustomPaint(
        painter: _RoutePainter(
          lineColor: Color(widget.element.style.foregroundColor),
          points: widget.element.routePoints,
        ),
        child: _box(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(widget.element.content, style: _textStyle(28)),
            ),
          ),
        ),
      );
    }
    if (widget.element.type == StoryElementType.photo) {
      return _photo();
    }

    final icon = switch (widget.element.type) {
      StoryElementType.locationStamp => Icons.location_on_outlined,
      StoryElementType.questList => Icons.checklist_rounded,
      StoryElementType.statistic => Icons.directions_run_rounded,
      StoryElementType.sticker => Icons.local_offer_outlined,
      _ => null,
    };
    return _box(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: widget.element.style.fontSize,
                color: Color(widget.element.style.foregroundColor),
              ),
              const SizedBox(width: 16),
            ],
            Flexible(
              child: Text(
                widget.element.content,
                textAlign: _textAlign(widget.element.style.textAlign),
                style: _textStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photo() {
    final path = widget.element.assetPath;
    Widget image = _photoPlaceholder();
    if (path != null && !path.startsWith('fixture://')) {
      image = Image.file(
        File(path),
        fit: BoxFit.cover,
        alignment: Alignment(
          widget.element.photoCrop.focalX,
          widget.element.photoCrop.focalY,
        ),
        errorBuilder: (_, __, ___) => _photoPlaceholder(),
      );
    }
    return _box(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.element.style.borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: widget.element.photoCrop.zoom,
              alignment: Alignment(
                widget.element.photoCrop.focalX,
                widget.element.photoCrop.focalY,
              ),
              child: image,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ColoredBox(
                color: const Color(0xB3171717),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    widget.element.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: _textStyle(30).copyWith(
                      color: const Color(StoryPalette.paper),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return ColoredBox(
      color: Color(
        widget.element.style.backgroundColor ?? StoryPalette.ink,
      ),
      child: Center(
        child: Icon(
          Icons.photo_camera_outlined,
          size: 96,
          color: Color(widget.element.style.foregroundColor),
        ),
      ),
    );
  }

  Widget _box({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.element.style.backgroundColor == null
            ? null
            : Color(widget.element.style.backgroundColor!),
        borderRadius: BorderRadius.circular(widget.element.style.borderRadius),
      ),
      child: child,
    );
  }

  TextStyle _textStyle([double? fontSize]) {
    return TextStyle(
      color: Color(widget.element.style.foregroundColor),
      fontSize: fontSize ?? widget.element.style.fontSize,
      fontWeight: _fontWeight(widget.element.style.fontWeight),
      fontFamily: widget.element.style.fontFamily,
      height: 1.15,
    );
  }
}

class _GuideView extends StatelessWidget {
  const _GuideView({required this.guide});

  final StoryAlignmentGuide guide;

  @override
  Widget build(BuildContext context) {
    const color = Color(StoryPalette.coral);
    if (guide.axis == StoryGuideAxis.vertical) {
      return Positioned(
        left: guide.position - 2,
        top: 0,
        bottom: 0,
        width: 4,
        child: const ColoredBox(color: color),
      );
    }
    return Positioned(
      left: 0,
      right: 0,
      top: guide.position - 2,
      height: 4,
      child: const ColoredBox(color: color),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.lineColor, required this.points});

  final Color lineColor;
  final List<StoryCanvasPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final resolvedPoints = points.length < 2
        ? const [
            StoryCanvasPoint(0.08, 0.82),
            StoryCanvasPoint(0.32, 0.38),
            StoryCanvasPoint(0.52, 0.62),
            StoryCanvasPoint(0.83, 0.22),
          ]
        : points;
    Offset mapPoint(StoryCanvasPoint point) {
      const padding = 0.12;
      return Offset(
        size.width * (padding + point.x * (1 - padding * 2)),
        size.height * (padding + point.y * (1 - padding * 2)),
      );
    }

    final path = Path();
    for (var index = 0; index < resolvedPoints.length; index++) {
      final point = mapPoint(resolvedPoints[index]);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, paint);
    final start = mapPoint(resolvedPoints.first);
    final end = mapPoint(resolvedPoints.last);
    canvas.drawCircle(start, 22, Paint()..color = lineColor);
    canvas.drawCircle(end, 22, Paint()..color = Colors.white);
    canvas.drawCircle(
      end,
      22,
      Paint()
        ..color = lineColor
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor || oldDelegate.points != points;
  }
}

FontWeight _fontWeight(int value) {
  final index = ((value ~/ 100) - 1).clamp(0, 8).toInt();
  return FontWeight.values[index];
}

TextAlign _textAlign(String value) {
  return switch (value) {
    'center' => TextAlign.center,
    'right' => TextAlign.right,
    'justify' => TextAlign.justify,
    _ => TextAlign.left,
  };
}
