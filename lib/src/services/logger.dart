import 'dart:io';

/// Appends failures to `flutter_setup_log.txt`.
final class SetupLogger {
  /// Creates a logger that writes [file].
  SetupLogger(this.file);

  /// Log file. Created on the first error.
  final File file;

  /// Writes [message] and an optional stack trace.
  void error(Object message, [StackTrace? stack]) {
    final text = StringBuffer('${DateTime.now().toIso8601String()} $message');
    if (stack != null) {
      text.writeln();
      text.write(stack);
    }
    text.writeln();
    try {
      file.writeAsStringSync(text.toString(), mode: FileMode.append);
    } on IOException {
      stderr.writeln(text);
    }
  }
}
