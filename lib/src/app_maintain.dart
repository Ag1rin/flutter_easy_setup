part of 'app.dart';

extension FesMaintain on FesApp {
  Future<int> _doctor(CliRequest request) async {
    console.writeln(_messages.text('doctorRunning'));
    final result = await processes.run('flutter', const [
      'doctor',
      '-v',
    ], environment: sessionEnv);
    if (!request.json) {
      console.writeln(result.stdout);
      if (result.stderr.isNotEmpty) {
        console.writeln(result.stderr);
      }
    }
    final findings = withLocalFindings(
      parsed: parseDoctorOutput(result.stdout),
      flutterOnPath: await commandSucceeds(
        processes,
        'flutter',
        environment: sessionEnv,
      ),
      localFlutterExists: Directory(defaultFlutterHome(home)).existsSync(),
      lockfileExists: File(
        p.join(defaultFlutterHome(home), 'bin', 'cache', 'lockfile'),
      ).existsSync(),
      javaOnPath: await commandSucceeds(
        processes,
        'java',
        environment: sessionEnv,
      ),
    );
    if (request.json) {
      console.writeln(
        jsonEncode({
          'ok': findings.isEmpty,
          'findings': [for (final item in findings) item.toJson()],
        }),
      );
      return findings.isEmpty ? 0 : 2;
    }
    for (final finding in findings) {
      console.writeln(
        _messages.text('finding', {
          'id': finding.id,
          'summary': finding.summary,
        }),
      );
      if (finding.fix == null) {
        continue;
      }
      final accepted = await confirmAction(
        console: console,
        reader: reader,
        messages: _messages,
        yes: request.yes,
        dryRun: request.dryRun,
        prompt: _messages.text('fixAsk', {'fix': finding.fix!}),
      );
      if (!accepted) {
        console.writeln(_messages.text('fixSkip', {'fix': finding.fix!}));
        continue;
      }
      await _applyFix(finding.fix!, request);
    }
    console.writeln(_messages.text('doctorDone'));
    return findings.isEmpty ? 0 : 2;
  }

  Future<void> _applyFix(String fix, CliRequest request) async {
    switch (fix) {
      case 'install-flutter':
        await _downloadFlutter(request, version: null, destinationParent: home);
        break;
      case 'configure-path':
        await _maybePath(request, flutterBinPath(defaultFlutterHome(home)));
        break;
      case 'install-android':
      case 'accept-licenses':
        await _installAndroid(request);
        break;
      case 'install-jdk':
        await _maybeJdk(request);
        break;
      case 'remove-lock':
        await _removeLock(request);
        break;
      case 'install-chrome':
        console.writeln(_messages.text('chromeHint'));
        break;
      case 'install-visual-studio':
        console.writeln(_messages.text('vsHint'));
        break;
      case 'install-linux-desktop':
        await _runConfirmed(request, 'sudo', const [
          'apt-get',
          'install',
          '-y',
          'clang',
          'cmake',
          'ninja-build',
          'pkg-config',
          'libgtk-3-dev',
        ]);
        break;
      case 'install-xcode':
        await _runConfirmed(request, 'xcode-select', const ['--install']);
        break;
      case 'install-cocoapods':
        await _runConfirmed(request, 'sudo', const [
          'gem',
          'install',
          'cocoapods',
        ]);
        break;
      default:
        throw CliException('Unknown fix: $fix');
    }
  }

  Future<void> _runConfirmed(
    CliRequest request,
    String executable,
    List<String> arguments,
  ) async {
    final accepted = await confirmAction(
      console: console,
      reader: reader,
      messages: _messages,
      yes: request.yes,
      dryRun: request.dryRun,
      prompt: '$executable ${arguments.join(' ')}',
    );
    if (!accepted) {
      return;
    }
    final result = await processes.run(
      executable,
      arguments,
      environment: sessionEnv,
    );
    if (result.exitCode != 0) {
      throw CliException(result.stderr, exitCode: 2);
    }
  }

