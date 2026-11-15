/// Version compiled into the CLI.
///
/// Tests require this to match `version:` in `pubspec.yaml`.
const compiledPackageVersion = '1.1.0';

/// GitHub repository that publishes `fes` releases.
const githubRepository = 'Ag1rin/flutter_easy_setup';

/// Official Flutter storage host. Mirrors are opt-in.
const officialStorageBase = 'https://storage.googleapis.com';

/// Official pub host. Mirrors are opt-in.
const officialPubHost = 'https://pub.dev';

/// Reads the `version:` field from pubspec text.
String parsePubspecVersion(String pubspec) {
  final match = RegExp(
    r'^version:\s*(\S+)\s*$',
    multiLine: true,
  ).firstMatch(pubspec);
  if (match == null) {
    throw StateError('pubspec.yaml has no version.');
  }
  return match.group(1)!;
}
