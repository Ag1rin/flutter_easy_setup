# Flutter Easy Setup CLI

A beautiful, interactive, and user-friendly command-line tool to automate Flutter installation, fix common setup issues, and get you started quickly on Windows, macOS, and Linux.

![Flutter](https://img.shields.io/badge/Flutter-Easy%20Setup-02569B?logo=flutter&logoColor=white&style=for-the-badge)  
![Version](https://img.shields.io/badge/version-1.0.0-blue)  
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)  
![Platforms](https://img.shields.io/badge/platforms-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)  
![License](https://img.shields.io/badge/license-MIT-green)

## Why This Tool?

Flutter setup can be painful, especially for beginners. Common issues include:

- `cmdline-tools component is missing`
- `Waiting for another flutter command to release the startup lock`
- Android licenses not accepted
- Incorrect PATH configuration
- Dart/Flutter SDK not detected in IDEs

**Flutter Easy Setup CLI** solves these with a colorful interactive menu, automatic downloads, live progress bars, and smart fixes — all in one tool!

## Features (v1.0.2)

- Gorgeous colored ASCII art welcome screen
- Interactive menu with 7 options
- Automatic detection of your OS (Windows, macOS, Linux)
- Download & extract the latest stable Flutter SDK with a **live progress bar**
- Auto-accept Android licenses
- Automatically remove startup lockfile
- Install/fix Android cmdline-tools
- Run `flutter doctor` directly
- Check installed SDKs (Flutter, Dart, Android tools)
- One-click Flutter upgrade
- Detailed installation guide and troubleshooting tips
- Error logging to `flutter_setup_log.txt`
- Clear instructions for permanent PATH setup (per OS)

## Screenshots

*(Coming soon after release – the menu looks amazing in your terminal!)*

## Installation

### Option 1: Global install via pub (requires Dart SDK)

```bash
dart pub global activate flutter_easy_setup
```

Run it:

```bash
fes
```

### Option 2: Run directly (no global install needed)

```bash
dart pub get
dart run
```

### Option 3: Standalone executables (recommended for easy sharing)

Download the pre-compiled binary for your platform from the [Releases page](https://github.com/Ag1rin/flutter_easy_setup/releases/tag/v1.0.0):

- **Windows**: `fes-windows.exe`
- **macOS**: `fes-macos` (run `chmod +x fes-macos` if needed)
- **Linux**: `fes-linux` (run `chmod +x fes-linux`)

Double-click or run in terminal — no Dart required!

## Usage

Launch the tool with `fes` (or the executable name).

You'll see a beautiful welcome screen and menu:

```
1. Run Flutter Doctor
2. Check Dart, Flutter, and Android SDKs
3. Install missing components or full setup
4. Check and update everything
5. Installation Guide
6. About
0. Exit
```

**Recommended for new users:**
1. Select **3** → It will download Flutter (if missing), extract it, fix common issues, and set up everything.
2. Follow the on-screen instructions to add Flutter to your PATH **permanently**.
3. Select **1** → Run `flutter doctor` to verify a clean setup.

## Supported Flutter Version

This release (v1.0.5) installs and supports **Flutter 3.38.5 stable** (released December 12, 2025) — the latest stable version as of December 2025.

Future releases will include automatic latest-version detection.

## Supported Platforms

- Windows (x64)
- macOS (Intel & Apple Silicon arm64)
- Linux (x64)

## Contributing

Contributions are very welcome! Feel free to:

- Report bugs or suggest features via Issues
- Submit Pull Requests
- Improve the UI, add new auto-fixes, or support more tools (e.g., Java auto-install)

## Author

**Agirîn**  
GitHub: [@Ag1rin](https://github.com/Ag1rin)  
Project: https://github.com/Ag1rin/flutter_easy_setup

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

**Made with ❤️ for the Flutter community**  
Let's make Flutter setup painless for everyone! 🚀