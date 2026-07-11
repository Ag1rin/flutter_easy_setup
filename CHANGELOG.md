## [1.0.6]

### Added
- README screenshots section with terminal preview images
- Screenshot generation script (`scripts/generate_screenshots.ps1`)

### Changed
- Smart install: skip Flutter SDK download when already installed in PATH
- Smart install: reuse local `~/flutter` installation without re-downloading
- Dart is no longer installed separately — recognized as bundled with Flutter
- Android cmdline-tools and licenses are only installed when missing
- SDK check (option 2) now reports Dart status correctly when Flutter is present

### Fixed
- About screen version now matches package version

## [1.0.5]
- fix release 

## [1.0.4]
- fix release 

## [1.0.3]
- fix release 

## [1.0.2]
- update for best release
- fix release 

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