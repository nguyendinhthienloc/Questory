import '../domain/run_models.dart';
import '../domain/shared_run.dart';

abstract interface class LiveShareService {
  Future<ShareLink> createShare(
    RunSummary summary, {
    Duration expiresIn = const Duration(hours: 24),
  });

  Future<void> uploadEvidence({
    required ShareLink share,
    required QuestEvidence evidence,
  });

  Future<SharedRunPreview> loadSharedRun({
    required String shareId,
    required String token,
  });

  Future<void> revokeShare({required String shareId, required String token});
}
