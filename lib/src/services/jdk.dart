import 'dart:convert';

import '../models/cli_exception.dart';
import 'https.dart';

/// A Temurin JDK archive from the Adoptium API.
final class JdkAsset {
  /// Creates a JDK archive description.
  const JdkAsset({
    required this.version,
    required this.url,
    required this.sha256,
  });

  /// Semver reported by Adoptium.
  final String version;

  /// HTTPS download URL.
  final Uri url;

  /// Lowercase SHA-256.
  final String sha256;
}

/// Parses an Adoptium assets JSON list for one OS and architecture.
JdkAsset parseAdoptiumAssets(
  String source, {
  required String os,
  required String arch,
}) {
  final decoded = jsonDecode(source);
  if (decoded is! List || decoded.isEmpty) {
    throw const CliException('Adoptium returned no JDK builds.');
  }
  for (final item in decoded) {
    final asset = _tryAsset(item, os: os, arch: arch);
    if (asset != null) {
      return asset;
    }
  }
  throw CliException('Adoptium has no JDK 17 build for $os/$arch.');
}

/// Adoptium API URL for Temurin 17.
Uri adoptiumLatestUri({required String os, required String arch}) {
  final query = {
    'architecture': arch,
    'image_type': 'jdk',
    'os': os,
    'vendor': 'eclipse',
  };
  return requireHttps(
    Uri.https('api.adoptium.net', '/v3/assets/latest/17/hotspot', query),
  );
}

/// Maps this CLI's OS name to Adoptium's name.
String adoptiumOs(String operatingSystem) {
  return switch (operatingSystem) {
    'windows' => 'windows',
    'macos' => 'mac',
    'linux' => 'linux',
    _ => throw CliException('Unsupported operating system: $operatingSystem.'),
  };
}

/// Maps this CLI's architecture to Adoptium's name.
String adoptiumArch(String arch) {
  return switch (arch) {
    'x64' => 'x64',
    'arm64' => 'aarch64',
    _ => throw const CliException('Architecture must be x64 or arm64.'),
  };
}

/// Relative directory inside a JDK archive that contains `bin/java`.
String? javaHomeRelative(Iterable<String> entries) {
  for (final entry in entries) {
    final normalized = entry.replaceAll('\\', '/');
    final isJava =
        normalized.endsWith('/bin/java') ||
        normalized.endsWith('/bin/java.exe') ||
        normalized == 'bin/java' ||
        normalized == 'bin/java.exe';
    if (!isJava) {
      continue;
    }
    final parts = normalized.split('/');
    if (parts.length < 2) {
      return '';
    }
    return parts.sublist(0, parts.length - 2).join('/');
  }
  return null;
}

JdkAsset? _tryAsset(Object? item, {required String os, required String arch}) {
  if (item is! Map) {
    return null;
  }
  final root = Map<String, Object?>.from(item);
  final binary = root['binary'];
  if (binary is! Map) {
    return null;
  }
  final body = Map<String, Object?>.from(binary);
  if (body['image_type'] != 'jdk' ||
      body['os'] != os ||
      body['architecture'] != arch) {
    return null;
  }
  final package = body['package'];
  if (package is! Map) {
    return null;
  }
  final details = Map<String, Object?>.from(package);
  final link = details['link'];
  final checksum = details['checksum'];
  if (link is! String || checksum is! String) {
    return null;
  }
  if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(checksum)) {
    return null;
  }
  final version = root['version'];
  final semver = version is Map ? version['semver'] : null;
  return JdkAsset(
    version: semver is String ? semver : '17',
    url: requireHttps(Uri.parse(link)),
    sha256: checksum.toLowerCase(),
  );
}
