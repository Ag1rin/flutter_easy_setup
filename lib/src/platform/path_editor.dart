import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/cli_exception.dart';
import 'paths.dart';
import 'process_runner.dart';

/// Start of a block this CLI owns inside a shell rc file.
const fesBlockStart = '# >>> fes >>>';

/// End of a block this CLI owns inside a shell rc file.
const fesBlockEnd = '# <<< fes <<<';

/// Start of the environment block this CLI owns.
const fesEnvStart = '# >>> fes env >>>';

/// End of the environment block this CLI owns.
const fesEnvEnd = '# <<< fes env <<<';

/// Planned PATH or rc-file edit.
final class PathEditPlan {
  /// Creates a plan.
  const PathEditPlan({
    required this.target,
    required this.alreadyPresent,
    required this.preview,
  });

  /// `Path` or an rc file path.
  final String target;

  /// True when the Flutter bin directory is already configured.
  final bool alreadyPresent;

  /// Text that would be written.
  final String preview;
}

/// A backup written before a PATH edit.
final class PathBackup {
  /// Creates a backup record.
  const PathBackup({
    required this.kind,
    required this.target,
    required this.previous,
    required this.created,
  });

  /// `env` or `file`.
  final String kind;

  /// Environment variable or file path.
  final String target;

  /// Previous contents. Empty when the file did not exist.
  final String previous;

  /// True when this tool created the file.
  final bool created;

  /// Serializes the backup.
  Map<String, Object?> toJson() => {
    'kind': kind,
    'target': target,
    'previous': previous,
    'created': created,
  };

  /// Reads a backup written by [toJson].
  factory PathBackup.fromJson(Object? source) {
    if (source is! Map) {
      throw const CliException('PATH backup is not a JSON object.');
    }
    final json = Map<String, Object?>.from(source);
    final kind = json['kind'];
    final target = json['target'];
    final previous = json['previous'];
    final created = json['created'];
    if (kind is! String ||
        target is! String ||
        previous is! String ||
        created is! bool ||
        (kind != 'env' && kind != 'file')) {
      throw const CliException('PATH backup is incomplete.');
    }
    return PathBackup(
      kind: kind,
      target: target,
      previous: previous,
      created: created,
    );
  }
}

/// Reads and writes one user environment variable.
abstract interface class EnvStore {
  /// Returns the user-level value, or null when it is unset.
  Future<String?> read(String name);

  /// Sets the user-level value.
  Future<void> write(String name, String value);
}

/// Windows user environment via a fixed PowerShell command.
final class WindowsEnvStore implements EnvStore {
  /// Creates a store that passes values through environment variables.
  const WindowsEnvStore(this.processes);

  /// Process runner.
  final ProcessRunner processes;

  @override
  Future<String?> read(String name) async {
    final result = await processes.run('powershell', const [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      r'[Environment]::GetEnvironmentVariable($env:FES_VAR, "User")',
    ], environment: _baseEnv(name));
    if (result.exitCode != 0) {
      throw CliException(
        'Could not read the user PATH: ${result.stderr}',
        exitCode: 2,
      );
    }
    final value = result.stdout.trimRight();
    return value.isEmpty ? null : value;
  }

