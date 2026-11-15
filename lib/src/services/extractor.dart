import '../models/cli_exception.dart';
import '../platform/process_runner.dart';
import 'archive_safety.dart';

/// Lists archive entries and extracts them without a shell.
final class ArchiveExtractor {
  /// Creates an extractor.
  const ArchiveExtractor(this.processes, {required this.operatingSystem});

  /// Process runner.
  final ProcessRunner processes;

  /// `windows`, `macos`, or `linux`.
  final String operatingSystem;

  /// Extracts [archivePath] into [destinationDirectory].
  Future<void> extract({
    required String archivePath,
    required String destinationDirectory,
  }) async {
    final listing = await processes.run(
      _listTool(archivePath),
      _listArgs(archivePath),
    );
    if (listing.exitCode != 0) {
      throw CliException(
        'Could not list archive entries: ${listing.stderr}',
        exitCode: 2,
      );
    }
    requireSafeArchiveEntries(_entryNames(listing.stdout));
    final details = await processes.run(
      _listTool(archivePath),
      _detailArgs(archivePath),
    );
    if (details.exitCode != 0) {
      throw CliException(
        'Could not inspect archive entries: ${details.stderr}',
        exitCode: 2,
      );
    }
    if (archiveListingHasLink(details.stdout)) {
      throw const CliException('Archive contains a symbolic link.');
    }
    final result = await processes.run(
      _extractTool(archivePath),
      _extractArgs(archivePath, destinationDirectory),
    );
    if (result.exitCode != 0) {
      throw CliException(
        'Could not extract archive: ${result.stderr}',
        exitCode: 2,
      );
    }
  }

  bool _zipOnUnix(String archivePath) {
    return archivePath.toLowerCase().endsWith('.zip') &&
        operatingSystem != 'windows';
  }

  String _listTool(String archivePath) =>
      _zipOnUnix(archivePath) ? 'unzip' : 'tar';

  List<String> _listArgs(String archivePath) {
    if (_zipOnUnix(archivePath)) {
      return ['-Z1', archivePath];
    }
    return ['-tf', archivePath];
  }

  List<String> _detailArgs(String archivePath) {
    if (_zipOnUnix(archivePath)) {
      return ['-Z', archivePath];
    }
    return ['-tvf', archivePath];
  }

  String _extractTool(String archivePath) => _listTool(archivePath);

  List<String> _extractArgs(String archivePath, String destination) {
    if (_zipOnUnix(archivePath)) {
      return ['-q', archivePath, '-d', destination];
    }
    return ['-xf', archivePath, '-C', destination];
  }
}

List<String> _entryNames(String stdout) {
  return stdout
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}
