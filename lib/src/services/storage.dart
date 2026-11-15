import 'https.dart';
import 'mirrors.dart';
import 'release_index.dart';

/// Storage host for this run: environment override, then the saved mirror.
String resolveStorageBase({
  required Map<String, String> environment,
  required String home,
}) {
  final fromEnv = environment['FLUTTER_STORAGE_BASE_URL'];
  if (fromEnv != null && fromEnv.trim().isNotEmpty) {
    return storageBaseFromEnvironment(environment);
  }
  final mirrors = loadMirrors(home);
  return requireMirror(mirrors, activeMirrorId(home)).storage;
}

/// Pub host for the saved mirror, unless `PUB_HOSTED_URL` is already set.
String resolvePubHost({
  required Map<String, String> environment,
  required String home,
}) {
  final fromEnv = environment['PUB_HOSTED_URL'];
  if (fromEnv != null && fromEnv.trim().isNotEmpty) {
    return validateBaseUrl(fromEnv);
  }
  final mirrors = loadMirrors(home);
  return requireMirror(mirrors, activeMirrorId(home)).pubHost;
}
