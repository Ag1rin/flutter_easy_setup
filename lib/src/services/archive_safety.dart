import '../models/cli_exception.dart';

/// True when an archive entry stays inside the destination directory.
bool isSafeArchiveEntry(String name) {
  if (name.isEmpty || name.contains('\x00')) {
    return false;
  }
  final normalized = name.replaceAll('\\', '/');
  if (normalized.startsWith('/') || normalized.startsWith('//')) {
    return false;
  }
  if (RegExp(r'^[A-Za-z]:').hasMatch(normalized)) {
    return false;
  }
  final parts = normalized.split('/');
  return !parts.any((part) => part == '..');
}

/// Rejects the first unsafe archive entry.
void requireSafeArchiveEntries(Iterable<String> entries) {
  for (final entry in entries) {
    if (!isSafeArchiveEntry(entry)) {
      throw CliException('Archive contains an unsafe path: $entry');
    }
  }
}

/// Accepts a download file name that cannot escape its directory.
String safeFileName(String name) {
  if (name.isEmpty ||
      name == '.' ||
      name == '..' ||
      !RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(name)) {
    throw CliException('Unsafe download file name.');
  }
  return name;
}

/// True when a `tar -tv` or zipinfo listing contains a symbolic link.
bool archiveListingHasLink(String listing) {
  for (final raw in listing.split(RegExp(r'\r?\n'))) {
    final line = raw.trimLeft();
    if (line.startsWith('l') && line.contains(' -> ')) {
      return true;
    }
  }
  return false;
}
