import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/contracts/clock.dart';
import '../../../core/contracts/location_tracker.dart';
import '../../../core/contracts/run_repository.dart';
import '../../../core/domain/destination_models.dart';
import '../../../core/domain/run_session.dart';
import '../../../core/domain/run_models.dart';
import 'run_calculations.dart';

class RunTrackerController extends ChangeNotifier {
  RunTrackerController({
    required this.pack,
    required this.route,
    required RunRepository repository,
    required LocationTracker locationTracker,
    required Clock clock,
  })  : _repository = repository,
        _locationTracker = locationTracker,
        _clock = clock;

  final DestinationPack pack;
  final RoutePlan? route;
  final RunRepository _repository;
  final LocationTracker _locationTracker;
  final Clock _clock;

  RunSession? _session;
  StreamSubscription<GeoPoint>? _positionSubscription;
  Timer? _ticker;
  RunSummary? _summary;

  RunSession? get session => _session;
  RunSummary? get summary => _summary;
  RunLifecycle get lifecycle => _session?.lifecycle ?? RunLifecycle.idle;
  List<GeoPoint> get track => _session?.track ?? const [];
  GeoPoint? get currentPoint => track.isEmpty ? null : track.last;
  Duration get activeDuration =>
      _session?.activeDurationAt(_clock.nowUtc()) ?? Duration.zero;
  double get distanceMeters => RunCalculations.distanceMeters(track);
  double? get paceSecondsPerKilometer =>
      RunCalculations.paceSecondsPerKilometer(
        distanceMeters: distanceMeters,
        activeDuration: activeDuration,
      );

  List<Quest> get availableQuests {
    final ids = route?.questIds ??
        pack.pointsOfInterest.expand((item) => item.questIds).toSet().toList();
    return [
      for (final id in ids)
        if (pack.questById(id) case final quest?) quest,
    ];
  }

  Future<void> start() async {
    if (lifecycle != RunLifecycle.idle && lifecycle != RunLifecycle.failed) {
      return;
    }
    final now = _clock.nowUtc();
    _session = RunSession(
      id: 'run-${now.microsecondsSinceEpoch}',
      cityId: pack.id,
      locationName: '${pack.cityName}, Vietnam',
      routeId: route?.id,
      startedAtUtc: now,
      updatedAtUtc: now,
      lifecycle: RunLifecycle.acquiring,
      accumulatedActiveDuration: Duration.zero,
      track: const [],
      evidence: const [],
      completedQuestIds: const {},
      skippedQuestIds: const {},
    );
    notifyListeners();
    if (!await _locationTracker.isServiceEnabled()) {
      return _fail('Location services are disabled. Turn on GPS and retry.');
    }
    final permission = await _locationTracker.requestPermission();
    if (permission != LocationPermissionStatus.granted) {
      return _fail(
        permission == LocationPermissionStatus.deniedForever
            ? 'Location permission is permanently denied. Open Android settings to enable it.'
            : 'Location permission was denied. Questory will not start tracking.',
      );
    }
    final activeStartedAt = _clock.nowUtc();
    _session = _session!.copyWith(
      lifecycle: RunLifecycle.active,
      activeSegmentStartedAtUtc: activeStartedAt,
      updatedAtUtc: activeStartedAt,
      errorMessage: null,
    );
    if (!await _saveCheckpoint()) return;
    _subscribe();
    _startTicker();
    notifyListeners();
  }

  Future<void> restore(RunSession session) async {
    final checkpointDuration = session.activeDurationAt(session.updatedAtUtc);
    _session = session.copyWith(
      lifecycle: RunLifecycle.paused,
      activeSegmentStartedAtUtc: null,
      accumulatedActiveDuration: checkpointDuration,
      updatedAtUtc: _clock.nowUtc(),
    );
    await _saveCheckpoint();
    notifyListeners();
  }

  Future<void> pause() async {
    final current = _session;
    if (current == null || current.lifecycle != RunLifecycle.active) return;
    final now = _clock.nowUtc();
    _session = current.copyWith(
      lifecycle: RunLifecycle.paused,
      accumulatedActiveDuration: current.activeDurationAt(now),
      activeSegmentStartedAtUtc: null,
      updatedAtUtc: now,
    );
    await _stopListening();
    if (!await _saveCheckpoint()) return;
    notifyListeners();
  }

  Future<void> resume() async {
    final current = _session;
    if (current == null || current.lifecycle != RunLifecycle.paused) return;
    final now = _clock.nowUtc();
    _session = current.copyWith(
      lifecycle: RunLifecycle.active,
      activeSegmentStartedAtUtc: now,
      updatedAtUtc: now,
    );
    if (!await _saveCheckpoint()) return;
    _subscribe();
    _startTicker();
    notifyListeners();
  }