  @override
  Future<void> write(String name, String value) async {
    final file = File(
      p.join(Directory.systemTemp.path, 'fes-env-${name.hashCode}.txt'),
    );
    await file.writeAsString(value);
    try {
      final result = await processes.run(
        'powershell',
        const [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          r'$value = Get-Content -Raw -LiteralPath $env:FES_FILE; '
              r'[Environment]::SetEnvironmentVariable($env:FES_VAR, $value, "User")',
        ],
        environment: {..._baseEnv(name), 'FES_FILE': file.path},
      );
      if (result.exitCode != 0) {
        throw CliException(
          'Could not update the user PATH: ${result.stderr}',
          exitCode: 2,
        );
      }
    } finally {
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

  Map<String, String> _baseEnv(String name) {
    return {...Platform.environment, 'FES_VAR': name};
  }
}

/// Inserts or removes one marked shell block.
String upsertBlock(String existing, String body) {
  return upsertNamedBlock(existing, fesBlockStart, fesBlockEnd, body);
}

/// Inserts or replaces a marked block identified by [start] and [end].
String upsertNamedBlock(
  String existing,
  String start,
  String end,
  String body,
) {
  final block = '$start\n$body\n$end\n';
  final pattern = RegExp(
    '${RegExp.escape(start)}.*?${RegExp.escape(end)}\\n?',
    dotAll: true,
  );
  if (pattern.hasMatch(existing)) {
    return existing.replaceFirst(pattern, block);
  }
  final separator = existing.isEmpty || existing.endsWith('\n') ? '' : '\n';
  return '$existing$separator$block';
}

/// Removes the marked shell block.
String removeBlock(String existing) {
  return removeNamedBlock(existing, fesBlockStart, fesBlockEnd);
}

/// Removes one marked block.
String removeNamedBlock(String existing, String start, String end) {
  final pattern = RegExp(
    '\\n?${RegExp.escape(start)}.*?${RegExp.escape(end)}\\n?',
    dotAll: true,
  );
  return existing.replaceFirst(pattern, '\n');
}

/// Shell lines that export [values]. Names and values are checked first.
String shellEnvExport(Map<String, String> values, {required bool fish}) {
  final lines = <String>[];
  final keys = values.keys.toList()..sort();
  for (final key in keys) {
    if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key)) {
      throw CliException('Refusing environment name $key.');
    }
    final value = values[key]!;
    validatePathToken(value);
    lines.add(fish ? 'set -gx $key "$value"' : 'export $key="$value"');
  }
  return lines.join('\n');
}

/// Shell line that prepends nothing and appends [flutterBin] idempotently.
String shellExport(String flutterBin, {required bool fish}) {
  validatePathToken(flutterBin);
  if (fish) {
    return 'fish_add_path --path "$flutterBin"';
  }
  return 'export PATH="\$PATH:$flutterBin"';
}

/// Edits the user PATH or shell startup files, with backups.
final class PathEditor {
  /// Creates an editor.
  PathEditor({
    required this.operatingSystem,
    required this.home,
    required this.env,
    required this.clock,
  });

  /// `windows`, `macos`, or `linux`.
  final String operatingSystem;

  /// User home directory.
  final String home;

  /// Windows user environment. Unused on Unix.
  final EnvStore env;

  /// Clock used for backup file names.
  final DateTime Function() clock;

  /// Describes the edit without writing it.
  Future<List<PathEditPlan>> plan(String flutterBin) async {
    validatePathToken(flutterBin);
    if (operatingSystem == 'windows') {
      final current = await env.read('Path') ?? '';
      final next = appendPathEntry(
        current,
        flutterBin,
        separator: ';',
        ignoreCase: true,
      );
      return [
        PathEditPlan(
          target: 'Path',
          alreadyPresent: next == current,
          preview: next,
        ),
      ];
    }
    return [
      for (final file in _rcFiles())
        _filePlan(file, _bodyFor(file, flutterBin)),
    ];
  }

  /// Writes the edit after the caller has confirmed it.
  Future<List<String>> apply(String flutterBin) async {
    final plans = await plan(flutterBin);
    final backups = <String>[];
    for (final item in plans) {
      if (item.alreadyPresent) {
        continue;
      }
      backups.add(await _writeBackup(item));
      if (item.target == 'Path') {
        await env.write('Path', item.preview);
      } else {
        final file = File(item.target);
        await file.parent.create(recursive: true);
        await file.writeAsString(item.preview);
      }
    }
    return backups;
  }

