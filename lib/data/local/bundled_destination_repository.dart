import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/contracts/destination_repository.dart';
import '../../core/domain/destination_models.dart';

class BundledDestinationRepository implements DestinationRepository {
  BundledDestinationRepository({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  static const _assetPaths = [
    'assets/destinations/nha_trang_pack_v1.json',
    'assets/destinations/ho_chi_minh_city_pack_v1.json',
  ];

  final AssetBundle _bundle;
  List<DestinationPack>? _cache;

  @override
  Future<DestinationPack?> getPack(String packId) async {
    final packs = await listPacks();
    for (final pack in packs) {
      if (pack.id == packId) return pack;
    }
    return null;
  }

  @override
  Future<List<DestinationPack>> listPacks() async {
    final cached = _cache;
    if (cached != null) return cached;
    final packs = <DestinationPack>[];
    for (final path in _assetPaths) {
      final source = await _bundle.loadString(path);
      final json = jsonDecode(source);
      if (json is! Map) {
        throw FormatException('$path does not contain a JSON object.');
      }
      packs.add(
        DestinationPack.fromJson(Map<String, Object?>.from(json)),
      );
    }
    packs.sort((a, b) => a.cityName.compareTo(b.cityName));
    return _cache = List.unmodifiable(packs);
  }
}
