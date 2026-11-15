import 'dart:io';

import 'package:flutter_easy_setup/src/i18n/messages.dart';
import 'package:flutter_easy_setup/src/models/cli_exception.dart';
import 'package:flutter_easy_setup/src/models/cpu_arch.dart';
import 'package:flutter_easy_setup/src/models/os_info.dart';
import 'package:flutter_easy_setup/src/platform/paths.dart';
import 'package:flutter_easy_setup/src/platform/process_runner.dart';
import 'package:flutter_easy_setup/src/services/android_catalog.dart';
import 'package:flutter_easy_setup/src/services/jdk.dart';
import 'package:flutter_easy_setup/src/services/logger.dart';
import 'package:flutter_easy_setup/src/services/mirrors.dart';
import 'package:flutter_easy_setup/src/services/storage.dart';
import 'package:flutter_easy_setup/src/services/versions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('host info and process runner stay on an argument list', () async {
    expect(currentCpuArch(), isA<CpuArch>());
    expect(parseCpuArch('arm64'), CpuArch.arm64);
    expect(() => parseCpuArch('ia32'), throwsA(isA<CliException>()));
    expect(OsInfo.current().operatingSystem, Platform.operatingSystem);
    expect(() => normalizeOs('fuchsia'), throwsA(isA<CliException>()));
    final runner = const SystemProcessRunner();
    final version = await runner.run(Platform.resolvedExecutable, const [
      '--version',
    ]);
    expect(version.exitCode, 0);
    final script = File(
      p.join(Directory.systemTemp.path, 'fes_stdin_echo.dart'),
    );
    await script.writeAsString(
      "import 'dart:io'; void main() { stdout.write(stdin.readLineSync()); }",
    );
    final echoed = await runner.run(Platform.resolvedExecutable, [
      script.path,
    ], stdin: 'fes-ok\n');
    expect(echoed.stdout, 'fes-ok');
    await script.delete();
    expect(await commandSucceeds(runner, 'this-fes-tool-is-missing'), isFalse);
    expect(const DownloadException('offline').exitCode, 2);
  });

  test('messages replace placeholders', () {
    expect(
      Messages('en').text('banner', {'version': '9.9.9'}),
      contains('9.9.9'),
    );
    expect(Messages('fa').text('opt0'), contains('0'));
    expect(() => Messages('en').text('missing-key'), throwsStateError);
    expect(() => Messages('de'), throwsArgumentError);
  });

  test('mirror config round trip keeps the language', () async {
    final home = await Directory.systemTemp.createTemp('fes-mirror-');
    expect(loadMirrors(home.path).map((item) => item.id), contains('china'));
    expect(activeMirrorId(home.path), 'official');
    await writeSavedLang(home.path, 'fa');
    await writeActiveMirror(home.path, 'china');
    expect(activeMirrorId(home.path), 'china');
    expect(readSavedLang(home.path), 'fa');
    expect(
      resolveStorageBase(environment: const {}, home: home.path),
      'https://storage.flutter-io.cn',
    );
    expect(
      resolvePubHost(environment: const {}, home: home.path),
      'https://pub.flutter-io.cn',
    );
    expect(
      () => parseMirrors(
        'mirrors:\n  - id: A\n    storage: https://a.example\n    pub: https://b.example\n',
      ),
      throwsA(isA<CliException>()),
    );
    expect(() => writeSavedLang(home.path, 'de'), throwsA(isA<CliException>()));
    await home.delete(recursive: true);
  });

  test('version store lists and removes a local SDK', () async {
    final home = await Directory.systemTemp.createTemp('fes-versions-');
    final project = await Directory.systemTemp.createTemp('fes-project-');
    File(
      p.join(project.path, '.fes.yaml'),
    ).writeAsStringSync('flutter: 3.24.5\n');
    expect(readProjectFlutterVersion(project.path), '3.24.5');
    final flutterHome = Directory(
      p.join(VersionStore(home.path).root, '3.24.5', 'flutter'),
    );
    await flutterHome.create(recursive: true);
    final listed = VersionStore(home.path).list();
    expect(listed.single.version, '3.24.5');
    expect(listed.single.active, isFalse);
    final removed = await VersionStore(
      home.path,
    ).remove('3.24.5', allowActive: false, dryRun: true);
    expect(Directory(removed).existsSync(), isTrue);
    await VersionStore(
      home.path,
    ).remove('3.24.5', allowActive: false, dryRun: false);
    expect(Directory(removed).existsSync(), isFalse);
    expect(
      defaultAndroidSdk(
        home: home.path,
        operatingSystem: 'windows',
        environment: const {'LOCALAPPDATA': r'C:\Users\me\AppData\Local'},
      ),
      contains('Android'),
    );
    expect(
      () => defaultAndroidSdk(
        home: home.path,
        operatingSystem: 'linux',
        environment: const {'ANDROID_HOME': 'bad;path'},
      ),
      throwsA(isA<CliException>()),
    );
    await home.delete(recursive: true);
    await project.delete(recursive: true);
  });

  test('path helpers, logger, jdk, and android catalog', () async {
    expect(
      appendPathEntry('', r'C:\flutter\bin', separator: ';', ignoreCase: true),
      r'C:\flutter\bin',
    );
    expect(
      appendPathEntry(
        r'C:\flutter\bin',
        r'C:\Flutter\bin',
        separator: ';',
        ignoreCase: true,
      ),
      r'C:\flutter\bin',
    );
    expect(resolveHome(const {'USERPROFILE': r'C:\Users\me'}), r'C:\Users\me');
    expect(
      () => resolveHome(const {'HOME': '~'}),
      throwsA(isA<CliException>()),
    );
    final log = File(p.join(Directory.systemTemp.path, 'fes-log-test.txt'));
    if (log.existsSync()) {
      await log.delete();
    }
    SetupLogger(log).error('boom', StackTrace.current);
    expect(log.readAsStringSync(), contains('boom'));
    await log.delete();
    expect(javaHomeRelative(const ['jdk-17/bin/java.exe']), 'jdk-17');
    expect(javaHomeRelative(const ['readme']), isNull);
    expect(adoptiumOs('macos'), 'mac');
    expect(() => adoptiumOs('solaris'), throwsA(isA<CliException>()));
    expect(
      () => parseAdoptiumAssets('[]', os: 'windows', arch: 'x64'),
      throwsA(isA<CliException>()),
    );
    final tools = androidToolsFor(
      operatingSystem: 'windows',
      arch: CpuArch.x64,
    );
    expect(tools.url.scheme, 'https');
    expect(
      sdkManagerPath(
        sdkRoot: r'C:\Sdk',
        operatingSystem: 'windows',
        separator: r'\',
      ),
      contains('sdkmanager.bat'),
    );
    expect(
      () => androidToolsFor(operatingSystem: 'windows', arch: CpuArch.arm64),
      throwsA(isA<CliException>()),
    );
  });
}
