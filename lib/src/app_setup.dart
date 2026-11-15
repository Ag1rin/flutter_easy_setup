part of 'app.dart';

extension FesSetup on FesApp {
  Future<int> _install(CliRequest request, {required bool intoHome}) async {
    console.writeln(_messages.text('checking'));
    final git = await commandSucceeds(
      processes,
      'git',
      environment: sessionEnv,
    );
    console.writeln(_messages.text(git ? 'gitOk' : 'gitMissing'));
    final pinned =
        request.flutterVersion ?? readProjectFlutterVersion(workingDirectory);
    final onPath = await commandSucceeds(
      processes,
      'flutter',
      environment: sessionEnv,
    );
    final flutterHome = defaultFlutterHome(home);
    final localExists = Directory(flutterHome).existsSync();
    final choice = chooseFlutterInstall(
      flutterOnPath: onPath,
      localExists: localExists,
      versionPinned: pinned != null,
    );
    if (choice == FlutterInstallChoice.skip) {
      console.writeln(_messages.text('skipDownload'));
      console.writeln(_messages.text('dartBundled'));
    } else if (choice == FlutterInstallChoice.reuse) {
      console.writeln(_messages.text('localFound', {'path': flutterHome}));
      _preferLocalFlutter();
      final works = await commandSucceeds(
        processes,
        'flutter',
        environment: sessionEnv,
      );
      console.writeln(_messages.text(works ? 'localOk' : 'localBroken'));
    } else {
      await _downloadFlutter(
        request,
        version: pinned,
        destinationParent: intoHome
            ? home
            : p.join(VersionStore(home).root, pinned ?? 'stable'),
      );
      _preferLocalFlutter();
    }
    await _maybeAndroid(request);
    await _maybeJdk(request);
    await _maybePath(request, flutterBinPath(flutterHome));
    console.writeln(_messages.text('setupDone'));
    return 0;
  }

