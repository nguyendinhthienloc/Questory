import '../domain/story_project.dart';

class StoryExport {
  const StoryExport({
    required this.path,
    required this.width,
    required this.height,
  });

  final String path;
  final int width;
  final int height;
}

abstract interface class StoryRenderer {
  Future<StoryExport> renderPng(StoryDocument document);
}
