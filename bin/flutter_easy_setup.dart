import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:process_run/shell.dart';
// ignore: unused_import
import 'package:http/http.dart' as http;
import 'package:ansicolor/ansicolor.dart';

// Define pens for colors
final greenPen = AnsiPen()..green(bold: true);
final redPen = AnsiPen()..red(bold: true);
final yellowPen = AnsiPen()..yellow(bold: true);
final cyanPen = AnsiPen()..cyan(bold: true);

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('version', abbr: 'v', help: 'Show version');
  final results = parser.parse(arguments);

  if (results['version']) {
    print(
      greenPen(
        'Flutter Easy Setup CLI - Version 1.0.6 (Supports Flutter 3.38.5 - December 2025)',
      ),
    );
    return;
  }

  displayWelcome();

  while (true) {
    print(yellowPen('\nSelect an option (0-6):'));
    final input = stdin.readLineSync();
    final choice = int.tryParse(input ?? '') ?? -1;

    try {
      switch (choice) {
        case 1:
          await runFlutterDoctor();
          break;
        case 2:
          await checkSDKs();
          break;
        case 3:
          await installOrFix();
          break;
        case 4:
          await updateAll();
          break;
        case 5:
          displayHelp();
          break;
        case 6:
          displayAbout();
          break;
        case 0:
          print(greenPen('Exiting... Goodbye!'));
          return;
        default:
          print(redPen('Invalid option. Please try again.'));
      }
    } catch (e) {
      logError('Error in operation: $e');
      print(
        redPen(
          'An error occurred: $e. Check flutter_setup_log.txt for details.',
        ),
      );
    }
  }
}

void displayWelcome() {
  print(
    cyanPen(r'''    
  Easy Setup CLI - Version 1.0.6 (Supports Flutter 3.38.5 - December 2025)
  '''),
  );

  print(greenPen('Welcome to Flutter Easy Setup!'));
  print('Options:');
  print('1. Run Flutter Doctor');
  print('2. Check Dart, Flutter, and Android SDKs');
  print('3. Install missing components or full setup');
  print('4. Check and update everything');
  print('5. Installation Guide');
  print('6. About');
  print('0. Exit');
}

Future<void> runFlutterDoctor() async {
  print(yellowPen('Running flutter doctor...'));
  var shell = Shell();
  await shell.run('flutter doctor -v');
  print(greenPen('Flutter doctor complete.'));
}

String homeDirectory() {
  return Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '~';
}

Future<bool> isCommandAvailable(Shell shell, String command) async {
  try {
    await shell.run('$command --version');
    return true;
  } catch (_) {
    return false;
  }
}

Future<Shell> shellWithLocalFlutter(Shell shell) async {
  final flutterBin = '${homeDirectory()}/flutter/bin';
  if (!Directory('${homeDirectory()}/flutter').existsSync()) {
    return shell;
  }

  final env = Map<String, String>.from(Platform.environment);
  env['PATH'] = '$flutterBin${Platform.pathSeparator}${env['PATH'] ?? ''}';
  return Shell(environment: env);
}

Future<void> checkSDKs() async {
  print(yellowPen('Checking SDKs...'));
  var shell = Shell();

  final flutterInstalled = await isCommandAvailable(shell, 'flutter');
  if (flutterInstalled) {
    print(greenPen('Flutter is installed.'));
    print(greenPen('Dart is installed (bundled with Flutter).'));
  } else {
    print(redPen('Flutter not found.'));
    shell = await shellWithLocalFlutter(shell);
    if (await isCommandAvailable(shell, 'dart')) {
      print(greenPen('Dart is installed.'));
    } else {
      print(redPen('Dart not found.'));
    }
  }

  if (await isCommandAvailable(shell, 'sdkmanager')) {
    print(greenPen('Android SDK tools are installed.'));
  } else {
    print(redPen('Android SDK tools not found.'));
  }
}

