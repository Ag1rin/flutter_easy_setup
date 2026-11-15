import 'package:args/args.dart';

import '../models/cli_exception.dart';
import '../models/cpu_arch.dart';
import '../services/release_index.dart';

/// Parsed command line.
final class CliRequest {
  /// Creates a parsed request.
  const CliRequest({
    required this.showVersion,
    required this.showHelp,
    required this.noColor,
    required this.quiet,
    required this.verbose,
    required this.yes,
    required this.dryRun,
    required this.json,
    required this.lang,
    required this.command,
    required this.flutterVersion,
    required this.channel,
    required this.arch,
    required this.undo,
    required this.rest,
    required this.template,
  });

  /// `-v` / `--version`.
  final bool showVersion;

  /// `-h` / `--help`.
  final bool showHelp;

  /// Disable ANSI colors.
  final bool noColor;

  /// Hide progress text.
  final bool quiet;

  /// Print command details.
  final bool verbose;

  /// Skip confirmation prompts.
  final bool yes;

  /// Print actions without writing or downloading.
  final bool dryRun;

  /// Machine-readable doctor output.
  final bool json;

  /// `en`, `fa`, or null to use the saved language.
  final String? lang;

  /// `menu` or a subcommand name.
  final String command;

  /// Pinned Flutter version for `install` or `use`.
  final String? flutterVersion;

  /// `stable` or `beta`.
  final String channel;

  /// Optional architecture override.
  final CpuArch? arch;

  /// `fes path --undo`.
  final bool undo;

  /// Positional arguments for the subcommand.
  final List<String> rest;

  /// `basic`, `state`, or `clean`.
  final String template;
}

/// Parses [args]. Throws [CliException] for invalid input.
CliRequest parseCli(List<String> args) {
  final parser = _parser();
  final ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (error) {
    throw CliException(error.message);
  }
  final command = results.command;
  final name = command?.name ?? 'menu';
  final flutterVersion =
      _option(command, 'flutter-version') ?? _firstRest(command, name);
  if (flutterVersion != null && (name == 'install' || name == 'use')) {
    validateFlutterVersion(flutterVersion);
  }
  final archName = _option(command, 'arch');
  return CliRequest(
    showVersion: _flag(results, 'version'),
    showHelp: _flag(results, 'help'),
    noColor: _flag(results, 'no-color'),
    quiet: _flag(results, 'quiet'),
    verbose: _flag(results, 'verbose'),
    yes: _flag(results, 'yes'),
    dryRun: _flag(results, 'dry-run'),
    json: _flag(results, 'json'),
    lang: results.option('lang'),
    command: name,
    flutterVersion: name == 'install' || name == 'use' ? flutterVersion : null,
    channel: _option(command, 'channel') ?? 'stable',
    arch: archName == null ? null : parseCpuArch(archName),
    undo: _commandFlag(command, 'undo'),
    rest: command?.rest ?? const [],
    template: _option(command, 'template') ?? 'basic',
  );
}

/// Usage text for `--help`.
String cliUsage() => _parser().usage;

ArgParser _parser() {
  final parser = ArgParser()
    ..addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Show the CLI version',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage')
    ..addFlag('no-color', negatable: false, help: 'Disable color')
    ..addFlag('quiet', abbr: 'q', negatable: false, help: 'Hide progress')
    ..addFlag('verbose', negatable: false, help: 'Show command details')
    ..addFlag('yes', abbr: 'y', negatable: false, help: 'Accept prompts')
    ..addFlag('dry-run', negatable: false, help: 'Print actions only')
    ..addFlag('json', negatable: false, help: 'Print JSON where supported')
    ..addOption('lang', allowed: ['en', 'fa'], help: 'en or fa');
  final install = parser.addCommand('install')
    ..addOption('flutter-version', help: 'Flutter version to install')
    ..addOption('channel', allowed: ['stable', 'beta'], defaultsTo: 'stable')
    ..addOption('arch', allowed: ['x64', 'arm64'], help: 'Override CPU arch');
  _shared(install);
  _shared(parser.addCommand('doctor'));
  _shared(parser.addCommand('path')..addFlag('undo', negatable: false));
  parser.addCommand('mirror');
  parser.addCommand('list');
  parser.addCommand('use');
  _shared(parser.addCommand('remove'));
  _shared(
    parser.addCommand('create')..addOption(
      'template',
      allowed: ['basic', 'state', 'clean'],
      defaultsTo: 'basic',
    ),
  );
  _shared(parser.addCommand('update'));
  parser.addCommand('net');
  return parser;
}

void _shared(ArgParser parser) {
  parser
    ..addFlag('yes', abbr: 'y', negatable: false)
    ..addFlag('dry-run', negatable: false)
    ..addFlag('json', negatable: false);
}

String? _option(ArgResults? results, String name) {
  if (results == null || !results.options.contains(name)) {
    return null;
  }
  return results.option(name);
}

bool _commandFlag(ArgResults? results, String name) {
  if (results == null || !results.options.contains(name)) {
    return false;
  }
  return results.flag(name);
}

bool _flag(ArgResults results, String name) {
  final command = results.command;
  if (command != null && command.options.contains(name) && command.flag(name)) {
    return true;
  }
  if (results.options.contains(name)) {
    return results.flag(name);
  }
  return false;
}

String? _firstRest(ArgResults? command, String name) {
  if (command == null) {
    return null;
  }
  if (name != 'use' && name != 'install') {
    return null;
  }
  if (command.rest.isEmpty) {
    return null;
  }
  return command.rest.first;
}
