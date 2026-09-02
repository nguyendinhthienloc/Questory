import '../domain/run_session.dart';
import '../domain/run_models.dart';

abstract interface class RunRepository {
  Future<void> saveActive(RunSession session);

  Future<RunSession?> loadActive();

  Future<void> clearActive();

  Future<void> saveSummary(RunSummary summary);

  Future<RunSummary?> getSummary(String id);

  Future<List<RunSummary>> listSummaries();

  Future<void> deleteSummary(String id);
}
