import 'dart:convert';

import '../models/cli_exception.dart';
import '../models/cpu_arch.dart';
import '../package_info.dart';
import 'https.dart';

/// One Flutter SDK archive from a releases index.
final class FlutterArchive {
  /// Creates an archive description.
  const FlutterArchive({
    required this.hash,
    required this.channel,
    required this.version,
    required this.arch,
    required this.archive,
    required this.sha256,
    required this.releaseDate,
  });

  /// Framework commit hash.
  final String hash;

  /// `stable` or `beta`.
  final String channel;

  /// Flutter version, such as `3.24.5` or `3.25.0-0.1.pre`.
  final String version;

  /// CPU architecture of this archive.
  final CpuArch arch;

  /// Path relative to the releases root.
  final String archive;

  /// Lowercase SHA-256 of the archive bytes.
  final String sha256;

  /// When this archive was published.
  final DateTime releaseDate;

  /// Absolute HTTPS URL for [storageBaseUrl].
  Uri downloadUri(String storageBaseUrl) {
    final base = validateBaseUrl(storageBaseUrl);
    final relative = archive.startsWith('/') ? archive.substring(1) : archive;
    return requireHttps(
      Uri.parse('$base/flutter_infra_release/releases/$relative'),
    );
  }
}

/// Parsed `releases_<os>.json` document.
final class ReleaseIndex {
  /// Creates an index from already validated releases.
  const ReleaseIndex({required this.currentRelease, required this.releases});

  /// Channel name to the current framework hash.
  final Map<String, String> currentRelease;

  /// Archives that have a SHA-256.
  final List<FlutterArchive> releases;

  /// Parses Flutter's releases JSON.
  ///
  /// Entries without a SHA-256 are skipped. Selection fails later if the
  /// requested archive was one of those entries.
  factory ReleaseIndex.parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const CliException('Flutter release index is not a JSON object.');
    }
    final root = Map<String, Object?>.from(decoded);
    final current = _requireMap(root['current_release'], 'current_release');
    final currentRelease = <String, String>{};
    for (final channel in const ['stable', 'beta']) {
      final hash = current[channel];
      if (hash is String && hash.isNotEmpty) {
        currentRelease[channel] = hash;
      }
    }
    final rawReleases = root['releases'];
    if (rawReleases is! List) {
      throw const CliException('Flutter release index has no releases list.');
    }
    final releases = <FlutterArchive>[];
    for (final item in rawReleases) {
      final archive = _tryParseRelease(item);
      if (archive != null) {
        releases.add(archive);
      }
    }
    if (releases.isEmpty) {
      throw const CliException('Flutter release index has no usable archives.');
    }
    return ReleaseIndex(currentRelease: currentRelease, releases: releases);
  }

  /// Selects one archive for [channel], [arch], and an optional [version].
  FlutterArchive select({
    required String channel,
    required CpuArch arch,
    String? version,
  }) {
    final normalized = normalizeChannel(channel);
    if (version != null) {
      validateFlutterVersion(version);
    }
    final currentHash = currentRelease[normalized];
    if (currentHash == null) {
      throw CliException('Release index has no $normalized channel.');
    }
    final onChannel = releases.where((item) => item.channel == normalized);
    final current = onChannel.where((item) => item.hash == currentHash);
    final resolvedVersion = version ?? _versionOf(current, normalized);
    final matches =
        onChannel
            .where(
              (item) => item.version == resolvedVersion && item.arch == arch,
            )
            .toList()
          ..sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    if (matches.isEmpty) {
      throw CliException(
        'No $normalized Flutter $resolvedVersion archive for ${arch.name}.',
      );
    }
    for (final match in matches) {
      if (match.hash == currentHash) {
        return match;
      }
    }
    return matches.first;
  }
}

/// URL of `releases_<os>.json` for a storage host.
Uri flutterReleasesUri({required String storageBaseUrl, required String os}) {
  final base = validateBaseUrl(storageBaseUrl);
  final normalized = switch (os) {
    'windows' || 'macos' || 'linux' => os,
    _ => throw CliException('Unsupported operating system: $os.'),
  };
  return requireHttps(
    Uri.parse('$base/flutter_infra_release/releases/releases_$normalized.json'),
  );
}

/// Default storage host, or `FLUTTER_STORAGE_BASE_URL` when it is set.
String storageBaseFromEnvironment(Map<String, String> environment) {
  final override = environment['FLUTTER_STORAGE_BASE_URL'];
  if (override == null || override.trim().isEmpty) {
    return officialStorageBase;
  }
  return validateBaseUrl(override);
}

/// Accepts `stable` or `beta`.
String normalizeChannel(String channel) {
  final value = channel.trim().toLowerCase();
  if (value != 'stable' && value != 'beta') {
    throw const CliException('Channel must be stable or beta.');
  }
  return value;
}

/// Accepts Flutter stable and prerelease version strings.
void validateFlutterVersion(String version) {
  final pattern = RegExp(r'^\d+\.\d+\.\d+(?:[.-][0-9A-Za-z.-]+)?$');
  if (!pattern.hasMatch(version) || version.contains('..')) {
    throw CliException('Version must look like 3.24.5 or 3.25.0-0.1.pre.');
  }
}

/// True when [value] is 64 hexadecimal characters.
bool isSha256Hex(String value) {
  return RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(value);
}

String _versionOf(Iterable<FlutterArchive> current, String channel) {
  for (final item in current) {
    return item.version;
  }
  throw CliException('Release index has no current $channel release.');
}

Map<String, Object?> _requireMap(Object? value, String name) {
  if (value is! Map) {
    throw CliException('Flutter release index is missing $name.');
  }
  return Map<String, Object?>.from(value);
}

FlutterArchive? _tryParseRelease(Object? item) {
  if (item is! Map) {
    return null;
  }
  final json = Map<String, Object?>.from(item);
  final hash = json['hash'];
  final channel = json['channel'];
  final version = json['version'];
  final arch = json['dart_sdk_arch'];
  final archive = json['archive'];
  final sha256 = json['sha256'];
  if (hash is! String ||
      channel is! String ||
      version is! String ||
      arch is! String ||
      archive is! String ||
      sha256 is! String) {
    return null;
  }
  if (!isSha256Hex(sha256) || !isSafeArchivePath(archive)) {
    return null;
  }
  final cpu = switch (arch) {
    'x64' => CpuArch.x64,
    'arm64' => CpuArch.arm64,
    _ => null,
  };
  if (cpu == null || (channel != 'stable' && channel != 'beta')) {
    return null;
  }
  final rawDate = json['release_date'];
  final date = rawDate is String
      ? DateTime.tryParse(rawDate) ?? DateTime.utc(1970)
      : DateTime.utc(1970);
  return FlutterArchive(
    hash: hash,
    channel: channel,
    version: version,
    arch: cpu,
    archive: archive,
    sha256: sha256.toLowerCase(),
    releaseDate: date.toUtc(),
  );
}

/// True when a release archive path cannot escape the releases root.
bool isSafeArchivePath(String archive) {
  if (archive.isEmpty || archive.contains('\\') || archive.contains('..')) {
    return false;
  }
  if (archive.startsWith('/') || archive.contains('://')) {
    return false;
  }
  return RegExp(r'^[A-Za-z0-9._/-]+$').hasMatch(archive);
}
