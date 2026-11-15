# Roadmap

## Good first issues

- Add another locale next to `lib/src/i18n/en.dart` and `lib/src/i18n/fa.dart`.
- Add a doctor rule for a `flutter doctor` line that is not mapped yet.
- Document a new opt-in mirror in `config/mirrors.example.yaml`. The official mirror must stay the default.
- Fill the SHA-256 values in `packaging/` from a published `SHA256SUMS` file before submitting those manifests upstream.

## Later

- Windows and Linux Flutter SDK indexes currently publish x64 archives only. `fes install --arch x64` is the explicit override until upstream publishes arm64 archives.
- Code signing for Windows and macOS binaries.
