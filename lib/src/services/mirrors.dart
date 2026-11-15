import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../models/cli_exception.dart';
import '../package_info.dart';
import 'https.dart';

/// One Flutter storage and pub mirror.
final class Mirror {
  /// Creates a mirror.
  const Mirror({
    required this.id,
    required this.storage,
    required this.pubHost,
  });

  /// Stable id such as `official`.
  final String id;

  /// `FLUTTER_STORAGE_BASE_URL` value.
  final String storage;

  /// `PUB_HOSTED_URL` value.
  final String pubHost;
}

/// Built-in mirrors. Only `official` is selected unless the user changes it.
const defaultMirrors = <Mirror>[
  Mirror(
    id: 'official',
    storage: officialStorageBase,
    pubHost: officialPubHost,
  ),
  Mirror(
    id: 'china',
    storage: 'https://storage.flutter-io.cn',
    pubHost: 'https://pub.flutter-io.cn',
  ),
];

/// Parses a mirror list from YAML text.
List<Mirror> parseMirrors(String source) {
  final decoded = loadYaml(source);
  if (decoded is! YamlMap) {
    throw const CliException('Mirror config must be a YAML map.');
  }
  final raw = decoded['mirrors'];
  if (raw is! YamlList || raw.isEmpty) {
    throw const CliException('Mirror config needs a mirrors list.');
  }
  final mirrors = <Mirror>[];
  final seen = <String>{};
  for (final item in raw) {
    if (item is! YamlMap) {
      throw const CliException('Each mirror must be a YAML map.');
    }
    final mirror = _mirror(item);
    if (!seen.add(mirror.id)) {
      throw CliException('Duplicate mirror id: ${mirror.id}');
    }
    mirrors.add(mirror);
  }
  return mirrors;
}

/// Loads `~/.fes/mirrors.yaml` when it exists, otherwise [defaultMirrors].
List<Mirror> loadMirrors(String home) {
  final file = File(_mirrorPath(home));
  if (!file.existsSync()) {
    return defaultMirrors;
  }
  return parseMirrors(file.readAsStringSync());
}

/// Finds [id] or throws.
Mirror requireMirror(List<Mirror> mirrors, String id) {
  for (final mirror in mirrors) {
    if (mirror.id == id) {
      return mirror;
    }
  }
  throw CliException('Unknown mirror: $id');
}

/// Reads the selected mirror id. Missing config means `official`.
String activeMirrorId(String home) {
  final file = File(_configPath(home));
  if (!file.existsSync()) {
    return 'official';
  }
  final decoded = loadYaml(file.readAsStringSync());
  if (decoded is! YamlMap) {
    throw const CliException('fes config must be a YAML map.');
  }
  final id = decoded['mirror'];
  if (id == null) {
    return 'official';
  }
  if (id is! String || id.trim().isEmpty) {
    throw const CliException('fes config has an invalid mirror id.');
  }
  return id.trim();
}

/// Writes the selected mirror id.
Future<void> writeActiveMirror(String home, String id) async {
  _validateMirrorId(id);
  final file = File(_configPath(home));
  await file.parent.create(recursive: true);
  final lang = _readLang(file);
  final buffer = StringBuffer('mirror: $id\n');
  if (lang != null) {
    buffer.writeln('lang: $lang');
  }
  await file.writeAsString(buffer.toString());
}

/// Reads the saved language, or null.
String? readSavedLang(String home) {
  final file = File(_configPath(home));
  if (!file.existsSync()) {
    return null;
  }
  return _readLang(file);
}

/// Writes the saved language without dropping the mirror.
Future<void> writeSavedLang(String home, String lang) async {
  if (lang != 'en' && lang != 'fa') {
    throw const CliException('Language must be en or fa.');
  }
  final file = File(_configPath(home));
  await file.parent.create(recursive: true);
  final mirror = file.existsSync() ? activeMirrorId(home) : 'official';
  await file.writeAsString('mirror: $mirror\nlang: $lang\n');
}

String _mirrorPath(String home) => p.join(home, '.fes', 'mirrors.yaml');

String _configPath(String home) => p.join(home, '.fes', 'config.yaml');

String? _readLang(File file) {
  if (!file.existsSync()) {
    return null;
  }
  final decoded = loadYaml(file.readAsStringSync());
  if (decoded is! YamlMap) {
    return null;
  }
  final lang = decoded['lang'];
  if (lang == 'en' || lang == 'fa') {
    return lang;
  }
  return null;
}

Mirror _mirror(YamlMap item) {
  final id = item['id'];
  final storage = item['storage'];
  final pubHost = item['pub'];
  if (id is! String || storage is! String || pubHost is! String) {
    throw const CliException('A mirror needs id, storage, and pub.');
  }
  _validateMirrorId(id);
  return Mirror(
    id: id,
    storage: validateBaseUrl(storage),
    pubHost: validateBaseUrl(pubHost),
  );
}

void _validateMirrorId(String id) {
  if (!RegExp(r'^[a-z][a-z0-9-]{0,31}$').hasMatch(id)) {
    throw CliException('Invalid mirror id: $id');
  }
}
