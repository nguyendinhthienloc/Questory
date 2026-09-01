import '../domain/story_document.dart';

class StoryTemplate {
  const StoryTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.document,
  });

  final String id;
  final String name;
  final String description;
  final StoryDocument document;

  StoryDocument createDocument({
    required String documentId,
    String? sourceRunId,
  }) {
    return document.copyWith(
      id: documentId,
      sourceRunId: sourceRunId,
      elements: [
        for (final element in document.elements)
          element.copyWith(id: '$documentId-${element.id}'),
      ],
    );
  }
}

abstract final class StoryPalette {
  static const int paper = 0xFFF7F1E3;
  static const int ink = 0xFF171717;
  static const int coral = 0xFFFF6B5E;
  static const int cobalt = 0xFF3157C8;
  static const int teal = 0xFF0B7A75;
  static const int yellow = 0xFFFFD447;
  static const int white = 0xFFFFFFFF;
}

final List<StoryTemplate> storyTemplates = List.unmodifiable([
  StoryTemplate(
    id: 'city-sprint',
    name: 'City Sprint',
    description: 'Bold route-first recap with one hero photograph.',
    document: _citySprint(),
  ),
  StoryTemplate(
    id: 'film-roll',
    name: 'Film Roll',
    description: 'A playful photo strip for quest-heavy runs.',
    document: _filmRoll(),
  ),
  StoryTemplate(
    id: 'postcard-trail',
    name: 'Postcard Trail',
    description: 'A calm postcard balancing place and performance.',
    document: _postcardTrail(),
  ),
]);

StoryTemplate storyTemplateById(String templateId) {
  return storyTemplates.firstWhere(
    (template) => template.id == templateId,
    orElse: () => throw ArgumentError.value(
      templateId,
      'templateId',
      'Unknown story template',
    ),
  );
}

StoryDocument _citySprint() {
  return StoryDocument(
    id: 'template-city-sprint',
    title: 'City Sprint',
    backgroundColor: StoryPalette.paper,
    elements: [
      _element(
        'label',
        StoryElementType.sticker,
        70,
        70,
        360,
        86,
        1,
        'QUESTORY / RUN 01',
        foreground: StoryPalette.white,
        background: StoryPalette.cobalt,
        fontSize: 34,
        rotation: -0.03,
      ),
      _element(
        'title',
        StoryElementType.text,
        70,
        185,
        940,
        150,
        2,
        'NHA TRANG\nMORNING RUN',
        fontSize: 76,
      ),
      _element(
        'hero-photo',
        StoryElementType.photo,
        70,
        375,
        620,
        720,
        1,
        'HERO PHOTO',
        foreground: StoryPalette.paper,
        background: StoryPalette.ink,
        rotation: -0.015,
      ),
      _element(
        'location',
        StoryElementType.locationStamp,
        730,
        380,
        280,
        110,
        3,
        'NHA TRANG, VN',
        background: StoryPalette.yellow,
        fontSize: 30,
      ),
      _element(
        'route',
        StoryElementType.route,
        730,
        530,
        280,
        410,
        2,
        'RECORDED ROUTE',
        foreground: StoryPalette.coral,
        background: StoryPalette.white,
      ),
      _element(
        'stats',
        StoryElementType.statistic,
        730,
        980,
        280,
        280,
        2,
        '5.42 KM\n31:09\n6:12 /KM',
        foreground: StoryPalette.white,
        background: StoryPalette.teal,
        fontSize: 38,
      ),
      _element(
        'quests',
        StoryElementType.questList,
        70,
        1160,
        620,
        420,
        2,
        'PHOTO QUESTS\n✓ Sunrise by the sea\n✓ Local breakfast\n✓ Hidden architecture',
        background: StoryPalette.white,
        fontSize: 38,
      ),
      _element(
        'caption',
        StoryElementType.text,
        70,
        1640,
        940,
        160,
        2,
        'A city is best remembered one stride at a time.',
        foreground: StoryPalette.cobalt,
        fontSize: 45,
      ),
    ],
  );
}

