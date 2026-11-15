import '../models/cli_exception.dart';

/// One problem found in `flutter doctor` output or the local machine.
final class DoctorFinding {
  /// Creates a finding.
  const DoctorFinding({required this.id, required this.summary, this.fix});

  /// Stable id used by fixes and JSON output.
  final String id;

  /// Short explanation.
  final String summary;

  /// Fix id, when this CLI knows one.
  final String? fix;

  /// JSON object for `fes doctor --json`.
  Map<String, Object?> toJson() => {'id': id, 'summary': summary, 'fix': fix};
}

/// A text pattern that maps to a finding.
final class DoctorRule {
  /// Creates a rule.
  const DoctorRule({
    required this.id,
    required this.pattern,
    required this.summary,
    required this.fix,
  });

  /// Finding id.
  final String id;

  /// Case-sensitive substring of doctor output.
  final String pattern;

  /// Text shown to the user.
  final String summary;

  /// Fix id.
  final String fix;
}

/// Known `flutter doctor` messages.
const doctorRules = <DoctorRule>[
  DoctorRule(
    id: 'cmdline-tools',
    pattern: 'cmdline-tools component is missing',
    summary: 'Android cmdline-tools are missing.',
    fix: 'install-android',
  ),
  DoctorRule(
    id: 'licenses',
    pattern: 'Android license status unknown',
    summary: 'Android SDK licenses are not accepted.',
    fix: 'accept-licenses',
  ),
  DoctorRule(
    id: 'startup-lock',
    pattern: 'Waiting for another flutter command to release the startup lock',
    summary: 'A Flutter startup lockfile is blocking commands.',
    fix: 'remove-lock',
  ),
  DoctorRule(
    id: 'android-sdk',
    pattern: 'Unable to locate Android SDK',
    summary: 'ANDROID_HOME is not set to an SDK.',
    fix: 'install-android',
  ),
  DoctorRule(
    id: 'jdk',
    pattern: 'Unable to find bundled Java',
    summary: 'A JDK was not found.',
    fix: 'install-jdk',
  ),
  DoctorRule(
    id: 'chrome',
    pattern: 'Cannot find Chrome',
    summary: 'Chrome was not found for Flutter web.',
    fix: 'install-chrome',
  ),
  DoctorRule(
    id: 'visual-studio',
    pattern: 'Visual Studio not installed',
    summary: 'Visual Studio is required for Windows desktop.',
    fix: 'install-visual-studio',
  ),
  DoctorRule(
    id: 'linux-desktop',
    pattern: 'clang++ is required for Linux development',
    summary: 'Linux desktop build packages are missing.',
    fix: 'install-linux-desktop',
  ),
  DoctorRule(
    id: 'xcode',
    pattern: 'Xcode installation is incomplete',
    summary: 'Xcode command line tools are incomplete.',
    fix: 'install-xcode',
  ),
  DoctorRule(
    id: 'cocoapods',
    pattern: 'CocoaPods not installed',
    summary: 'CocoaPods is not installed.',
    fix: 'install-cocoapods',
  ),
];

/// Returns every rule whose pattern appears in [output].
List<DoctorFinding> parseDoctorOutput(String output) {
  if (output.contains('\x00')) {
    throw const CliException('Doctor output contains a NUL byte.');
  }
  final findings = <DoctorFinding>[];
  final seen = <String>{};
  for (final rule in doctorRules) {
    if (output.contains(rule.pattern) && seen.add(rule.id)) {
      findings.add(
        DoctorFinding(id: rule.id, summary: rule.summary, fix: rule.fix),
      );
    }
  }
  return findings;
}

/// Adds local checks that doctor text does not always include.
List<DoctorFinding> withLocalFindings({
  required List<DoctorFinding> parsed,
  required bool flutterOnPath,
  required bool localFlutterExists,
  required bool lockfileExists,
  required bool javaOnPath,
}) {
  final findings = [...parsed];
  void add(DoctorFinding finding) {
    if (findings.every((item) => item.id != finding.id)) {
      findings.add(finding);
    }
  }

  if (!flutterOnPath && localFlutterExists) {
    add(
      const DoctorFinding(
        id: 'path',
        summary: 'Flutter is installed but not on PATH.',
        fix: 'configure-path',
      ),
    );
  }
  if (!flutterOnPath && !localFlutterExists) {
    add(
      const DoctorFinding(
        id: 'flutter-missing',
        summary: 'Flutter is not installed.',
        fix: 'install-flutter',
      ),
    );
  }
  if (lockfileExists) {
    add(
      const DoctorFinding(
        id: 'startup-lock',
        summary: 'A Flutter startup lockfile is present.',
        fix: 'remove-lock',
      ),
    );
  }
  if (!javaOnPath) {
    add(
      const DoctorFinding(
        id: 'jdk',
        summary: 'java was not found on PATH.',
        fix: 'install-jdk',
      ),
    );
  }
  return findings;
}
