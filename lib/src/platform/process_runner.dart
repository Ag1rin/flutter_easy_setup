import 'dart:convert';
import 'dart:io';

/// Result of a finished process.
final class CommandResult {
  /// Creates a process result.
  const CommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  /// Process exit code.
  final int exitCode;

  /// Standard output, decoded as UTF-8.
  final String stdout;

  /// Standard error, decoded as UTF-8.
  final String stderr;
}

/// Runs a program with an argument list. Implementations must not use a shell.
abstract interface class ProcessRunner {
  /// Runs [executable] and waits for it to exit.
  Future<CommandResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    String? stdin,
  });
}

/// [ProcessRunner] backed by `dart:io`.
final class SystemProcessRunner implements ProcessRunner {
  /// Creates a system process runner.
  const SystemProcessRunner();

  @override
  Future<CommandResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    String? stdin,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: false,
    );
    if (stdin != null) {
      process.stdin.write(stdin);
    }
    await process.stdin.close();
    final output = process.stdout.transform(utf8.decoder).join();
    final error = process.stderr.transform(utf8.decoder).join();
    final code = await process.exitCode;
    return CommandResult(
      exitCode: code,
      stdout: await output,
      stderr: await error,
    );
  }
}

/// True when [executable] exits 0 for `--version`.
///
/// A missing program is an expected outcome, so [ProcessException] becomes
/// false. Other failures still surface.
Future<bool> commandSucceeds(
  ProcessRunner runner,
  String executable, {
  Map<String, String>? environment,
}) async {
  try {
    final result = await runner.run(executable, const [
      '--version',
    ], environment: environment);
    return result.exitCode == 0;
  } on ProcessException {
    return false;
  }
}