StoryDocument _filmRoll() {
  return StoryDocument(
    id: 'template-film-roll',
    title: 'Film Roll',
    backgroundColor: StoryPalette.yellow,
    elements: [
      _element(
        'header',
        StoryElementType.text,
        70,
        70,
        940,
        120,
        2,
        'THE CITY, ON FILM',
        fontSize: 70,
      ),
      _element(
        'photo-one',
        StoryElementType.photo,
        80,
        240,
        580,
        430,
        2,
        'QUEST PHOTO 01',
        foreground: StoryPalette.white,
        background: StoryPalette.ink,
        rotation: -0.035,
      ),
      _element(
        'photo-two',
        StoryElementType.photo,
        420,
        700,
        580,
        430,
        3,
        'QUEST PHOTO 02',
        foreground: StoryPalette.white,
        background: StoryPalette.cobalt,
        rotation: 0.03,
      ),
      _element(
        'photo-three',
        StoryElementType.photo,
        80,
        1160,
        580,
        430,
        2,
        'QUEST PHOTO 03',
        foreground: StoryPalette.white,
        background: StoryPalette.teal,
        rotation: -0.02,
      ),
      _element(
        'route',
        StoryElementType.route,
        700,
        250,
        300,
        390,
        1,
        'CITY ROUTE',
        foreground: StoryPalette.coral,
        background: StoryPalette.paper,
      ),
      _element(
        'stats',
        StoryElementType.statistic,
        80,
        730,
        290,
        300,
        2,
        '7.10 KM\n44:18\n6:14 /KM',
        foreground: StoryPalette.white,
        background: StoryPalette.coral,
        fontSize: 42,
      ),
      _element(
        'quests',
        StoryElementType.questList,
        700,
        1190,
        300,
        350,
        2,
        '3/3 QUESTS\n✓ LANDMARK\n✓ STREET DETAIL\n✓ LOCAL FLAVOR',
        foreground: StoryPalette.paper,
        background: StoryPalette.ink,
        fontSize: 30,
      ),
      _element(
        'date',
        StoryElementType.sticker,
        680,
        1630,
        330,
        100,
        4,
        'SEP 01 / 2026',
        foreground: StoryPalette.white,
        background: StoryPalette.cobalt,
        fontSize: 34,
        rotation: -0.04,
      ),
      _element(
        'location',
        StoryElementType.locationStamp,
        80,
        1680,
        500,
        100,
        3,
        'HO CHI MINH CITY, VN',
        background: StoryPalette.paper,
        fontSize: 30,
      ),
    ],
  );
}

StoryDocument _postcardTrail() {
  return StoryDocument(
    id: 'template-postcard-trail',
    title: 'Postcard Trail',
    backgroundColor: StoryPalette.teal,
    elements: [
      _element(
        'postcard',
        StoryElementType.sticker,
        70,
        70,
        300,
        88,
        4,
        'POSTCARD 001',
        background: StoryPalette.yellow,
        fontSize: 32,
        rotation: -0.025,
      ),
      _element(
        'title',
        StoryElementType.text,
        70,
        200,
        940,
        190,
        2,
        'HELLO FROM\nTHE RUNNING TRAIL',
        foreground: StoryPalette.paper,
        fontSize: 72,
      ),
      _element(
        'hero',
        StoryElementType.photo,
        70,
        430,
        940,
        600,
        1,
        'TRAVEL PHOTO',
        background: StoryPalette.paper,
        fontSize: 44,
        rotation: 0.01,
      ),
      _element(
        'route',
        StoryElementType.route,
        70,
        1080,
        500,
        420,
        2,
        'TRAIL MAP',
        foreground: StoryPalette.coral,
        background: StoryPalette.paper,
      ),
      _element(
        'stats',
        StoryElementType.statistic,
        610,
        1080,
        400,
        220,
        2,
        '4.86 KM • 31:09\nAVG PACE 6:24 /KM',
        background: StoryPalette.yellow,
        fontSize: 36,
      ),
      _element(
        'location',
        StoryElementType.locationStamp,
        610,
        1340,
        400,
        100,
        3,
        'NHA TRANG, VN',
        foreground: StoryPalette.paper,
        background: StoryPalette.coral,
        fontSize: 32,
      ),
      _element(
        'quests',
        StoryElementType.questList,
        610,
        1480,
        400,
        240,
        2,
        'TODAY\n✓ COASTLINE\n✓ LOCAL DETAIL\n✓ FAVORITE VIEW',
        background: StoryPalette.paper,
        fontSize: 30,
      ),
      _element(
        'caption',
        StoryElementType.text,
        70,
        1760,
        940,
        90,
        2,
        'WISH YOU RAN HERE.',
        foreground: StoryPalette.yellow,
        fontSize: 52,
      ),
    ],
  );
}

StoryElement _element(
  String id,
  StoryElementType type,
  double x,
  double y,
  double width,
  double height,
  int zIndex,
  String content, {
  int foreground = StoryPalette.ink,
  int? background,
  double fontSize = 40,
  double rotation = 0,
}) {
  return StoryElement(
    id: id,
    type: type,
    transform: StoryTransform(
      x: x,
      y: y,
      width: width,
      height: height,
      rotation: rotation,
    ),
    zIndex: zIndex,
    content: content,
    style: StoryElementStyle(
      foregroundColor: foreground,
      backgroundColor: background,
      fontSize: fontSize,
      fontWeight: 700,
      textAlign: 'center',
      borderRadius: 22,
    ),
  );
}