  Future<void> addEvidence(QuestEvidence evidence) async {
    final current = _session;
    if (current == null) return;
    _session = current.copyWith(
      evidence: [...current.evidence, evidence],
      completedQuestIds: {...current.completedQuestIds, evidence.questId},
      skippedQuestIds: {...current.skippedQuestIds}..remove(evidence.questId),
      updatedAtUtc: _clock.nowUtc(),
    );
    if (!await _saveCheckpoint()) return;
    notifyListeners();
  }

  Future<void> skipQuest(String questId) async {
    final current = _session;
    if (current == null) return;
    _session = current.copyWith(
      skippedQuestIds: {...current.skippedQuestIds, questId},
      updatedAtUtc: _clock.nowUtc(),
    );
    await _saveCheckpoint();
    notifyListeners();
  }

  Future<RunSummary?> finish() async {
    final current = _session;
    if (current == null ||
        (current.lifecycle != RunLifecycle.active &&
            current.lifecycle != RunLifecycle.paused)) {
      return null;
    }
    final now = _clock.nowUtc();
    final duration = current.activeDurationAt(now);
    _session = current.copyWith(
      lifecycle: RunLifecycle.finishing,
      accumulatedActiveDuration: duration,
      activeSegmentStartedAtUtc: null,
      updatedAtUtc: now,
    );
    notifyListeners();
    await _stopListening();
    final distance = RunCalculations.distanceMeters(_session!.track);
    final questResults = [
      for (final quest in availableQuests)
        RunQuestResult(
          questId: quest.id,
          title: quest.title,
          completed: _session!.completedQuestIds.contains(quest.id),
          skipped: _session!.skippedQuestIds.contains(quest.id),
        ),
    ];
    final result = RunSummary(
      id: _session!.id,
      startedAtUtc: _session!.startedAtUtc,
      activeDuration: duration,
      distanceMeters: distance,
      averagePaceSecondsPerKilometer: RunCalculations.paceSecondsPerKilometer(
        distanceMeters: distance,
        activeDuration: duration,
      ),
      locationName: _session!.locationName,
      track: _session!.track,
      landmarks: route?.landmarks.map((item) => item.name).toList() ?? const [],
      quests: questResults,
      evidence: _session!.evidence,
      estimatedCalories: (distance / 1000 * 60).round(),
    );
    try {
      await _repository.saveSummary(result);
      await _repository.clearActive();
    } catch (error) {
      _session = _session!.copyWith(
        lifecycle: RunLifecycle.paused,
        errorMessage: 'The run could not be saved locally: $error',
        updatedAtUtc: _clock.nowUtc(),
      );
      try {
        await _repository.saveActive(_session!);
      } catch (_) {
        // The in-memory snapshot remains visible so the user can retry.
      }
      notifyListeners();
      return null;
    }
    _summary = result;
    _session = _session!.copyWith(
      lifecycle: RunLifecycle.completed,
      updatedAtUtc: now,
    );
    notifyListeners();
    return result;
  }

  Future<void> discard() async {
    await _stopListening();
    await _repository.clearActive();
    _session = null;
    notifyListeners();
  }

  void _subscribe() {
    _positionSubscription ??= _locationTracker.watch().listen(
          _onPoint,
          onError: (Object error) => _fail('Location tracking failed: $error'),
        );
  }

  Future<void> _onPoint(GeoPoint point) async {
    final current = _session;
    if (current == null || current.lifecycle != RunLifecycle.active) return;
    final previous = current.track.isEmpty ? null : current.track.last;
    if (!RunCalculations.accepts(previous, point)) return;
    _session = current.copyWith(
      track: [...current.track, point],
      updatedAtUtc: _clock.nowUtc(),
    );
    await _saveCheckpoint();
    notifyListeners();
  }

  Future<bool> _saveCheckpoint() async {
    try {
      await _repository.saveActive(_session!);
      return true;
    } catch (error) {
      final current = _session;
      if (current != null) {
        final now = _clock.nowUtc();
        _session = current.copyWith(
          lifecycle: RunLifecycle.paused,
          accumulatedActiveDuration: current.activeDurationAt(now),
          activeSegmentStartedAtUtc: null,
          errorMessage:
              'Local checkpoint failed. Progress remains visible: $error',
          updatedAtUtc: now,
        );
      }
      await _stopListening();
      notifyListeners();
      return false;
    }
  }

  Future<void> _fail(String message) async {
    final current = _session;
    if (current == null) return;
    _session = current.copyWith(
      lifecycle: RunLifecycle.failed,
      activeSegmentStartedAtUtc: null,
      updatedAtUtc: _clock.nowUtc(),
      errorMessage: message,
    );
    await _stopListening();
    notifyListeners();
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
  }

  Future<void> _stopListening() async {
    _ticker?.cancel();
    _ticker = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
