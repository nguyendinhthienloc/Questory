abstract interface class PhotoStore {
  Future<String> retain({
    required String temporaryPath,
    required String evidenceId,
  });

  Future<bool> exists(String path);

  Future<void> delete(String path);
}
