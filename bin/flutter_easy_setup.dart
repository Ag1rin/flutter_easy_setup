import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:process_run/shell.dart';
import 'package:http/http.dart' as http;
import 'package:ansicolor/ansicolor.dart';

// Define pens for colors
final greenPen = AnsiPen()..green(bold: true);
final redPen = AnsiPen()..red(bold: true);
final yellowPen = AnsiPen()..yellow(bold: true);
final cyanPen = AnsiPen()..cyan(bold: true);

void main(List<String> arguments) async {
  // Parse arguments if any (e.g., --version)
  final parser = ArgParser()
    ..addFlag('version', abbr: 'v', help: 'Show version');
  final results = parser.parse(arguments);

  if (results['version']) {
    print(greenPen('Flutter Easy Setup CLI - Version 1.0.0'));
    return;
  }

  // Display welcome screen
  displayWelcome();

  // Interactive loop
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
      print(redPen('An error occurred: $e. Check log file for details.'));
    }
  }
}

// Welcome screen
void displayWelcome() {
  print(
    cyanPen(r'''                                                     
  Easy Setup CLI - Version 1.0.0
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

// Run flutter doctor
Future<void> runFlutterDoctor() async {
  print(yellowPen('Running flutter doctor...'));
  var shell = Shell();
  await shell.run('flutter doctor -v');
  print(greenPen('Flutter doctor complete.'));
}

// Check SDKs
Future<void> checkSDKs() async {
  print(yellowPen('Checking SDKs...'));
  var shell = Shell();

  // Check Flutter
  try {
    await shell.run('flutter --version');
    print(greenPen('Flutter is installed.'));
  } catch (_) {
    print(redPen('Flutter not found.'));
  }

  // Check Dart
  try {
    await shell.run('dart --version');
    print(greenPen('Dart is installed.'));
  } catch (_) {
    print(redPen('Dart not found.'));
  }

  // Check Android SDK (cmdline-tools)
  try {
    await shell.run('sdkmanager --version');
    print(greenPen('Android SDK tools are installed.'));
  } catch (_) {
    print(redPen('Android SDK tools not found.'));
  }
}

// Install or Fix
Future<void> installOrFix() async {
  print(yellowPen('Starting installation/fix...'));
  var shell = Shell();

  // Detect OS
  final os = Platform.operatingSystem;
  print('Detected OS: $os');

  // Install Git if missing
  try {
    await shell.run('git --version');
  } catch (_) {
    print(yellowPen('Installing Git...'));
    if (os == 'macos') {
      await shell.run('brew install git');
    } else if (os == 'windows') {
      await shell.run('choco install git');
    } else if (os == 'linux') {
      await shell.run('sudo apt install git');
    }
  }

  // Download Flutter if missing
  final flutterPath = Directory('${Platform.environment['HOME']}/flutter');
  if (!flutterPath.existsSync()) {
    print(yellowPen('Downloading Flutter...'));
    final url = await getLatestFlutterUrl(); // Get latest stable URL
    final response = await http.get(Uri.parse(url));
    final file = File('flutter.zip');
    await file.writeAsBytes(response.bodyBytes);
    showProgress(
      file.lengthSync(),
      response.contentLength ?? 0,
    ); // Simple progress
    await shell.run('unzip flutter.zip -d ~/');
    // Update PATH using new environment map
    final newEnv = Map<String, String>.from(Platform.environment);
    newEnv['PATH'] = '${newEnv['PATH']}:~/flutter/bin';
    shell = Shell(environment: newEnv);
    print(greenPen('Flutter installed and PATH updated for this session.'));
  } else {
    print(greenPen('Flutter already exists.'));
  }

  // Install Android cmdline-tools if missing
  try {
    await shell.run('sdkmanager --version');
  } catch (_) {
    print(yellowPen('Installing Android cmdline-tools...'));
    await shell.run('sdkmanager "cmdline-tools;latest"');
  }

  // Accept licenses
  await shell.run('flutter doctor --android-licenses');

  // Fix lockfile
  final lockfile = File('~/flutter/bin/cache/lockfile');
  if (lockfile.existsSync()) {
    lockfile.deleteSync();
    print(greenPen('Lockfile removed.'));
  }

  // Set environment variables (instruct user for permanent)
  print(
    yellowPen(r'Add to PATH permanently: export PATH="$PATH:~/flutter/bin"'),
  );
  print(greenPen('Installation/Fix complete.'));
}

// Get latest Flutter download URL (example for stable, update as needed)
Future<String> getLatestFlutterUrl() async {
  // For simplicity, hardcode or fetch from API. Here: stable Windows example, adjust per OS
  if (Platform.isWindows) {
    return 'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.27.0-stable.zip';
  } else if (Platform.isMacOS) {
    return 'https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.27.0-stable.zip';
  } else if (Platform.isLinux) {
    return 'https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.0-stable.tar.xz';
  }
  throw Exception('Unsupported OS');
}

// Simple progress bar for download
void showProgress(int current, int total) {
  final percentage = (current / total * 100).toInt();
  print('Download progress: $percentage%');
  // Add timer for simulation if needed
}

// Update all
Future<void> updateAll() async {
  print(yellowPen('Check for updates? (Y/N)'));
  final confirm = stdin.readLineSync()?.toUpperCase() ?? 'N';
  if (confirm != 'Y') return;

  print(yellowPen('Updating...'));
  var shell = Shell();
  await shell.run('flutter upgrade');
  await shell.run('dart pub upgrade');
  await shell.run('sdkmanager --update');
  print(greenPen('Update complete.'));
}

// Display Help
void displayHelp() {
  print(greenPen('Installation Guide:'));
  print('1. Install Git if not present.');
  print('2. Download Flutter SDK from official site.');
  print('3. Extract to ~/flutter and add to PATH.');
  print('4. Run flutter doctor and fix issues.');
  print('5. Install Android cmdline-tools via sdkmanager.');
  print('6. Accept Android licenses.');
  print('7. For iOS (macOS): Install Xcode and CocoaPods.');
  print('More details: https://flutter.dev/docs/get-started/install');
}

// Display About
void displayAbout() {
  print(greenPen('About Flutter Easy Setup CLI:'));
  print('Created by Agirîn.');
  print('This tool simplifies Flutter setup and fixes common issues.');
  print('GitHub: https://github.com/Ag1rin/flutter_easy_setup');
  print('Version: 1.0.0');
  // Add your details here
}

// Log error to file
void logError(String message) {
  final logFile = File('flutter_setup_log.txt');
  logFile.writeAsStringSync('$message\n', mode: FileMode.append);
}
