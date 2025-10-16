// Stub implementation for platforms without web support
Future<void> downloadBytes(List<int> bytes, String filename) async {
  // Not supported on this platform. The caller should save bytes locally.
  throw UnsupportedError('Browser download not supported on this platform.');
}
