const double storyCanvasWidth = 1080;
const double storyCanvasHeight = 1920;

enum StoryElementType {
  photo,
  text,
  route,
  statistic,
  questList,
  sticker,
  locationStamp,
}

class StoryTransform {
  const StoryTransform({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  StoryTransform copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
  }) {
    return StoryTransform(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, Object> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
      };

  factory StoryTransform.fromJson(Map<String, Object?> json) {
    return StoryTransform(
      x: _readDouble(json, 'x'),
      y: _readDouble(json, 'y'),
      width: _readDouble(json, 'width'),
      height: _readDouble(json, 'height'),
      rotation: _readDouble(json, 'rotation', fallback: 0),
    );
  }
}

class StoryElementStyle {
  const StoryElementStyle({
    this.foregroundColor = 0xFF171717,
    this.backgroundColor,
    this.opacity = 1,
    this.fontSize = 48,
    this.fontWeight = 500,
    this.fontFamily = 'sans-serif',
    this.textAlign = 'left',
    this.borderRadius = 0,
  });

  final int foregroundColor;
  final int? backgroundColor;
  final double opacity;
  final double fontSize;
  final int fontWeight;
  final String fontFamily;
  final String textAlign;
  final double borderRadius;

  Map<String, Object?> toJson() => {
        'foregroundColor': foregroundColor,
        'backgroundColor': backgroundColor,
        'opacity': opacity,
        'fontSize': fontSize,
        'fontWeight': fontWeight,
        'fontFamily': fontFamily,
        'textAlign': textAlign,
        'borderRadius': borderRadius,
      };

  factory StoryElementStyle.fromJson(Map<String, Object?> json) {
    return StoryElementStyle(
      foregroundColor: _readInt(json, 'foregroundColor', fallback: 0xFF171717),
      backgroundColor: json['backgroundColor'] == null
          ? null
          : _readInt(json, 'backgroundColor'),
      opacity: _readDouble(json, 'opacity', fallback: 1),
      fontSize: _readDouble(json, 'fontSize', fallback: 48),
      fontWeight: _readInt(json, 'fontWeight', fallback: 500),
      fontFamily: json['fontFamily'] as String? ?? 'sans-serif',
      textAlign: json['textAlign'] as String? ?? 'left',
      borderRadius: _readDouble(json, 'borderRadius', fallback: 0),
    );
  }
}

class StoryElement {
  const StoryElement({
    required this.id,
    required this.type,
    required this.transform,
    required this.zIndex,
    this.content = '',
    this.assetPath,
    this.style = const StoryElementStyle(),
    this.locked = false,
  });

  final String id;
  final StoryElementType type;
  final StoryTransform transform;
  final int zIndex;
  final String content;
  final String? assetPath;
  final StoryElementStyle style;
  final bool locked;

  StoryElement copyWith({
    String? id,
    StoryElementType? type,
    StoryTransform? transform,
    int? zIndex,
    String? content,
    String? assetPath,
    StoryElementStyle? style,
    bool? locked,
  }) {
    return StoryElement(
      id: id ?? this.id,
      type: type ?? this.type,
      transform: transform ?? this.transform,
      zIndex: zIndex ?? this.zIndex,
      content: content ?? this.content,
      assetPath: assetPath ?? this.assetPath,
      style: style ?? this.style,
      locked: locked ?? this.locked,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'transform': transform.toJson(),
        'zIndex': zIndex,
        'content': content,
        'assetPath': assetPath,
        'style': style.toJson(),
        'locked': locked,
      };

  factory StoryElement.fromJson(Map<String, Object?> json) {
    final typeName = json['type'] as String? ?? '';
    return StoryElement(
      id: _readString(json, 'id'),
      type: StoryElementType.values.firstWhere(
        (type) => type.name == typeName,
        orElse: () => throw FormatException(
          'Unsupported story element type: $typeName',
        ),
      ),
      transform: StoryTransform.fromJson(
        _readMap(json, 'transform'),
      ),
      zIndex: _readInt(json, 'zIndex'),
      content: json['content'] as String? ?? '',
      assetPath: json['assetPath'] as String?,
      style: StoryElementStyle.fromJson(_readMap(json, 'style')),
      locked: json['locked'] as bool? ?? false,
    );
  }
}

class StoryDocument {
  const StoryDocument({
    required this.id,
    required this.title,
    required this.backgroundColor,
    required this.elements,
    this.canvasWidth = storyCanvasWidth,
    this.canvasHeight = storyCanvasHeight,
    this.sourceRunId,
    this.schemaVersion = 1,
  });

  final String id;
  final String title;
  final int backgroundColor;
  final List<StoryElement> elements;
  final double canvasWidth;
  final double canvasHeight;
  final String? sourceRunId;
  final int schemaVersion;

  List<StoryElement> get elementsInPaintOrder {
    final sorted = List<StoryElement>.of(elements);
    sorted.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return List.unmodifiable(sorted);
  }

  StoryDocument replaceElement(StoryElement updated) {
    return copyWith(
      elements: [
        for (final element in elements)
          if (element.id == updated.id) updated else element,
      ],
    );
  }

  StoryDocument removeElement(String elementId) {
    return copyWith(
      elements: elements.where((element) => element.id != elementId).toList(),
    );
  }

  StoryDocument copyWith({
    String? id,
    String? title,
    int? backgroundColor,
    List<StoryElement>? elements,
    double? canvasWidth,
    double? canvasHeight,
    String? sourceRunId,
    int? schemaVersion,
  }) {
    return StoryDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elements: List.unmodifiable(elements ?? this.elements),
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      sourceRunId: sourceRunId ?? this.sourceRunId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'title': title,
        'canvasWidth': canvasWidth,
        'canvasHeight': canvasHeight,
        'backgroundColor': backgroundColor,
        'sourceRunId': sourceRunId,
        'elements': elements.map((element) => element.toJson()).toList(),
      };

  factory StoryDocument.fromJson(Map<String, Object?> json) {
    final rawElements = json['elements'];
    if (rawElements is! List) {
      throw const FormatException('Story document elements must be a list.');
    }

    return StoryDocument(
      schemaVersion: _readInt(json, 'schemaVersion', fallback: 1),
      id: _readString(json, 'id'),
      title: _readString(json, 'title'),
      canvasWidth: _readDouble(json, 'canvasWidth', fallback: storyCanvasWidth),
      canvasHeight:
          _readDouble(json, 'canvasHeight', fallback: storyCanvasHeight),
      backgroundColor: _readInt(json, 'backgroundColor'),
      sourceRunId: json['sourceRunId'] as String?,
      elements: List.unmodifiable(
        rawElements.map(
          (element) => StoryElement.fromJson(
            Map<String, Object?>.from(element as Map),
          ),
        ),
      ),
    );
  }
}

Map<String, Object?> _readMap(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value is! Map) {
    throw FormatException('$key must be a JSON object.');
  }
  return Map<String, Object?>.from(value);
}

String _readString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

double _readDouble(
  Map<String, Object?> json,
  String key, {
  double? fallback,
}) {
  final value = json[key];
  if (value == null && fallback != null) {
    return fallback;
  }
  if (value is! num) {
    throw FormatException('$key must be a number.');
  }
  return value.toDouble();
}

int _readInt(
  Map<String, Object?> json,
  String key, {
  int? fallback,
}) {
  final value = json[key];
  if (value == null && fallback != null) {
    return fallback;
  }
  if (value is! num) {
    throw FormatException('$key must be a number.');
  }
  return value.toInt();
}
