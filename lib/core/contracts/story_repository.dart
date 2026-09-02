import '../domain/story_project.dart';

abstract interface class StoryRepository {
  Future<void> save(StoryDocument document);

  Future<StoryDocument?> load(String documentId);

  Future<List<StoryDocument>> list();

  /// Removes every editable project derived from [runId].
  Future<void> deleteForRun(String runId);
}