  Future<void> _removeLock(CliRequest request) async {
    final file = File(
      p.join(defaultFlutterHome(home), 'bin', 'cache', 'lockfile'),
    );
    if (!file.existsSync()) {
      console.writeln(_messages.text('lockKept'));
      return;
    }
    if (request.dryRun) {
      console.writeln(_messages.text('dryRun', {'url': file.path}));
      return;
    }
    await file.delete();
    console.writeln(_messages.text('lockRemoved'));
  }

  Future<void> _upgradeFlutter(CliRequest request) async {
    console.writeln(_messages.text('updateAsk'));
    final answer = reader.readLine()?.trim().toUpperCase() ?? 'N';
    if (answer != 'Y' && answer != 'YES' && !request.yes) {
      return;
    }
    console.writeln(_messages.text('updating'));
    final upgrade = await processes.run('flutter', const [
      'upgrade',
      '--force',
    ], environment: sessionEnv);
    if (upgrade.exitCode != 0) {
      throw CliException(upgrade.stderr, exitCode: 2);
    }
    await processes.run('flutter', const [
      'doctor',
      '-v',
    ], environment: sessionEnv);
    console.writeln(_messages.text('updateDone'));
  }

  Future<int> _mirror(CliRequest request) async {
    final action = request.rest.isEmpty ? 'list' : request.rest.first;
    final mirrors = loadMirrors(home);
    final active = activeMirrorId(home);
    if (action == 'list') {
      console.writeln(_messages.text('mirrorHeader', {'id': active}));
      for (final mirror in mirrors) {
        console.writeln(
          _messages.text('mirrorLine', {
            'mark': mirror.id == active ? '*' : '-',
            'id': mirror.id,
            'storage': mirror.storage,
            'pub': mirror.pubHost,
          }),
        );
      }
      return 0;
    }
    if (action == 'reset') {
      await _saveMirror(request, requireMirror(mirrors, 'official'));
      return 0;
    }
    if (action == 'set') {
      if (request.rest.length < 2) {
        throw const CliException('Usage: fes mirror set <id>');
      }
      await _saveMirror(request, requireMirror(mirrors, request.rest[1]));
      return 0;
    }
    throw CliException('Usage: fes mirror list|set <id>|reset');
  }

  Future<int> _list() async {
    final store = VersionStore(home);
    final installed = store.list();
    console.writeln(_messages.text('versionHeader'));
    if (installed.isEmpty) {
      console.writeln(_messages.text('versionNone', {'path': store.root}));
      return 0;
    }
    for (final sdk in installed) {
      final key = sdk.active ? 'versionActive' : 'versionItem';
      console.writeln(
        _messages.text(key, {'version': sdk.version, 'path': sdk.location}),
      );
    }
    return 0;
  }

  Future<int> _use(CliRequest request) async {
    final version =
        request.flutterVersion ?? readProjectFlutterVersion(workingDirectory);
    if (version == null) {
      throw const CliException('Usage: fes use <version>');
    }
    final parent = p.join(VersionStore(home).root, version);
    await _downloadFlutter(
      request,
      version: version,
      destinationParent: parent,
    );
    if (!request.dryRun) {
      await _linkActive(p.join(parent, 'flutter'));
    }
    console.writeln(_messages.text('useDone', {'version': version}));
    return 0;
  }

  Future<void> _linkActive(String flutterDir) async {
    final linkPath = VersionStore(home).activeLink;
    final link = Link(linkPath);
    if (link.existsSync()) {
      await link.delete();
    }
    try {
      await link.create(flutterDir, recursive: true);
    } on FileSystemException {
      if (os.operatingSystem != 'windows') {
        rethrow;
      }
      final result = await processes.run(
        'powershell',
        const [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          r'New-Item -ItemType Junction -Path $env:FES_LINK -Target $env:FES_TARGET -Force | Out-Null',
        ],
        environment: {
          ...sessionEnv,
          'FES_LINK': linkPath,
          'FES_TARGET': flutterDir,
        },
      );
      if (result.exitCode != 0) {
        throw CliException(result.stderr, exitCode: 2);
      }
    }
  }