Future<void> installOrFix() async {
  print(yellowPen('Starting installation/fix...'));
  var shell = Shell();

  final os = Platform.operatingSystem;
  print('Detected OS: $os');

  final home = homeDirectory();
  final flutterPath = Directory('$home/flutter');

  // Git check (manual install recommended)
  if (await isCommandAvailable(shell, 'git')) {
    print(greenPen('Git is installed.'));
  } else {
    print(
      redPen(
        'Git not found. Please install Git manually from https://git-scm.com',
      ),
    );
  }

  // Flutter & Dart — skip download when already available
  if (await isCommandAvailable(shell, 'flutter')) {
    print(greenPen('Flutter is already installed. Skipping SDK download.'));
    print(greenPen('Dart is bundled with Flutter — no separate install needed.'));
  } else if (flutterPath.existsSync()) {
    print(
      greenPen(
        'Flutter SDK found at ${flutterPath.path}. Skipping download.',
      ),
    );
    shell = await shellWithLocalFlutter(shell);
    if (await isCommandAvailable(shell, 'flutter')) {
      print(greenPen('Using existing local Flutter installation.'));
    } else {
      print(
        redPen(
          'Flutter folder exists but flutter command is not working. '
          'Check PATH or reinstall manually.',
        ),
      );
    }
  } else {
    print(yellowPen('Flutter not found. Downloading SDK v3.38.5 (stable)...'));
    final url = await getLatestFlutterUrl();
    final filename = url.split('/').last;

    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();
    final total = response.contentLength;
    final file = File(filename);
    final sink = file.openWrite();
    var downloaded = 0;

    await for (final chunk in response) {
      downloaded += chunk.length;
      sink.add(chunk);
      // ignore: unnecessary_null_comparison
      if (total != null && total > 0) {
        final percent = (downloaded / total * 100).toStringAsFixed(1);
        stdout.write(
          '\rDownloading Flutter SDK... $percent% ($downloaded/$total bytes)',
        );
      }
    }
    await sink.close();
    print('\n${greenPen('Download complete!')}');

    print(yellowPen('Extracting Flutter SDK...'));
    if (os == 'linux') {
      await shell.run('tar -xf $filename -C $home');
    } else {
      await shell.run('unzip -q $filename -d $home');
    }

    if (file.existsSync()) file.deleteSync();
    print(greenPen('Flutter SDK extracted to $home/flutter'));

    final newEnv = Map<String, String>.from(Platform.environment);
    final flutterBin = '$home/flutter/bin';
    newEnv['PATH'] = '$flutterBin${Platform.pathSeparator}${newEnv['PATH'] ?? ''}';
    shell = Shell(environment: newEnv);
  }

  // cmdline-tools — only when missing
  if (await isCommandAvailable(shell, 'sdkmanager')) {
    print(greenPen('Android cmdline-tools already installed. Skipping.'));
  } else {
    print(yellowPen('Installing Android cmdline-tools (latest)...'));
    await shell.run(
      'sdkmanager "cmdline-tools;latest" --sdk_root=${Platform.environment['ANDROID_HOME'] ?? '$home/android-sdk'}',
    );
  }

  // Accept licenses — only when Flutter is available
  if (await isCommandAvailable(shell, 'flutter')) {
    try {
      await shell.run('flutter doctor --android-licenses --accept');
      print(greenPen('Android licenses accepted.'));
    } catch (_) {
      print(yellowPen('Accepting Android licenses interactively...'));
      await shell.run('flutter doctor --android-licenses');
    }
  } else {
    print(
      yellowPen(
        'Skipping Android licenses — Flutter is not available in this session.',
      ),
    );
  }

  // Remove lockfile if present
  final lockfile = File('$home/flutter/bin/cache/lockfile');
  if (lockfile.existsSync()) {
    lockfile.deleteSync();
    print(greenPen('Startup lockfile removed.'));
  }

  // Permanent PATH instructions
  print(yellowPen('\nImportant: Add Flutter to PATH permanently:'));
  if (os == 'windows') {
    print(
      yellowPen(
        r'Set Environment Variable: PATH += ;%USERPROFILE%\flutter\bin',
      ),
    );
  } else if (os == 'macos' || os == 'linux') {
    print(
      yellowPen(
        r'Add to ~/.zshrc or ~/.bashrc: export PATH="$PATH:$home/flutter/bin"',
      ),
    );
    print(yellowPen('Then run: source ~/.zshrc (or ~/.bashrc)'));
  }

  print(greenPen('Setup complete! Run option 1 (flutter doctor) to verify.'));
}

Future<String> getLatestFlutterUrl() async {
  if (Platform.isWindows) {
    return 'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.38.5-stable.zip';
  } else if (Platform.isMacOS) {
    return 'https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.38.5-stable.zip';
  } else if (Platform.isLinux) {
    return 'https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.38.5-stable.tar.xz';
  }
  throw Exception('Unsupported operating system');
}

Future<void> updateAll() async {
  print(yellowPen('Check for updates? (Y/N)'));
  final confirm = stdin.readLineSync()?.toUpperCase() ?? 'N';
  if (confirm != 'Y') return;

  print(yellowPen('Updating Flutter, Dart, and tools...'));
  var shell = Shell();
  await shell.run('flutter upgrade --force');
  await shell.run('flutter doctor -v');
  print(greenPen('Update complete!'));
}

void displayHelp() {
  print(greenPen('Flutter Installation Guide (December 2025):'));
  print('1. Install Git from https://git-scm.com');
  print('2. Run this tool → Option 3 for automatic setup');
  print('3. Add flutter/bin to your PATH permanently');
  print('4. Run "flutter doctor" and fix remaining issues');
  print('5. For Android: Licenses are auto-accepted where possible');
  print(
    '6. For iOS (macOS): Install Xcode from App Store + run "sudo xcode-select --install"',
  );
  print('Official guide: https://docs.flutter.dev/get-started/install');
}

void displayAbout() {
  print(greenPen('About Flutter Easy Setup CLI'));
  print('Version: 1.0.6');
  print('Supports Flutter 3.38.5 (Stable - December 2025)');
  print('Created by Agirîn');
  print('GitHub: https://github.com/Ag1rin/flutter_easy_setup');
  print('This tool automates Flutter setup and fixes common issues.');
  print('Open source - Contributions welcome!');
}

void logError(String message) {
  final logFile = File('flutter_setup_log.txt');
  logFile.writeAsStringSync(
    '${DateTime.now()}: $message\n',
    mode: FileMode.append,
  );
}
