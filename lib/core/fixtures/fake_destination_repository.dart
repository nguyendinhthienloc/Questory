import '../contracts/destination_repository.dart';
import '../domain/destination_models.dart';

class FakeDestinationRepository implements DestinationRepository {
  FakeDestinationRepository({Iterable<DestinationPack> seed = const []})
      : _packs = {for (final pack in seed) pack.id: pack};

  final Map<String, DestinationPack> _packs;

  @override
  Future<DestinationPack?> getPack(String packId) async => _packs[packId];

  @override
  Future<List<DestinationPack>> listPacks() async =>
      List.unmodifiable(_packs.values);
}
