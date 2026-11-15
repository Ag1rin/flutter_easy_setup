/// A failure the CLI can explain to the user.
final class CliException implements Exception {
  /// Creates a user-facing failure.
  ///
  /// [exitCode] is 1 for validation problems and 2 for download or tool
  /// failures.
  const CliException(this.message, {this.exitCode = 1});

  /// Text safe to print on the console.
  final String message;

  /// Process exit code for this failure.
  final int exitCode;

  @override
  String toString() => message;
}

/// A download, checksum, or network failure.
final class DownloadException extends CliException {
  /// Creates a download failure that exits with code 2.
  const DownloadException(super.message) : super(exitCode: 2);
}
