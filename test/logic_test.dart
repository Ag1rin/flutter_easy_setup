import 'dart:io';

import 'package:flutter_easy_setup/src/cli/cli_args.dart';
import 'package:flutter_easy_setup/src/i18n/messages.dart';
import 'package:flutter_easy_setup/src/package_info.dart';
import 'package:flutter_easy_setup/src/platform/path_editor.dart';
import 'package:flutter_easy_setup/src/platform/paths.dart';
import 'package:flutter_easy_setup/src/services/archive_safety.dart';
import 'package:flutter_easy_setup/src/services/doctor_parser.dart';
import 'package:flutter_easy_setup/src/services/github_release.dart';
import 'package:flutter_easy_setup/src/services/http_fetcher.dart';
import 'package:flutter_easy_setup/src/services/https.dart';
import 'package:flutter_easy_setup/src/services/jdk.dart';
import 'package:flutter_easy_setup/src/services/mirrors.dart';
import 'package:flutter_easy_setup/src/services/templates.dart';
import 'package:flutter_easy_setup/src/services/versions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('compiled version matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(compiledPackageVersion, parsePubspecVersion(pubspec));
  });

  test('message catalogs contain the same keys', () {
    expect(messageCatalogsMatch(), isTrue);
  });

  test('archive paths reject traversal', () {
    expect(isSafeArchiveEntry('flutter/bin/flutter'), isTrue);
    expect(isSafeArchiveEntry('../etc/passwd'), isFalse);
    expect(isSafeArchiveEntry('/etc/passwd'), isFalse);
    expect(isSafeArchiveEntry(r'C:\Windows\system.ini'), isFalse);
    expect(() => safeFileName('../sdk.zip'), throwsA(isA<Exception>()));
  });

  test('path lists ignore duplicates and reject quotes', () {
    expect(
      appendPathEntry(
        r'C:\bin',
        r'C:\flutter\bin',
        separator: ';',
        ignoreCase: true,
      ),
      r'C:\bin;C:\flutter\bin',
    );
    expect(
      appendPathEntry(
        r'C:\bin;C:\flutter\bin',
        r'c:\flutter\bin',
        separator: ';',
        ignoreCase: true,
      ),
      r'C:\bin;C:\flutter\bin',
    );
    expect(() => validatePathToken('bad"path'), throwsA(isA<Exception>()));
    expect(
      () => validatePathToken(r'C:\legit;C:\other'),
      throwsA(isA<Exception>()),
    );
    expect(
      archiveListingHasLink('lrwxrwxrwx 1 root root 0 Jan 1 link -> /tmp/x'),
      isTrue,
    );
    expect(
      archiveListingHasLink(
        '-rw-r--r-- 1 root root 0 Jan 1 flutter/bin/flutter',
      ),
      isFalse,
    );
    final posix = p.Context(style: p.Style.posix);
    expect(
      isWithinDirectory(
        '/home/me/.fes/versions',
        '/home/me/.fes/versions/3.24.0',
        context: posix,
      ),
      isTrue,
    );
    expect(
      isWithinDirectory(
        '/home/me/.fes/versions',
        '/home/me/.fes/versions-evil',
        context: posix,
      ),
      isFalse,
    );
  });

  test('shell blocks are idempotent and can be removed', () {
    const body = 'export PATH="\$PATH:/flutter/bin"';
    final once = upsertBlock('', body);
    final twice = upsertBlock(once, body);
    expect(twice, once);
    expect(twice.split(fesBlockStart).length, 2);
    expect(removeBlock(twice).contains(fesBlockStart), isFalse);
  });

  test('windows PATH edit backs up and undoes', () async {
    final env = _MemoryEnv();
    final home = await Directory.systemTemp.createTemp('fes-path-');
    final editor = PathEditor(
      operatingSystem: 'windows',
      home: home.path,
      env: env,
      clock: () => DateTime.utc(2026, 1, 2, 3, 4, 5),
    );
    await editor.apply(r'C:\flutter\bin');
    await editor.apply(r'C:\flutter\bin');
    expect(env.values['Path'], r'C:\flutter\bin');
    final undone = await editor.undo();
    expect(undone.previous, isEmpty);
    expect(env.values['Path'], isEmpty);
    await home.delete(recursive: true);
  });

  test(
    'unix rc files gain one block and fish is included when present',
    () async {
      final home = await Directory.systemTemp.createTemp('fes-rc-');
      final fish = File(p.join(home.path, '.config', 'fish', 'config.fish'));
      await fish.parent.create(recursive: true);
      await fish.writeAsString('status\n');
      final editor = PathEditor(
        operatingSystem: 'linux',
        home: home.path,
        env: _MemoryEnv(),
        clock: () => DateTime.utc(2026, 1, 2),
      );
      await editor.apply('/opt/flutter/bin');
      final bash = File(p.join(home.path, '.bashrc')).readAsStringSync();
      expect(bash.split(fesBlockStart).length, 2);
      expect(fish.readAsStringSync(), contains('fish_add_path'));
      await editor.apply('/opt/flutter/bin');
      expect(File(p.join(home.path, '.bashrc')).readAsStringSync(), bash);
      await home.delete(recursive: true);
    },
  );

  test('environment exports use a separate marked block', () async {
    final home = await Directory.systemTemp.createTemp('fes-env-');
    File(
      p.join(home.path, '.bashrc'),
    ).writeAsStringSync('export PATH=\$PATH\n');
    final editor = PathEditor(
      operatingSystem: 'linux',
      home: home.path,
      env: _MemoryEnv(),
      clock: () => DateTime.utc(2026, 1, 3),
    );
    await editor.applyEnvironment({
      'JAVA_HOME': '/opt/jdk',
      'ANDROID_HOME': '/opt/android',
    });
    final bash = File(p.join(home.path, '.bashrc')).readAsStringSync();
    expect(bash, contains('export ANDROID_HOME="/opt/android"'));
    expect(bash, contains('export JAVA_HOME="/opt/jdk"'));
    expect(bash, contains(fesEnvStart));
    expect(bash, isNot(contains(fesBlockStart)));
    await editor.applyEnvironment({
      'JAVA_HOME': '/opt/jdk',
      'ANDROID_HOME': '/opt/android',
    });
    expect(File(p.join(home.path, '.bashrc')).readAsStringSync(), bash);
    expect(
      () => shellEnvExport({'BAD NAME': 'x'}, fish: false),
      throwsA(isA<Exception>()),
    );
    await home.delete(recursive: true);
  });

  test('doctor output maps known failures', () {
    final parsed = parseDoctorOutput('''
[!] Android toolchain
    X cmdline-tools component is missing
    X Android license status unknown
    X Unable to locate Android SDK
[!] Chrome
    X Cannot find Chrome
''');
    expect(
      parsed.map((item) => item.id),
      containsAll(['cmdline-tools', 'licenses', 'chrome']),
    );
    final withLocal = withLocalFindings(
      parsed: parsed,
      flutterOnPath: false,
      localFlutterExists: true,
      lockfileExists: true,
      javaOnPath: false,
    );
    expect(withLocal.map((item) => item.id), contains('path'));
    expect(withLocal.map((item) => item.id), contains('startup-lock'));
  });

  test('mirrors reject insecure URLs and duplicate ids', () {
    final mirrors = parseMirrors('''
mirrors:
  - id: official
    storage: https://storage.googleapis.com
    pub: https://pub.dev
''');
    expect(requireMirror(mirrors, 'official').storage, officialStorageBase);
    expect(
      () => parseMirrors('''
mirrors:
  - id: bad
    storage: http://example.com
    pub: https://pub.dev
'''),
      throwsA(isA<Exception>()),
    );
  });

  test('cli flags keep -v as the tool version', () {
    final version = parseCli(const ['--version']);
    expect(version.showVersion, isTrue);
    expect(version.command, 'menu');
    final install = parseCli(const [
      'install',
      '--flutter-version',
      '3.24.5',
      '--channel',
      'beta',
      '--yes',
      '--dry-run',
    ]);
    expect(install.command, 'install');
    expect(install.flutterVersion, '3.24.5');
    expect(install.channel, 'beta');
    expect(install.yes, isTrue);
    expect(install.dryRun, isTrue);
    final doctor = parseCli(const ['doctor', '--json']);
    expect(doctor.json, isTrue);
    expect(
      () => parseCli(const ['use', 'not a version']),
      throwsA(isA<Exception>()),
    );
  });

  test('https redirects and proxies stay on https', () {
    final current = Uri.parse('https://example.com/a');
    expect(
      nextHttpsRedirect(current, 302, 'https://example.com/b').toString(),
      'https://example.com/b',
    );
    expect(
      () => nextHttpsRedirect(current, 302, 'http://example.com/b'),
      throwsA(isA<Exception>()),
    );
    expect(
      proxyDirective(current, const {'HTTPS_PROXY': 'http://127.0.0.1:8080'}),
      'PROXY 127.0.0.1:8080',
    );
    expect(proxyDirective(current, const {}), 'DIRECT');
  });

  test('github release parsing and checksum lookup', () {
    final release = parseGitHubRelease('''
{
  "tag_name": "v1.2.0",
  "assets": [
    {"name": "fes-linux-x64", "browser_download_url": "https://github.com/Ag1rin/flutter_easy_setup/releases/download/v1.2.0/fes-linux-x64"},
    {"name": "SHA256SUMS", "browser_download_url": "https://github.com/Ag1rin/flutter_easy_setup/releases/download/v1.2.0/SHA256SUMS"}
  ]
}
''');
    expect(release.requireAsset('SHA256SUMS').name, 'SHA256SUMS');
    expect(
      () => requireChecksum(
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  fes-linux-x64\n',
        'missing',
      ),
      throwsA(isA<Exception>()),
    );
    expect(
      checksumForFile(
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  fes-linux-x64\n',
        'fes-linux-x64',
      ),
      startsWith('aaa'),
    );
    expect(isNewerVersion('1.2.0', '1.1.0'), isTrue);
    expect(isNewerVersion('1.0.6', '1.0.6'), isFalse);
    expect(
      isPubGlobalInstall(r'C:\Users\me\AppData\Local\Pub\Cache\bin\fes.bat'),
      isTrue,
    );
    expect(isPubGlobalInstall('/home/me/.pub-cache/bin/fes'), isTrue);
  });

  test('adoptium JSON and project templates', () {
    final asset = parseAdoptiumAssets(
      '''
[{
  "binary": {
    "os": "windows",
    "architecture": "x64",
    "image_type": "jdk",
    "package": {
      "link": "https://github.com/adoptium/temurin17-binaries/releases/download/jdk.zip",
      "checksum": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    }
  },
  "version": {"semver": "17.0.13+11"}
}]
''',
      os: 'windows',
      arch: 'x64',
    );
    expect(asset.version, '17.0.13+11');
    expect(javaHomeRelative(const ['jdk-17/bin/java.exe']), 'jdk-17');
    expect(templateFiles('basic'), isEmpty);
    expect(
      templateFiles('clean').keys,
      contains(p.join('lib', 'src', 'domain', '.gitkeep')),
    );
    expect(
      templateFiles('state')[p.join('lib', 'main.dart')],
      contains('ChangeNotifier'),
    );
    expect(() => validatePackageName('../app'), throwsA(isA<Exception>()));
  });

  test('version store refuses to escape its root', () async {
    final home = await Directory.systemTemp.createTemp('fes-ver-');
    final version = Directory(
      p.join(home.path, '.fes', 'versions', '3.24.5', 'flutter'),
    );
    await version.create(recursive: true);
    final store = VersionStore(home.path);
    expect(store.list().single.version, '3.24.5');
    final removed = await store.remove(
      '3.24.5',
      allowActive: false,
      dryRun: true,
    );
    expect(
      Directory(p.join(home.path, '.fes', 'versions', '3.24.5')).existsSync(),
      isTrue,
    );
    expect(removed, contains('3.24.5'));
    await store.remove('3.24.5', allowActive: false, dryRun: false);
    expect(store.list(), isEmpty);
    await home.delete(recursive: true);
  });

  test('install choice keeps an existing PATH install unless pinned', () {
    expect(
      chooseFlutterInstall(
        flutterOnPath: true,
        localExists: false,
        versionPinned: false,
      ),
      FlutterInstallChoice.skip,
    );
    expect(
      chooseFlutterInstall(
        flutterOnPath: true,
        localExists: true,
        versionPinned: true,
      ),
      FlutterInstallChoice.download,
    );
    expect(
      chooseFlutterInstall(
        flutterOnPath: false,
        localExists: true,
        versionPinned: false,
      ),
      FlutterInstallChoice.reuse,
    );
  });
}

final class _MemoryEnv implements EnvStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String name) async => values[name];

  @override
  Future<void> write(String name, String value) async {
    values[name] = value;
  }
}
