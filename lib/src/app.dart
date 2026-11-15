import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'cli/cli_args.dart';
import 'i18n/messages.dart';
import 'models/cli_exception.dart';
import 'models/os_info.dart';
import 'package_info.dart';
import 'platform/path_editor.dart';
import 'platform/paths.dart';
import 'platform/process_runner.dart';
import 'services/android_catalog.dart';
import 'services/archive_safety.dart';
import 'services/doctor_parser.dart';
import 'services/downloader.dart';
import 'services/extractor.dart';
import 'services/github_release.dart';
import 'services/http_fetcher.dart';
import 'services/jdk.dart';
import 'services/logger.dart';
import 'services/mirrors.dart';
import 'services/release_index.dart';
import 'services/storage.dart';
import 'services/templates.dart';
import 'services/versions.dart';
import 'ui/console.dart';

part 'app_setup.dart';
part 'app_maintain.dart';

/// Asks the user to confirm, unless `--yes` or `--dry-run` already decided.
Future<bool> confirmAction({
  required Console console,
  required LineReader reader,
  required Messages messages,
  required bool yes,
  required bool dryRun,
  required String prompt,
}) async {
  if (dryRun) {
    return false;
  }
  if (yes) {
    return true;
  }
  console.writeln(messages.text('confirm', {'prompt': prompt}));
  final answer = reader.readLine()?.trim().toLowerCase();
  return answer == 'y' || answer == 'yes';
}

/// Shared dependencies for commands.
final class FesApp {
  /// Creates an app with injected dependencies.
  FesApp({
    required this.console,
    required this.reader,
    required this.processes,
    required this.http,
    required this.logger,
    required this.home,
    required this.os,
    required this.executable,
    required this.workingDirectory,
    required this.sleeper,
    required this.env,
    required Map<String, String> environment,
    this.interactive = true,
  }) : sessionEnv = Map<String, String>.from(environment);

  /// Creates an app bound to the real machine.
  factory FesApp.production() {
    final environment = Map<String, String>.from(Platform.environment);
    final processes = const SystemProcessRunner();
    return FesApp(
      console: const StdConsole(),
      reader: const StdinReader(),
      processes: processes,
      http: IoHttpFetcher(environment: environment),
      logger: SetupLogger(File('flutter_setup_log.txt')),
      home: resolveHome(environment),
      os: OsInfo.current(),
      executable: Platform.resolvedExecutable,
      workingDirectory: Directory.current.path,
      sleeper: const SystemSleeper(),
      env: WindowsEnvStore(processes),
      environment: environment,
      interactive: stdin.hasTerminal,
    );
  }

  /// Text output.
  final Console console;

  /// Prompt input.
  final LineReader reader;

  /// Argument-list process runner.
  final ProcessRunner processes;

  /// HTTPS client.
  final HttpFetcher http;

  /// Error log.
  final SetupLogger logger;

  /// User home directory.
  final String home;

  /// Host OS and CPU.
  final OsInfo os;

  /// Path of the running executable.
  final String executable;

  /// Directory used by `fes create` and `.fes.yaml`.
  final String workingDirectory;

  /// Backoff sleeper.
  final Sleeper sleeper;

  /// Windows user environment.
  final EnvStore env;

  /// True when the menu may read from a terminal.
  final bool interactive;

  /// Environment passed to child processes. Install updates PATH here.
  final Map<String, String> sessionEnv;

  /// Color helper. Disabled by `--no-color`.
  Palette palette = Palette(enabled: true);

  Messages _messages = Messages('en');

  ArchiveDownloader get _downloader =>
      ArchiveDownloader(fetcher: http, sleeper: sleeper);

  /// Runs the CLI and returns an exit code.
  Future<int> run(List<String> args) async {
    final request = parseCli(args);
    palette = Palette(enabled: !request.noColor);
    _messages = Messages(request.lang ?? readSavedLang(home) ?? 'en');
    if (request.showHelp) {
      console.writeln(_messages.text('help'));
      return 0;
    }
    if (request.showVersion) {
      console.writeln(
        _messages.text('cliVersion', {'version': compiledPackageVersion}),
      );
      return 0;
    }
    return switch (request.command) {
      'menu' => _menu(request),
      'install' => _install(request, intoHome: true),
      'doctor' => _doctor(request),
      'path' => _path(request),
      'mirror' => _mirror(request),
      'list' => _list(),
      'use' => _use(request),
      'remove' => _remove(request),
      'create' => _create(request),
      'update' => _selfUpdate(request),
      'net' => _net(),
      _ => throw CliException('Unknown command: ${request.command}'),
    };
  }

