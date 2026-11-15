import 'dart:ffi';

import 'cli_exception.dart';

/// CPU architecture of a Flutter SDK archive.
enum CpuArch {
  /// 64-bit x86.
  x64,

  /// 64-bit ARM.
  arm64,
}

/// Reads the CPU architecture of this process.
CpuArch currentCpuArch() {
  return switch (Abi.current()) {
    Abi.windowsX64 || Abi.linuxX64 || Abi.macosX64 => CpuArch.x64,
    Abi.windowsArm64 || Abi.linuxArm64 || Abi.macosArm64 => CpuArch.arm64,
    _ => throw CliException('Unsupported CPU architecture: ${Abi.current()}.'),
  };
}

/// Parses `x64` or `arm64`.
CpuArch parseCpuArch(String value) {
  return switch (value) {
    'x64' => CpuArch.x64,
    'arm64' => CpuArch.arm64,
    _ => throw CliException('Architecture must be x64 or arm64.'),
  };
}
