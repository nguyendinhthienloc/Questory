import 'package:flutter/material.dart';

import '../data/story_templates.dart';
import '../domain/story_document.dart';

class StoryStudioScreen extends StatefulWidget {
  const StoryStudioScreen({super.key});

  @override
  State<StoryStudioScreen> createState() => _StoryStudioScreenState();
}

class _StoryStudioScreenState extends State<StoryStudioScreen> {
  late StoryTemplate _template;
  late StoryDocument _document;
  String? _selectedElementId;

  @override
  void initState() {
    super.initState();
    _selectTemplate(storyTemplates.first, notify: false);
  }

  void _selectTemplate(StoryTemplate template, {bool notify = true}) {
    final nextDocument = template.createDocument(
      documentId: 'draft-${template.id}',
    );

    if (!notify) {
      _template = template;
      _document = nextDocument;
      return;
    }

    setState(() {
      _template = template;
      _document = nextDocument;
      _selectedElementId = null;
    });
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
          TextButton(
            onPressed: () {},
            child: const Text(
              'EXPORT',
              style: TextStyle(color: Color(StoryPalette.yellow)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 74,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: storyTemplates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final template = storyTemplates[index];
                  return ChoiceChip(
                    label: Text(template.name),
                    selected: template.id == _template.id,
                    onSelected: (_) => _selectTemplate(template),
                    selectedColor: const Color(StoryPalette.yellow),
                    backgroundColor: const Color(0xFF2C2C2C),
                    labelStyle: TextStyle(
                      color: template.id == _template.id
                          ? const Color(StoryPalette.ink)
                          : const Color(StoryPalette.paper),
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide.none,
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: StoryCanvas(
                  document: _document,
                  selectedElementId: _selectedElementId,
                  onElementTap: (element) {
                    setState(() => _selectedElementId = element.id);
                  },
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              color: const Color(0xFF232323),
              child: Text(
                _selectedElementId == null
                    ? _template.description
                    : 'Selected: $_selectedElementId',
                style: const TextStyle(
                  color: Color(StoryPalette.paper),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoryCanvas extends StatelessWidget {
  const StoryCanvas({
    super.key,
    required this.document,
    this.selectedElementId,
    this.onElementTap,
  });

  final StoryDocument document;
  final String? selectedElementId;
  final ValueChanged<StoryElement>? onElementTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: document.canvasWidth / document.canvasHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(document.backgroundColor),
            boxShadow: const [
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
              child: SizedBox(
                width: document.canvasWidth,
                height: document.canvasHeight,
                child: Stack(
                  children: [
                    for (final element in document.elementsInPaintOrder)
                      _StoryElementView(
                        element: element,
                        selected: element.id == selectedElementId,
                        onTap: onElementTap == null
                            ? null
                            : () => onElementTap!(element),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryElementView extends StatelessWidget {
  const _StoryElementView({
    required this.element,
    required this.selected,
    this.onTap,
  });

  final StoryElement element;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final transform = element.transform;

    return Positioned(
      left: transform.x,
      top: transform.y,
      width: transform.width,
      height: transform.height,
      child: Transform.rotate(
        angle: transform.rotation,
        child: GestureDetector(
          key: ValueKey(element.id),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: selected
                  ? Border.all(
                      color: const Color(StoryPalette.yellow),
                      width: 8,
                    )
                  : null,
            ),
            child: Opacity(
              opacity: element.style.opacity.clamp(0, 1).toDouble(),
              child: _content(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (element.type == StoryElementType.route) {
      return CustomPaint(
        painter: _RoutePainter(
          lineColor: Color(element.style.foregroundColor),
        ),
        child: _box(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(element.content, style: _textStyle(28)),
            ),
          ),
        ),
      );
    }

    if (element.type == StoryElementType.photo) {
      return _box(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 96,
              color: Color(element.style.foregroundColor),
            ),
            const SizedBox(height: 20),
            Text(element.content, style: _textStyle()),
          ],
        ),
      );
    }

    final icon = switch (element.type) {
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
                size: element.style.fontSize,
                color: Color(element.style.foregroundColor),
              ),
              const SizedBox(width: 16),
            ],
            Flexible(
              child: Text(
                element.content,
                textAlign: _textAlign(element.style.textAlign),
                style: _textStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: element.style.backgroundColor == null
            ? null
            : Color(element.style.backgroundColor!),
        borderRadius: BorderRadius.circular(element.style.borderRadius),
      ),
      child: child,
    );
  }

  TextStyle _textStyle([double? fontSize]) {
    return TextStyle(
      color: Color(element.style.foregroundColor),
      fontSize: fontSize ?? element.style.fontSize,
      fontWeight: _fontWeight(element.style.fontWeight),
      height: 1.15,
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.77)
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.45,
        size.width * 0.52,
        size.height * 0.62,
        size.width * 0.45,
        size.height * 0.30,
      )
      ..cubicTo(
        size.width * 0.40,
        size.height * 0.08,
        size.width * 0.88,
        size.height * 0.18,
        size.width * 0.80,
        size.height * 0.55,
      );

    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.77),
      22,
      Paint()..color = lineColor,
    );
    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.55),
      22,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.55),
      22,
      Paint()
        ..color = lineColor
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
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
