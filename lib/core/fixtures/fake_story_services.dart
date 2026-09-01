import '../contracts/share_service.dart';
import '../contracts/story_renderer.dart';
import '../contracts/story_repository.dart';
import '../domain/story_project.dart';

class FakeStoryRepository implements StoryRepository {
  FakeStoryRepository({Iterable<StoryDocument> seed = const []})
      : _documents = {
          for (final document in seed)
            document.id: StoryDocument.fromJson(document.toJson()),
        };

  final Map<String, StoryDocument> _documents;

  @override
  Future<StoryDocument?> load(String documentId) async {
    final document = _documents[documentId];
    return document == null ? null : StoryDocument.fromJson(document.toJson());
  }

  @override
  Future<List<StoryDocument>> list() async {
    final documents = _documents.values
        .map((document) => StoryDocument.fromJson(document.toJson()))
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    return List.unmodifiable(documents);
  }

  @override
  Future<void> save(StoryDocument document) async {
    _documents[document.id] = StoryDocument.fromJson(document.toJson());
  }
}

class FakeStoryRenderer implements StoryRenderer {
  FakeStoryRenderer({
    this.path = 'memory://questory-story.png',
    this.failure,
  });

  final String path;
  final Object? failure;
  StoryDocument? lastDocument;

  @override
  Future<StoryExport> renderPng(StoryDocument document) async {
    if (failure != null) {
      throw failure!;
    }
    lastDocument = StoryDocument.fromJson(document.toJson());
    return StoryExport(
      path: path,
      width: storyCanvasWidth.toInt(),
      height: storyCanvasHeight.toInt(),
    );
  }
}

class FakeShareService implements ShareService {
  FakeShareService({this.failure});

  final Object? failure;
  String? sharedPath;
  String? sharedTitle;

  @override
  Future<void> sharePng({required String path, required String title}) async {
    if (failure != null) {
      throw failure!;
    }
    sharedPath = path;
    sharedTitle = title;
  }
}