  Future<void> _downloadFlutter(
    CliRequest request, {
    required String? version,
    required String destinationParent,
  }) async {
    final storage = resolveStorageBase(environment: sessionEnv, home: home);
    final mirrorId = activeMirrorId(home);
    console.writeln(
      _messages.text('usingMirror', {'url': storage, 'id': mirrorId}),
    );
    final indexUri = flutterReleasesUri(
      storageBaseUrl: storage,
      os: os.operatingSystem,
    );
    final index = ReleaseIndex.parse(await readHttpsText(http, indexUri));
    final archive = index.select(
      channel: request.channel,
      arch: request.arch ?? os.arch,
      version: version,
    );
    final url = archive.downloadUri(storage);
    if (request.dryRun) {
      console.writeln(_messages.text('dryRun', {'url': url.toString()}));
      return;
    }
    console.writeln(
      _messages.text('downloading', {
        'version': archive.version,
        'channel': archive.channel,
      }),
    );
    final fileName = safeFileName(url.pathSegments.last);
    final file = File(p.join(Directory.systemTemp.path, fileName));
    await _downloader.download(
      url: url,
      destination: file,
      expectedSha256: archive.sha256,
      onProgress: request.quiet ? null : _progress,
    );
    console.writeln(_messages.text('downloadDone'));
    console.writeln(_messages.text('extracting'));
    final flutterDir = Directory(p.join(destinationParent, 'flutter'));
    if (flutterDir.existsSync()) {
      final accepted = await confirmAction(
        console: console,
        reader: reader,
        messages: _messages,
        yes: request.yes,
        dryRun: request.dryRun,
        prompt: _messages.text('replaceAsk', {'path': flutterDir.path}),
      );
      if (!accepted) {
        throw CliException(_messages.text('replaceSkipped'));
      }
      await flutterDir.rename(
        '${flutterDir.path}.bak-${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    await Directory(destinationParent).create(recursive: true);
    await ArchiveExtractor(
      processes,
      operatingSystem: os.operatingSystem,
    ).extract(archivePath: file.path, destinationDirectory: destinationParent);
    if (file.existsSync()) {
      await file.delete();
    }
    console.writeln(
      _messages.text('extracted', {
        'path': p.join(destinationParent, 'flutter'),
      }),
    );
  }

  void _progress(int received, int? total) {
    if (total == null || total <= 0) {
      console.write('\r$received');
      return;
    }
    final percent = (received / total * 100).toStringAsFixed(1);
    console.write('\r$percent% ($received/$total)');
  }

  void _preferLocalFlutter() {
    final bin = flutterBinPath(defaultFlutterHome(home));
    if (!Directory(bin).existsSync()) {
      return;
    }
    final current = sessionEnv['PATH'] ?? '';
    sessionEnv['PATH'] = appendPathEntry(
      current,
      bin,
      separator: pathListSeparator(os.operatingSystem),
      ignoreCase: os.operatingSystem == 'windows',
    );
  }

  Future<void> _maybePath(CliRequest request, String bin) async {
    final editor = PathEditor(
      operatingSystem: os.operatingSystem,
      home: home,
      env: env,
      clock: DateTime.now,
    );
    final plans = await editor.plan(bin);
    if (plans.every((plan) => plan.alreadyPresent)) {
      console.writeln(_messages.text('pathUnchanged'));
      return;
    }
    final accepted = await confirmAction(
      console: console,
      reader: reader,
      messages: _messages,
      yes: request.yes,
      dryRun: request.dryRun,
      prompt: _messages.text('pathPrompt'),
    );
    if (!accepted) {
      _printPathHint(bin);
      return;
    }
    await editor.apply(bin);
    console.writeln(_messages.text('pathApplied'));
  }

  void _printPathHint(String bin) {
    if (os.operatingSystem == 'windows') {
      console.writeln(_messages.text('pathWindows', {'path': bin}));
      return;
    }
    console.writeln(_messages.text('pathUnix', {'path': bin}));
    console.writeln(_messages.text('pathSource'));
  }

  Future<int> _path(CliRequest request) async {
    final editor = PathEditor(
      operatingSystem: os.operatingSystem,
      home: home,
      env: env,
      clock: DateTime.now,
    );
    if (request.undo) {
      if (request.dryRun) {
        console.writeln(_messages.text('dryRun', {'url': 'path-undo'}));
        return 0;
      }
      final restored = await editor.undo();
      console.writeln(_messages.text('pathUndo', {'target': restored.target}));
      return 0;
    }
    await _maybePath(request, flutterBinPath(defaultFlutterHome(home)));
    return 0;
  }

  Future<void> _maybeAndroid(CliRequest request) async {
    final present = await commandSucceeds(
      processes,
      'sdkmanager',
      environment: sessionEnv,
    );
    if (present && request.command != 'doctor') {
      console.writeln(_messages.text('androidOk'));
      return;
    }
    final accepted = await confirmAction(
      console: console,
      reader: reader,
      messages: _messages,
      yes: request.yes,
      dryRun: request.dryRun,
      prompt: 'Install Android command-line tools?',
    );
    if (!accepted) {
      return;
    }
    await _installAndroid(request);
  }

  Future<void> _installAndroid(CliRequest request) async {
    final sdk = defaultAndroidSdk(
      home: home,
      operatingSystem: os.operatingSystem,
      environment: sessionEnv,
    );
    final pinned = androidToolsFor(
      operatingSystem: os.operatingSystem,
      arch: os.arch,
    );
    if (request.dryRun) {
      console.writeln(_messages.text('dryRun', {'url': pinned.url.toString()}));
      return;
    }
    final file = File(
      p.join(Directory.systemTemp.path, safeFileName(pinned.fileName)),
    );
    await _downloader.download(
      url: pinned.url,
      destination: file,
      expectedSha256: pinned.sha256,
    );
    final temp = await Directory.systemTemp.createTemp('fes-android-');
    await ArchiveExtractor(
      processes,
      operatingSystem: os.operatingSystem,
    ).extract(archivePath: file.path, destinationDirectory: temp.path);
    final latest = Directory(p.join(sdk, 'cmdline-tools', 'latest'));
    await latest.parent.create(recursive: true);
    final extracted = Directory(p.join(temp.path, 'cmdline-tools'));
    if (!latest.existsSync()) {
      await extracted.rename(latest.path);
    }
    final manager = sdkManagerPath(
      sdkRoot: sdk,
      operatingSystem: os.operatingSystem,
      separator: p.separator,
    );
    final install = await processes.run(manager, [
      '--sdk_root',
      sdk,
      ...androidSdkPackages,
    ], environment: sessionEnv);
    if (install.exitCode != 0) {
      throw CliException(install.stderr, exitCode: 2);
    }
    final licenses = await confirmAction(
      console: console,
      reader: reader,
      messages: _messages,
      yes: request.yes,
      dryRun: false,
      prompt: 'Accept Android SDK licenses?',
    );
    if (licenses) {
      final yes = List.filled(licenseAnswers, 'y').join('\n');
      await processes.run(
        manager,
        ['--sdk_root', sdk, '--licenses'],
        stdin: yes,
        environment: sessionEnv,
      );
    }
    sessionEnv['ANDROID_HOME'] = sdk;
    sessionEnv['ANDROID_SDK_ROOT'] = sdk;
    await _persistEnv(request, {'ANDROID_HOME': sdk, 'ANDROID_SDK_ROOT': sdk});
    console.writeln(
      palette.green(_messages.text('androidDone', {'path': sdk})),
    );
  }

  Future<void> _maybeJdk(CliRequest request) async {
    if (await commandSucceeds(processes, 'java', environment: sessionEnv)) {
      return;
    }
    final accepted = await confirmAction(
      console: console,
      reader: reader,
      messages: _messages,
      yes: request.yes,
      dryRun: request.dryRun,
      prompt: 'Install Temurin JDK 17?',
    );
    if (!accepted) {
      return;
    }
    final uri = adoptiumLatestUri(
      os: adoptiumOs(os.operatingSystem),
      arch: adoptiumArch(os.arch.name),
    );
    if (request.dryRun) {
      console.writeln(_messages.text('dryRun', {'url': uri.toString()}));
      return;
    }
    final asset = parseAdoptiumAssets(
      await readHttpsText(http, uri),
      os: adoptiumOs(os.operatingSystem),
      arch: adoptiumArch(os.arch.name),
    );
    final file = File(
      p.join(
        Directory.systemTemp.path,
        safeFileName(asset.url.pathSegments.last),
      ),
    );
    await _downloader.download(
      url: asset.url,
      destination: file,
      expectedSha256: asset.sha256,
    );
    final dest = Directory(p.join(fesRoot(home), 'jdks'));
    await dest.create(recursive: true);
    await ArchiveExtractor(
      processes,
      operatingSystem: os.operatingSystem,
    ).extract(archivePath: file.path, destinationDirectory: dest.path);
    final listing = await processes.run('tar', ['-tf', file.path]);
    final relative = javaHomeRelative(listing.stdout.split(RegExp(r'\r?\n')));
    if (relative == null) {
      throw const CliException('JDK archive did not contain bin/java.');
    }
    final javaHome = p.join(dest.path, relative);
    sessionEnv['JAVA_HOME'] = javaHome;
    await _persistEnv(request, {'JAVA_HOME': javaHome});
    console.writeln(
      palette.green(_messages.text('jdkDone', {'path': javaHome})),
    );
  }
}
