// Conditional import helper to expose downloadBytes across platforms.
// This uses conditional imports: on web, download_web.dart is used; otherwise download_stub.dart.
import 'download_stub.dart' if (dart.library.html) 'download_web.dart' as _impl;

/// Download bytes as a file using a platform-specific implementation.
/// On web this triggers a browser download; on native platforms the stub throws
/// (the native branch in the app will save the file to disk instead).
Future<void> downloadBytes(List<int> bytes, String filename) =>
    _impl.downloadBytes(bytes, filename);
