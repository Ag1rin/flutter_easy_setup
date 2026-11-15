import 'dart:io';

import 'cli_exception.dart';
import 'cpu_arch.dart';

/// Host operating system and CPU architecture.
final class OsInfo {
  /// Creates host information that has already been validated.
  const OsInfo({required this.operatingSystem, required this.arch});

  /// `windows`, `macos`, or `linux`.
  final String operatingSystem;

  /// CPU architecture of this process.
  final CpuArch arch;

  /// Reads the current host.
  factory OsInfo.current() {
    return OsInfo(
      operatingSystem: normalizeOs(Platform.operatingSystem),
      arch: currentCpuArch(),
    );
  }
}

/// Accepts only the three operating systems this CLI supports.
String normalizeOs(String operatingSystem) {
  return switch (operatingSystem) {
    'windows' || 'macos' || 'linux' => operatingSystem,
    _ => throw CliException('Unsupported operating system: $operatingSystem.'),
  };
}
