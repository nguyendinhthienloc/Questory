import '../domain/destination_models.dart';

abstract interface class DestinationRepository {
  Future<List<DestinationPack>> listPacks();

  Future<DestinationPack?> getPack(String packId);
}
