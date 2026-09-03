import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/contracts/live_share_service.dart';
import '../../core/domain/run_models.dart';
import '../../core/domain/shared_run.dart';

class SupabaseLiveShareService implements LiveShareService {
  SupabaseLiveShareService({
    required String supabaseUrl,
    required this.anonKey,
    http.Client? client,
  })  : baseUrl = supabaseUrl.replaceFirst(RegExp(r'/$'), ''),
        client = client ?? http.Client();

  final String baseUrl;
  final String anonKey;
  final http.Client client;

  Uri get _endpoint => Uri.parse('$baseUrl/functions/v1/share-run');

  Map<String, String> get _headers => {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      };

  @override
  Future<ShareLink> createShare(
    RunSummary summary, {
    Duration expiresIn = const Duration(hours: 24),
  }) async {
    final response = await client.post(
      _endpoint,
      headers: _headers,
      body: jsonEncode({
        'run': _shareableRunJson(summary),
        'expiresInSeconds': expiresIn.inSeconds,
      }),
    );
    _checkResponse(response);
    final result = _decodeObject(response);
    result['shareUrl'] ??= _endpoint.replace(queryParameters: {
      'shareId': result['shareId'],
      'token': result['token'],
    }).toString();
    return ShareLink.fromJson(result);
  }

  @override
  Future<SharedRunPreview> loadSharedRun({
    required String shareId,
    required String token,
  }) async {
    final response = await client.get(
      _endpoint.replace(queryParameters: {'shareId': shareId}),
      headers: {..._headers, 'X-Share-Token': token},
    );
    _checkResponse(response);
    return SharedRunPreview.fromJson(_decodeObject(response));
  }

  @override
  Future<void> uploadEvidence({
    required ShareLink share,
    required QuestEvidence evidence,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _endpoint.replace(queryParameters: {'shareId': share.shareId}),
    )
      ..headers.addAll(_headers)
      ..headers['X-Share-Token'] = share.token
      ..fields['evidence'] = jsonEncode({
        'id': evidence.id,
        'questId': evidence.questId,
        'caption': evidence.caption,
        'capturedAtUtc': evidence.capturedAtUtc.toIso8601String(),
        'point': evidence.point.toJson(),
      })
      ..files.add(
        await http.MultipartFile.fromPath('image', evidence.photoPath),
      );
    final response = await client.send(request);
    final body = await response.stream.bytesToString();
    _checkResponse(http.Response(body, response.statusCode));
  }

  @override
  Future<void> revokeShare(
      {required String shareId, required String token}) async {
    final response = await client.delete(
      _endpoint.replace(queryParameters: {'shareId': shareId}),
      headers: {..._headers, 'X-Share-Token': token},
    );
    _checkResponse(response);
  }

  Map<String, Object?> _shareableRunJson(RunSummary summary) => {
        'id': summary.id,
        'startedAtUtc': summary.startedAtUtc.toIso8601String(),
        'activeDurationSeconds': summary.activeDuration.inSeconds,
        'distanceMeters': summary.distanceMeters,
        'averagePaceSecondsPerKilometer':
            summary.averagePaceSecondsPerKilometer,
        'locationName': summary.locationName,
        'track': summary.track.map((point) => point.toJson()).toList(),
        'landmarks': summary.landmarks,
        'quests': summary.quests.map((quest) => quest.toJson()).toList(),
      };

  Map<String, Object?> _decodeObject(http.Response response) {
    final decoded = jsonDecode(response.body);
    return Map<String, Object?>.from(decoded as Map);
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ShareServiceException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
  }
}

class ShareServiceException implements Exception {
  const ShareServiceException(
      {required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'ShareServiceException($statusCode): $message';
}