  /// Writes user environment variables after the caller has confirmed it.
  Future<void> applyEnvironment(Map<String, String> values) async {
    if (values.isEmpty) {
      return;
    }
    if (operatingSystem == 'windows') {
      for (final entry in values.entries) {
        if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(entry.key)) {
          throw CliException('Refusing environment name ${entry.key}.');
        }
        validatePathToken(entry.value);
        final current = await env.read(entry.key);
        if (current == entry.value) {
          continue;
        }
        final plan = PathEditPlan(
          target: entry.key,
          alreadyPresent: false,
          preview: entry.value,
        );
        await _writeBackup(plan);
        await env.write(entry.key, entry.value);
      }
      return;
    }
    for (final file in _rcFiles()) {
      final text = shellEnvExport(values, fish: file.endsWith('config.fish'));
      final existing = File(file).existsSync()
          ? File(file).readAsStringSync()
          : '';
      final next = upsertNamedBlock(existing, fesEnvStart, fesEnvEnd, text);
      if (next == existing) {
        continue;
      }
      await _writeBackup(
        PathEditPlan(target: file, alreadyPresent: false, preview: next),
      );
      final target = File(file);
      await target.parent.create(recursive: true);
      await target.writeAsString(next);
    }
  }

  /// Restores the newest backup.
  Future<PathBackup> undo() async {
    final backup = _newestBackup();
    final record = PathBackup.fromJson(jsonDecode(backup.readAsStringSync()));
    if (record.kind == 'env') {
      await env.write(record.target, record.previous);
    } else if (record.created && record.previous.isEmpty) {
      final file = File(record.target);
      if (file.existsSync()) {
        await file.delete();
      }
    } else {
      await File(record.target).writeAsString(record.previous);
    }
    return record;
  }

  PathEditPlan _filePlan(String path, String body) {
    final file = File(path);
    final existing = file.existsSync() ? file.readAsStringSync() : '';
    return PathEditPlan(
      target: path,
      alreadyPresent: existing.contains(body),
      preview: upsertBlock(existing, body),
    );
  }

  String _bodyFor(String path, String flutterBin) {
    return shellExport(flutterBin, fish: path.endsWith('config.fish'));
  }

  List<String> _rcFiles() {
    final files = <String>[p.join(home, '.bashrc'), p.join(home, '.zshrc')];
    final fish = p.join(home, '.config', 'fish', 'config.fish');
    if (File(fish).existsSync()) {
      files.add(fish);
    }
    return files;
  }

  Future<String> _writeBackup(PathEditPlan plan) async {
    final isEnv = _isEnvTarget(plan.target);
    final created = !isEnv && !File(plan.target).existsSync();
    final previous = isEnv
        ? (await env.read(plan.target) ?? '')
        : (File(plan.target).existsSync()
              ? File(plan.target).readAsStringSync()
              : '');
    final record = PathBackup(
      kind: isEnv ? 'env' : 'file',
      target: plan.target,
      previous: previous,
      created: created,
    );
    final directory = Directory(p.join(fesRoot(home), 'backups'));
    await directory.create(recursive: true);
    final safeTarget = plan.target.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final name = '${clock().toUtc().microsecondsSinceEpoch}-$safeTarget.json';
    final file = File(p.join(directory.path, name));
    await file.writeAsString(jsonEncode(record.toJson()));
    return file.path;
  }

  File _newestBackup() {
    final directory = Directory(p.join(fesRoot(home), 'backups'));
    if (!directory.existsSync()) {
      throw const CliException('No PATH backup exists to undo.');
    }
    final files =
        directory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => _backupStamp(b).compareTo(_backupStamp(a)));
    if (files.isEmpty) {
      throw const CliException('No PATH backup exists to undo.');
    }
    return files.first;
  }
}

int _backupStamp(File file) {
  final prefix = p.basename(file.path).split('-').first;
  return int.tryParse(prefix) ?? 0;
}

bool _isEnvTarget(String target) {
  return !target.contains('/') && !target.contains('\\');
}