  Future<int> _menu(CliRequest request) async {
    if (!interactive) {
      console.writeln(_messages.text('help'));
      return 1;
    }
    _printBanner();
    while (true) {
      console.writeln(_messages.text('select'));
      final choice = int.tryParse(reader.readLine() ?? '') ?? -1;
      try {
        final done = await _menuChoice(choice, request);
        if (done) {
          return 0;
        }
      } on CliException catch (error, stack) {
        _report(error, stack);
      } on IOException catch (error, stack) {
        _report(error, stack);
      } on FormatException catch (error, stack) {
        _report(error, stack);
      }
    }
  }

  Future<bool> _menuChoice(int choice, CliRequest request) async {
    switch (choice) {
      case 1:
        await _doctor(request);
        break;
      case 2:
        await _checkSdks();
        break;
      case 3:
        await _install(request, intoHome: true);
        break;
      case 4:
        await _upgradeFlutter(request);
        break;
      case 5:
        _guide();
        break;
      case 6:
        _about();
        break;
      case 7:
        await _toggleLanguage();
        break;
      case 0:
        console.writeln(_messages.text('goodbye'));
        return true;
      default:
        console.writeln(_messages.text('invalid'));
    }
    return false;
  }

  void _printBanner() {
    console.writeln(
      palette.cyan(
        _messages.text('banner', {'version': compiledPackageVersion}),
      ),
    );
    for (final key in [
      'opt1',
      'opt2',
      'opt3',
      'opt4',
      'opt5',
      'opt6',
      'opt7',
      'opt0',
    ]) {
      console.writeln(_messages.text(key));
    }
  }

  Future<void> _checkSdks() async {
    console.writeln(_messages.text('checking'));
    if (await commandSucceeds(processes, 'flutter', environment: sessionEnv)) {
      console.writeln(_messages.text('flutterOk'));
      console.writeln(_messages.text('dartBundled'));
    } else {
      console.writeln(_messages.text('flutterMissing'));
      _preferLocalFlutter();
      final dart = await commandSucceeds(
        processes,
        'dart',
        environment: sessionEnv,
      );
      console.writeln(_messages.text(dart ? 'dartOk' : 'dartMissing'));
    }
    final sdk = await commandSucceeds(
      processes,
      'sdkmanager',
      environment: sessionEnv,
    );
    console.writeln(_messages.text(sdk ? 'androidOk' : 'androidMissing'));
  }

  Future<void> _toggleLanguage() async {
    final next = _messages.language == 'en' ? 'fa' : 'en';
    await writeSavedLang(home, next);
    _messages = Messages(next);
    console.writeln(_messages.text('langSet', {'lang': next}));
    _printBanner();
  }

  void _guide() {
    console.writeln(_messages.text('guideTitle'));
    console.writeln(_messages.text('guideBody'));
  }

  void _about() {
    console.writeln(_messages.text('aboutTitle'));
    console.writeln(
      _messages.text('aboutVersion', {'version': compiledPackageVersion}),
    );
    console.writeln(_messages.text('aboutBody'));
  }

  PathEditor _editor() {
    return PathEditor(
      operatingSystem: os.operatingSystem,
      home: home,
      env: env,
      clock: DateTime.now,
    );
  }

  Future<void> _persistEnv(
    CliRequest request,
    Map<String, String> values,
  ) async {
    if (request.dryRun || values.isEmpty) {
      return;
    }
    await _editor().applyEnvironment(values);
  }

  Future<void> _saveMirror(CliRequest request, Mirror mirror) async {
    console.writeln(
      _messages.text('usingMirror', {'url': mirror.storage, 'id': mirror.id}),
    );
    final accepted = await confirmAction(
      console: console,
      reader: reader,
      messages: _messages,
      yes: request.yes,
      dryRun: request.dryRun,
      prompt: _messages.text('envPrompt'),
    );
    if (request.dryRun) {
      console.writeln(_messages.text('dryRun', {'url': mirror.storage}));
      return;
    }
    await writeActiveMirror(home, mirror.id);
    sessionEnv['FLUTTER_STORAGE_BASE_URL'] = mirror.storage;
    sessionEnv['PUB_HOSTED_URL'] = mirror.pubHost;
    if (accepted) {
      await _persistEnv(request, {
        'FLUTTER_STORAGE_BASE_URL': mirror.storage,
        'PUB_HOSTED_URL': mirror.pubHost,
      });
    }
    console.writeln(
      _messages.text('mirrorSaved', {
        'id': mirror.id,
        'storage': mirror.storage,
      }),
    );
  }

  void _report(Object error, StackTrace stack) {
    logger.error(error, stack);
    final message = error is CliException ? error.message : error.toString();
    console.writeln(palette.red(_messages.text('error', {'message': message})));
  }
}
