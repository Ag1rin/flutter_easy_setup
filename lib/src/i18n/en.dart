/// English user-facing strings.
const enMessages = <String, String>{
  'banner':
      'Easy Setup CLI - Version {version}\nWelcome to Flutter Easy Setup!',
  'opt1': '1. Run Flutter Doctor',
  'opt2': '2. Check Dart, Flutter, and Android SDKs',
  'opt3': '3. Install missing components or full setup',
  'opt4': '4. Check and update everything',
  'opt5': '5. Installation Guide',
  'opt6': '6. About',
  'opt7': '7. Language / زبان',
  'opt0': '0. Exit',
  'select': 'Select an option (0-7):',
  'invalid': 'Invalid option. Please try again.',
  'goodbye': 'Exiting... Goodbye!',
  'error': 'An error occurred: {message}. Check flutter_setup_log.txt.',
  'doctorRunning': 'Running flutter doctor...',
  'doctorDone': 'Flutter doctor complete.',
  'checking': 'Checking SDKs...',
  'flutterOk': 'Flutter is installed.',
  'dartBundled': 'Dart is installed (bundled with Flutter).',
  'flutterMissing': 'Flutter not found.',
  'dartOk': 'Dart is installed.',
  'dartMissing': 'Dart not found.',
  'androidOk': 'Android SDK tools are installed.',
  'androidMissing': 'Android SDK tools not found.',
  'gitOk': 'Git is installed.',
  'gitMissing':
      'Git not found. Please install Git manually from https://git-scm.com',
  'skipDownload': 'Flutter is already installed. Skipping SDK download.',
  'localFound': 'Flutter SDK found at {path}. Skipping download.',
  'localOk': 'Using existing local Flutter installation.',
  'localBroken':
      'Flutter folder exists but flutter command is not working. Check PATH or reinstall manually.',
  'usingMirror': 'Using Flutter storage {url} (mirror: {id}).',
  'downloading': 'Downloading Flutter {version} ({channel})...',
  'downloadDone': 'Download complete!',
  'extracting': 'Extracting Flutter SDK...',
  'extracted': 'Flutter SDK extracted to {path}',
  'pathPrompt': 'Add Flutter to PATH permanently?',
  'pathWindows': r'Set Environment Variable: PATH += ;{path}',
  'pathUnix': 'Add to ~/.zshrc or ~/.bashrc: export PATH="\$PATH:{path}"',
  'pathSource': 'Then run: source ~/.zshrc (or ~/.bashrc)',
  'pathApplied': 'PATH updated. Open a new terminal to use it.',
  'pathUnchanged': 'Flutter is already on PATH.',
  'pathUndo': 'Restored PATH backup for {target}.',
  'setupDone': 'Setup complete! Run option 1 (flutter doctor) to verify.',
  'updateAsk': 'Check for updates? (Y/N)',
  'updating': 'Updating Flutter, Dart, and tools...',
  'updateDone': 'Update complete!',
  'guideTitle': 'Flutter Installation Guide:',
  'guideBody':
      '1. Install Git from https://git-scm.com\n'
      '2. Run this tool and choose option 3 for automatic setup\n'
      '3. Add flutter/bin to your PATH permanently\n'
      '4. Run "flutter doctor" and fix remaining issues\n'
      '5. For Android: licenses are accepted only after you confirm\n'
      '6. For iOS (macOS): install Xcode, then xcode-select --install\n'
      'Official guide: https://docs.flutter.dev/get-started/install',
  'aboutTitle': 'About Flutter Easy Setup CLI',
  'aboutVersion': 'Version: {version}',
  'aboutBody':
      'Created by Agirîn\n'
      'GitHub: https://github.com/Ag1rin/flutter_easy_setup\n'
      'This tool automates Flutter setup and fixes common issues.\n'
      'Open source - Contributions welcome!',
  'cliVersion': 'Flutter Easy Setup CLI {version}',
  'langSet': 'Language set to {lang}.',
  'dryRun': 'Dry run. Would download {url}',
  'confirm': '{prompt} (y/N)',
  'versionHeader': 'Installed Flutter SDKs:',
  'versionNone': 'No versions under {path}.',
  'versionActive': '{version} (active) {path}',
  'versionItem': '{version} {path}',
  'removed': 'Removed {path}',
  'removeRefused': 'Refusing to remove the active version without --yes.',
  'useDone': 'Now using Flutter {version}.',
  'createDone': 'Created {name} with the {template} template.',
  'createDry': 'Dry run. Would create {name} with the {template} template.',
  'badName': 'Project name must be a Dart package name, such as my_app.',
  'selfSame': 'fes {version} is already the latest release.',
  'selfAsk': 'Download fes {version} and replace this executable?',
  'selfPub':
      'This install comes from pub. Run: dart pub global activate flutter_easy_setup',
  'selfStaged':
      'Downloaded {path}. Close fes and replace the current executable with it.',
  'selfDone': 'Updated fes to {version}.',
  'netOk': 'Reached {url} ({status}).',
  'netFail': 'Could not reach {url}: {message}',
  'mirrorHeader': 'Mirrors (active: {id}):',
  'mirrorLine': '{mark} {id} storage={storage} pub={pub}',
  'mirrorSaved': 'Active mirror is now {id}. Storage: {storage}',
  'finding': '{id}: {summary}',
  'fixAsk': 'Apply fix {fix}?',
  'fixSkip': 'Skipped {fix}.',
  'chromeHint': 'Install Google Chrome from https://www.google.com/chrome/',
  'vsHint':
      'Install Visual Studio with the Desktop development with C++ workload.',
  'lockRemoved': 'Startup lockfile removed.',
  'lockKept': 'Startup lockfile was left in place.',
  'jdkDone': 'JDK installed at {path}',
  'androidDone': 'Android SDK ready at {path}',
  'replaceAsk': 'Replace the Flutter SDK at {path}?',
  'replaceSkipped': 'Left the existing Flutter SDK in place.',
  'envPrompt': 'Save these environment variables permanently?',
  'help':
      'Usage: fes [--version] [--lang en|fa] [--no-color] [--yes] [--dry-run]\n'
      '       fes install [--flutter-version x.y.z] [--channel stable|beta]\n'
      '       fes doctor [--json]\n'
      '       fes path [--undo]\n'
      '       fes mirror list|set <id>|reset\n'
      '       fes list | fes use <version> | fes remove <version>\n'
      '       fes create <name> [--template basic|state|clean]\n'
      '       fes update\n'
      '       fes net',
};
