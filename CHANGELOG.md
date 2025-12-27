## [1.0.1]
- update for best release

## [1.0.0] 

### Added
- Initial public release 🎉
- Beautiful colored ASCII art welcome screen with tool name and version
- Fully interactive menu with 7 options:
  1. Run Flutter Doctor
  2. Check Dart, Flutter, and Android SDKs
  3. Install missing components or full setup
  4. Check and update everything
  5. Installation Guide
  6. About
  0. Exit
- Automatic OS detection (Windows, macOS, Linux)
- Smart Flutter SDK download with **live progress bar** (real-time percentage and bytes)
- Automatic extraction of Flutter SDK (unzip on Windows/macOS, tar on Linux)
- Cleanup of downloaded archive after extraction
- Auto-install/fix Android `cmdline-tools` (latest)
- Automatic acceptance of Android SDK licenses
- Automatic removal of Flutter startup lockfile
- Session-based PATH update for immediate use
- Clear, OS-specific instructions for **permanent PATH configuration**
- One-click Flutter upgrade (`flutter upgrade --force`)
- Detailed in-app installation guide and troubleshooting tips
- About section with author credit and GitHub link
- Comprehensive error logging to `flutter_setup_log.txt` with timestamps
- Support for Flutter **3.38.5 stable** (latest stable as of December 2025)
- Cross-platform support:
  - Windows (x64)
  - macOS (Intel & Apple Silicon arm64)
  - Linux (x64)