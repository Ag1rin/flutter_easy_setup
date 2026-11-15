import '../models/cli_exception.dart';
import '../models/cpu_arch.dart';

/// Pinned Android command-line tools archive.
final class AndroidToolsArchive {
  /// Creates a pinned archive.
  const AndroidToolsArchive({required this.fileName, required this.sha256});

  /// File name on `dl.google.com`.
  final String fileName;

  /// Lowercase SHA-256.
  final String sha256;

  /// HTTPS download URL.
  Uri get url =>
      Uri.parse('https://dl.google.com/android/repository/$fileName');
}

/// Command-line tools revision 15859902.
///
/// Google does not publish a stable checksum API for these zips. The hashes
/// are pinned to that revision and must be updated together with the file name.
const androidCommandLineTools = <String, AndroidToolsArchive>{
  'windows-x64': AndroidToolsArchive(
    fileName: 'commandlinetools-win-15859902_latest.zip',
    sha256: '90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a',
  ),
  'linux-x64': AndroidToolsArchive(
    fileName: 'commandlinetools-linux-15859902_latest.zip',
    sha256: '4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583',
  ),
  'macos-x64': AndroidToolsArchive(
    fileName: 'commandlinetools-mac_x86_64-15859902_latest.zip',
    sha256: 'c5a6378ab5cf7e0d5701921405115befff13e9ff7417fb588389338f8bd050f3',
  ),
  'macos-arm64': AndroidToolsArchive(
    fileName: 'commandlinetools-mac_arm64-15859902_latest.zip',
    sha256: '835b62a26162b229b441d1f6d4680383815a270809eb33522c0d480fa5002c4e',
  ),
};

/// SDK packages installed after cmdline-tools.
const androidSdkPackages = <String>[
  'platform-tools',
  'platforms;android-35',
  'build-tools;35.0.0',
];

/// How many `y` answers are written to `sdkmanager --licenses`.
const licenseAnswers = 80;

/// Looks up the pinned archive for this host.
AndroidToolsArchive androidToolsFor({
  required String operatingSystem,
  required CpuArch arch,
}) {
  final key = '$operatingSystem-${arch.name}';
  final archive = androidCommandLineTools[key];
  if (archive == null) {
    throw CliException('No pinned Android cmdline-tools archive for $key.');
  }
  return archive;
}

/// `sdkmanager` path inside an SDK root.
String sdkManagerPath({
  required String sdkRoot,
  required String operatingSystem,
  required String separator,
}) {
  final executable = operatingSystem == 'windows'
      ? 'sdkmanager.bat'
      : 'sdkmanager';
  return [
    sdkRoot,
    'cmdline-tools',
    'latest',
    'bin',
    executable,
  ].join(separator);
}
