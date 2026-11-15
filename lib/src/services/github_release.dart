import 'dart:convert';

import '../models/cli_exception.dart';
import '../models/cpu_arch.dart';
import 'http_fetcher.dart';
import 'https.dart';

/// One file attached to a GitHub release.
final class GitHubAsset {
  /// Creates an asset.
  const GitHubAsset({required this.name, required this.url});

  /// Asset file name.
  final String name;

  /// Browser download URL.
  final Uri url;
}

/// A GitHub release document.
final class GitHubRelease {
  /// Creates a release.
  const GitHubRelease({required this.tag, required this.assets});

  /// Tag name, including the leading `v` when GitHub sends one.
  final String tag;

  /// Downloadable assets.
  final List<GitHubAsset> assets;

  /// Finds [name] or throws.
  GitHubAsset requireAsset(String name) {
    for (final asset in assets) {
      if (asset.name == name) {
        return asset;
      }
    }
    throw CliException('Release $tag has no asset named $name.');
  }
}

/// Parses `/releases/latest` JSON.
GitHubRelease parseGitHubRelease(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) {
    throw const CliException('GitHub release is not a JSON object.');
  }
  final root = Map<String, Object?>.from(decoded);
  final tag = root['tag_name'];
  final rawAssets = root['assets'];
  if (tag is! String || tag.isEmpty || rawAssets is! List) {
    throw const CliException('GitHub release is missing a tag or assets.');
  }
  if (!RegExp(r'^v?\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$').hasMatch(tag)) {
    throw CliException('Refusing unexpected release tag: $tag');
  }
  final assets = <GitHubAsset>[];
  for (final item in rawAssets) {
    final asset = _asset(item);
    if (asset != null) {
      assets.add(asset);
    }
  }
  return GitHubRelease(tag: tag, assets: assets);
}

/// Asset name published by the release workflow.
String releaseAssetName({
  required String operatingSystem,
  required CpuArch arch,
}) {
  final suffix = switch (operatingSystem) {
    'windows' => '.exe',
    'macos' || 'linux' => '',
    _ => throw CliException('Unsupported operating system: $operatingSystem.'),
  };
  return 'fes-$operatingSystem-${arch.name}$suffix';
}

/// True when [latest] is a newer semver than [current].
bool isNewerVersion(String latest, String current) {
  final left = _numbers(latest);
  final right = _numbers(current);
  for (var i = 0; i < 3; i++) {
    if (left[i] != right[i]) {
      return left[i] > right[i];
    }
  }
  return false;
}

/// Expected hash for [fileName] inside a `SHA256SUMS` document.
String requireChecksum(String sums, String fileName) {
  final hash = checksumForFile(sums, fileName);
  if (hash == null) {
    throw CliException('SHA256SUMS has no entry for $fileName.');
  }
  return hash;
}

/// True when this executable is a pub global install rather than a release binary.
bool isPubGlobalInstall(String executablePath) {
  final normalized = executablePath.replaceAll('\\', '/').toLowerCase();
  return normalized.contains('/.pub-cache/') ||
      normalized.contains('/pub-cache/') ||
      normalized.contains('/pub/cache/') ||
      normalized.contains('/dart-sdk/');
}

List<int> _numbers(String version) {
  final stripped = version.startsWith('v') ? version.substring(1) : version;
  final core = stripped.split(RegExp(r'[-+]')).first;
  final parts = core.split('.');
  if (parts.length < 3) {
    throw CliException('Not a semver version: $version');
  }
  return [
    for (final part in parts.take(3))
      int.tryParse(part) ??
          (throw CliException('Not a semver version: $version')),
  ];
}

GitHubAsset? _asset(Object? item) {
  if (item is! Map) {
    return null;
  }
  final json = Map<String, Object?>.from(item);
  final name = json['name'];
  final url = json['browser_download_url'];
  if (name is! String || url is! String) {
    return null;
  }
  if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(name)) {
    return null;
  }
  final uri = requireHttps(Uri.parse(url));
  const allowed = {
    'github.com',
    'api.github.com',
    'objects.githubusercontent.com',
    'release-assets.githubusercontent.com',
  };
  if (!allowed.contains(uri.host)) {
    throw CliException('Refusing release asset host ${uri.host}.');
  }
  return GitHubAsset(name: name, url: uri);
}
