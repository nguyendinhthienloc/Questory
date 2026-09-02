import 'dart:async';

import '../contracts/achievement_repository.dart';
import '../contracts/clock.dart';
import '../contracts/location_tracker.dart';
import '../contracts/photo_store.dart';
import '../contracts/run_repository.dart';
import '../domain/achievement.dart';
import '../domain/run_session.dart';
import '../domain/run_models.dart';

class FakeClock implements Clock {
  FakeClock(this.value);

  DateTime value;

  void advance(Duration duration) => value = value.add(duration);

  @override
  DateTime nowUtc() => value.toUtc();
}

class FakeLocationTracker implements LocationTracker {
  FakeLocationTracker({
    this.serviceEnabled = true,
    this.permission = LocationPermissionStatus.granted,
  });

  bool serviceEnabled;
  LocationPermissionStatus permission;
  final StreamController<GeoPoint> _controller = StreamController.broadcast();

  void emit(GeoPoint point) => _controller.add(point);

  Future<void> close() => _controller.close();

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermissionStatus> requestPermission() async => permission;

  @override
  Stream<GeoPoint> watch() => _controller.stream;
}

class FakeRunRepository implements RunRepository {
  RunSession? active;
  final Map<String, RunSummary> summaries = {};

  @override
  Future<void> clearActive() async => active = null;

  @override
  Future<void> deleteSummary(String id) async => summaries.remove(id);

  @override
  Future<RunSummary?> getSummary(String id) async => summaries[id];

  @override
  Future<List<RunSummary>> listSummaries() async {
    final values = summaries.values.toList()
      ..sort((a, b) => b.startedAtUtc.compareTo(a.startedAtUtc));
    return List.unmodifiable(values);
  }

  @override
  Future<RunSession?> loadActive() async => active;

  @override
  Future<void> saveActive(RunSession session) async => active = session;

  @override
  Future<void> saveSummary(RunSummary summary) async =>
      summaries[summary.id] = summary;
}

class FakePhotoStore implements PhotoStore {
  final Set<String> paths = {};

  @override
  Future<void> delete(String path) async => paths.remove(path);

  @override
  Future<bool> exists(String path) async => paths.contains(path);

  @override
  Future<String> retain({
    required String temporaryPath,
    required String evidenceId,
  }) async {
    final path = '/app/photos/$evidenceId.jpg';
    paths.add(path);
    return path;
  }
}

class FakeAchievementRepository implements AchievementRepository {
  List<Achievement> achievements = [];

  @override
  Future<List<Achievement>> list() async => List.unmodifiable(achievements);

  @override
  Future<void> saveAll(List<Achievement> achievements) async =>
      this.achievements = List.of(achievements);
}
