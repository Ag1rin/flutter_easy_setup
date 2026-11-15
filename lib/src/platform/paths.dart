import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/cli_exception.dart';

/// Resolves the user home directory without treating `~` as a real path.
String resolveHome(Map<String, String> environment) {
  final home = environment['HOME'] ?? environment['USERPROFILE'];
  if (home == null || home.trim().isEmpty || home.trim() == '~') {
    throw const CliException(
      'Home directory is not set. Set HOME or USERPROFILE.',
    );
  }
  return home.trim();
}

/// Absolute Flutter SDK directory used by the interactive installer.
String defaultFlutterHome(String home) {
  return p.join(home, 'flutter');
}

/// Absolute `flutter/bin` directory.
String flutterBinPath(String flutterHome) {
  return p.join(flutterHome, 'bin');
}

/// Directory where `fes` keeps versions, backups, and JDKs.
String fesRoot(String home) {
  return p.join(home, '.fes');
}

/// True when [candidate] is [root] or a path inside it.
bool isWithinDirectory(String root, String candidate, {p.Context? context}) {
  final pathContext = context ?? p.context;
  final base = pathContext.normalize(pathContext.absolute(root));
  final target = pathContext.normalize(pathContext.absolute(candidate));
  if (target == base) {
    return true;
  }
  final prefix = base.endsWith(pathContext.separator)
      ? base
      : '$base${pathContext.separator}';
  return target.startsWith(prefix);
}

/// Refuses PATH entries that would break a shell rc file.
void validatePathToken(String path) {
  const forbidden = ['\n', '\r', '"', "'", '`', '\$', ';', '|', '&', '<', '>'];
  if (path.trim().isEmpty || forbidden.any(path.contains)) {
    throw const CliException(
      'Refusing to write a PATH entry with special characters.',
    );
  }
}

/// Platform path separator for PATH lists.
String pathListSeparator(String operatingSystem) {
  return operatingSystem == 'windows' ? ';' : ':';
}

/// True when [pathList] already contains [entry].
bool pathListContains(
  String pathList,
  String entry, {
  required String separator,
  required bool ignoreCase,
}) {
  final wanted = ignoreCase ? entry.toLowerCase() : entry;
  for (final part in pathList.split(separator)) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    final current = ignoreCase ? trimmed.toLowerCase() : trimmed;
    if (current == wanted) {
      return true;
    }
  }
  return false;
}

/// Appends [entry] when it is not already present.
String appendPathEntry(
  String pathList,
  String entry, {
  required String separator,
  required bool ignoreCase,
}) {
  validatePathToken(entry);
  if (pathListContains(
    pathList,
    entry,
    separator: separator,
    ignoreCase: ignoreCase,
  )) {
    return pathList;
  }
  if (pathList.trim().isEmpty) {
    return entry;
  }
  final trimmed = pathList.endsWith(separator)
      ? pathList.substring(0, pathList.length - 1)
      : pathList;
  return '$trimmed$separator$entry';
}

/// Reads a file when it exists.
String? readIfExists(File file) {
  if (!file.existsSync()) {
    return null;
  }
  return file.readAsStringSync();
}
