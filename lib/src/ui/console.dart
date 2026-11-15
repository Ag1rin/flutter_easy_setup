import 'dart:io';

import 'package:ansicolor/ansicolor.dart';

/// Console output. Tests substitute an in-memory implementation.
abstract interface class Console {
  /// Writes one line.
  void writeln([String line = '']);

  /// Writes without a newline.
  void write(String text);
}

/// Console backed by stdout.
final class StdConsole implements Console {
  /// Creates a stdout console.
  const StdConsole();

  @override
  void writeln([String line = '']) => stdout.writeln(line);

  @override
  void write(String text) => stdout.write(text);
}

/// Reads one line. Tests substitute a queue.
abstract interface class LineReader {
  /// Returns the next line, without the newline, or null at EOF.
  String? readLine();
}

/// [LineReader] backed by stdin.
final class StdinReader implements LineReader {
  /// Creates a stdin reader.
  const StdinReader();

  @override
  String? readLine() => stdin.readLineSync();
}

/// Colors that can be turned off with `--no-color`.
final class Palette {
  /// Creates a palette.
  Palette({required this.enabled})
    : _green = AnsiPen()..green(bold: true),
      _red = AnsiPen()..red(bold: true),
      _yellow = AnsiPen()..yellow(bold: true),
      _cyan = AnsiPen()..cyan(bold: true);

  /// When false, text is returned unchanged.
  final bool enabled;

  final AnsiPen _green;
  final AnsiPen _red;
  final AnsiPen _yellow;
  final AnsiPen _cyan;

  /// Green text.
  String green(String text) => enabled ? _green(text) : text;

  /// Red text.
  String red(String text) => enabled ? _red(text) : text;

  /// Yellow text.
  String yellow(String text) => enabled ? _yellow(text) : text;

  /// Cyan text.
  String cyan(String text) => enabled ? _cyan(text) : text;
}

/// In-memory console used by tests and dry runs that capture text.
final class MemoryConsole implements Console {
  /// Captured lines and writes.
  final buffer = StringBuffer();

  @override
  void writeln([String line = '']) => buffer.writeln(line);

  @override
  void write(String text) => buffer.write(text);
}

/// In-memory line reader.
final class MemoryReader implements LineReader {
  /// Creates a reader that returns [lines] in order.
  MemoryReader(this.lines);

  /// Remaining answers.
  final List<String?> lines;

  @override
  String? readLine() => lines.isEmpty ? null : lines.removeAt(0);
}