  Future<int> _remove(CliRequest request) async {
    if (request.rest.isEmpty) {
      throw const CliException('Usage: fes remove <version>');
    }
    final removed = await VersionStore(home).remove(
      request.rest.first,
      allowActive: request.yes,
      dryRun: request.dryRun,
    );
    console.writeln(_messages.text('removed', {'path': removed}));
    return 0;
  }

  Future<int> _create(CliRequest request) async {
    if (request.rest.isEmpty) {
      throw const CliException('Usage: fes create <name>');
    }
    final name = request.rest.first;
    validatePackageName(name);
    final overlay = templateFiles(request.template);
    if (request.dryRun) {
      console.writeln(
        _messages.text('createDry', {
          'name': name,
          'template': request.template,
        }),
      );
      return 0;
    }
    final created = await processes.run(
      'flutter',
      ['create', '--project-name', name, name],
      workingDirectory: workingDirectory,
      environment: sessionEnv,
    );
    if (created.exitCode != 0) {
      throw CliException(created.stderr, exitCode: 2);
    }
    for (final entry in overlay.entries) {
      final file = File(p.join(workingDirectory, name, entry.key));
      await file.parent.create(recursive: true);
      await file.writeAsString(entry.value);
    }
    console.writeln(
      _messages.text('createDone', {
        'name': name,
        'template': request.template,
      }),
    );
    return 0;
  }

  Future<int> _selfUpdate(CliRequest request) async {
    if (isPubGlobalInstall(executable)) {
      console.writeln(_messages.text('selfPub'));
      return 0;
    }
    final release = parseGitHubRelease(
      await readHttpsText(
        http,
        Uri.parse(
          'https://api.github.com/repos/$githubRepository/releases/latest',
        ),
      ),
    );
    final tag = release.tag.startsWith('v')
        ? release.tag.substring(1)
        : release.tag;
    if (!isNewerVersion(tag, compiledPackageVersion)) {
      console.writeln(
        _messages.text('selfSame', {'version': compiledPackageVersion}),
      );
      return 0;
    }
    final assetName = releaseAssetName(
      operatingSystem: os.operatingSystem,
      arch: os.arch,
    );
    final asset = release.requireAsset(assetName);
    final sums = release.requireAsset('SHA256SUMS');
    final expected = requireChecksum(
      await readHttpsText(http, sums.url),
      assetName,
    );
    if (request.dryRun) {
      console.writeln(_messages.text('dryRun', {'url': asset.url.toString()}));
      return 0;
    }
    final accepted = await confirmAction(
      console: console,
      reader: reader,
      messages: _messages,
      yes: request.yes,
      dryRun: request.dryRun,
      prompt: _messages.text('selfAsk', {'version': tag}),
    );
    if (!accepted) {
      return 0;
    }
    final staged = File('$executable.new');
    await _downloader.download(
      url: asset.url,
      destination: staged,
      expectedSha256: expected,
    );
    if (os.operatingSystem == 'windows') {
      console.writeln(_messages.text('selfStaged', {'path': staged.path}));
      return 0;
    }
    try {
      await staged.rename(executable);
      console.writeln(_messages.text('selfDone', {'version': tag}));
    } on FileSystemException {
      console.writeln(_messages.text('selfStaged', {'path': staged.path}));
    }
    return 0;
  }

  Future<int> _net() async {
    final storage = resolveStorageBase(environment: sessionEnv, home: home);
    final uri = flutterReleasesUri(
      storageBaseUrl: storage,
      os: os.operatingSystem,
    );
    try {
      final body = await readHttpsText(http, uri);
      if (!body.contains('current_release')) {
        throw const DownloadException(
          'Release index was missing current_release.',
        );
      }
      console.writeln(
        _messages.text('netOk', {'url': uri.toString(), 'status': '200'}),
      );
      return 0;
    } on CliException catch (error) {
      console.writeln(
        _messages.text('netFail', {
          'url': uri.toString(),
          'message': error.message,
        }),
      );
      return 2;
    }
  }
}
