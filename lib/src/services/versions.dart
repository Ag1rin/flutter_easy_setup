import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../models/cli_exception.dart';
import '../platform/paths.dart';
import 'release_index.dart';

/// What the installer should do with the Flutter SDK.
enum FlutterInstallChoice {
  /// Flutter is already on PATH and no version was pinned.
  skip,

  /// `~/flutter` exists and can be reused.
  reuse,

  /// Download an archive.
  download,
}

/// Chooses whether option 3 downloads Flutter.
FlutterInstallChoice chooseFlutterInstall({
  required bool flutterOnPath,
  required bool localExists,
  required bool versionPinned,
}) {
  if (versionPinned) {
    return FlutterInstallChoice.download;
  }
  if (flutterOnPath) {
    return FlutterInstallChoice.skip;
  }
  if (localExists) {
    return FlutterInstallChoice.reuse;
  }
  return FlutterInstallChoice.download;
}

/// Reads `flutter:` from `.fes.yaml` in [directory].
String? readProjectFlutterVersion(String directory) {
  final file = File(p.join(directory, '.fes.yaml'));
  if (!file.existsSync()) {
    return null;
  }
  final decoded = loadYaml(file.readAsStringSync());
  if (decoded is! YamlMap) {
    throw const CliException('.fes.yaml must be a YAML map.');
  }
  final version = decoded['flutter'];
  if (version is! String) {
    throw const CliException('.fes.yaml must contain flutter: <version>.');
  }
  validateFlutterVersion(version);
  return version;
}

/// One installed SDK under `~/.fes/versions`.
final class InstalledSdk {
  /// Creates an installed SDK record.
  const InstalledSdk({
    required this.version,
    required this.location,
    required this.active,
  });

  /// Version directory name.
  final String version;

  /// Absolute `flutter` directory.
  final String location;

  /// True when `~/.fes/active` points here.
  final bool active;
}

/// Lists, activates, and deletes SDKs under `~/.fes/versions`.
final class VersionStore {
  /// Creates a store rooted at [home].
  const VersionStore(this.home);

  /// User home directory.
  final String home;

  /// `~/.fes/versions`.
  String get root => p.join(fesRoot(home), 'versions');

  /// `~/.fes/active`.
  String get activeLink => p.join(fesRoot(home), 'active');

  /// Installed versions. Does not follow links outside [root].
  List<InstalledSdk> list() {
    final directory = Directory(root);
    if (!directory.existsSync()) {
      return const [];
    }
    final active = _activeTarget();
    final found = <InstalledSdk>[];
    for (final entity in directory.listSync()) {
      if (entity is! Directory) {
        continue;
      }
      final version = p.basename(entity.path);
      final flutterHome = p.join(entity.path, 'flutter');
      if (!isWithinDirectory(root, entity.path)) {
        continue;
      }
      if (!Directory(flutterHome).existsSync()) {
        continue;
      }
      found.add(
        InstalledSdk(
          version: version,
          location: flutterHome,
          active: active == p.normalize(flutterHome),
        ),
      );
    }
    found.sort((a, b) => a.version.compareTo(b.version));
    return found;
  }

  /// Deletes one version directory.
  Future<String> remove(
    String version, {
    required bool allowActive,
    required bool dryRun,
  }) async {
    validateFlutterVersion(version);
    final target = p.join(root, version);
    if (!isWithinDirectory(root, target) || !Directory(target).existsSync()) {
      throw CliException('Flutter $version is not installed.');
    }
    final active = list().any((item) => item.version == version && item.active);
    if (active && !allowActive) {
      throw const CliException(
        'Refusing to remove the active version without --yes.',
      );
    }
    if (!dryRun) {
      await Directory(target).delete(recursive: true);
    }
    return target;
  }

  String? _activeTarget() {
    final link = Link(activeLink);
    if (!link.existsSync()) {
      return null;
    }
    return p.normalize(link.targetSync());
  }
}

/// Default Android SDK directory for this host.
String defaultAndroidSdk({
  required String home,
  required String operatingSystem,
  required Map<String, String> environment,
}) {
  final current =
      environment['ANDROID_HOME'] ?? environment['ANDROID_SDK_ROOT'];
  if (current != null && current.trim().isNotEmpty) {
    validatePathToken(current.trim());
    return current.trim();
  }
  if (operatingSystem == 'macos') {
    return p.join(home, 'Library', 'Android', 'sdk');
  }
  if (operatingSystem == 'windows') {
    final local = environment['LOCALAPPDATA'];
    if (local != null && local.trim().isNotEmpty) {
      return p.join(local.trim(), 'Android', 'Sdk');
    }
  }
  return p.join(home, 'Android', 'Sdk');
}
