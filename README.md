# Flutter Easy Setup CLI

A simple, beautiful, and user-friendly command-line tool to automate Flutter installation and fix the most common setup issues on Windows, macOS, and Linux.

![Flutter Easy Setup](https://img.shields.io/badge/Flutter-Easy%20Setup-02569B?logo=flutter&logoColor=white&style=for-the-badge)  
![Version](https://img.shields.io/badge/version-1.0.0-blue)  
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)  
![License](https://img.shields.io/badge/license-MIT-green)

## Why This Tool?

Setting up Flutter can be frustrating for beginners — and even experienced developers sometimes run into issues like:

- `cmdline-tools component is missing`
- `Waiting for another flutter command to release the startup lock`
- Android licenses not accepted
- PATH not configured correctly
- Dart/Flutter SDK not found in IDE

**Flutter Easy Setup CLI** makes the entire process smooth and interactive with a colorful menu, automatic fixes, and clear instructions.

## Features

- Beautiful colored ASCII welcome screen
- Interactive menu with 7 options
- Automatic Flutter SDK download & extraction (latest stable version)
- Live download progress bar
- Auto-accept Android licenses
- Remove startup lockfile automatically
- Smart OS detection (Windows, macOS, Linux)
- Clear instructions for permanent PATH setup
- Run `flutter doctor` directly from the tool
- Check installed SDKs (Flutter, Dart, Android tools)
- Update Flutter with one click
- Detailed help guide and about section
- Error logging to `flutter_setup_log.txt`

## Installation

### Prerequisites
- Git installed (required by Flutter)
- Internet connection

### Install via pub (recommended)

```bash
dart pub global activate flutter_easy_setup
```

Then run it:

```bash
fes
```

### Or run directly without global install

```bash
dart pub get
dart run bin/main.dart
```

## Usage

After running `fes`, you'll see a beautiful welcome screen with this menu:

```
1. Run Flutter Doctor
2. Check Dart, Flutter, and Android SDKs
3. Install missing components or full setup
4. Check and update everything
5. Installation Guide
6. About
0. Exit
```

Just type the number and press Enter!

### Recommended Flow for New Users:
1. Choose **3** → Full setup (downloads Flutter if missing, fixes common issues)
2. Follow the on-screen instructions to add Flutter to your PATH permanently
3. Choose **1** → Run `flutter doctor` to verify everything is green

## Supported Platforms

- Windows
- macOS (Intel & Apple Silicon)
- Linux

## Current Flutter Version Supported

This version (1.0.0) installs **Flutter 3.27.0 stable** (safe and widely used).  
Future versions will support automatic latest version detection.

## Contributing

Contributions are welcome! Feel free to:
- Open issues for bugs or feature requests
- Submit pull requests
- Improve the UI or add new fixes

## Author

**Agirîn**  
GitHub: [@Ag1rin](https://github.com/Ag1rin)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Made with ❤️ for the Flutter community**  
Let's make Flutter setup easy for everyone! 🚀