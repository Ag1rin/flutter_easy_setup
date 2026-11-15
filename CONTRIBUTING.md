# Contributing

Thanks for helping make Flutter setup less painful.

## Setup

```bash
dart pub get
dart format --set-exit-if-changed .
dart analyze
dart test
```

## Pull requests

- Keep the interactive menu options 0-6 working.
- Add a unit test for logic changes. Do not call the network from tests.
- Use Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`.
- Update `CHANGELOG.md` for user-visible changes.
- Do not add telemetry.

PATH, registry, and shell-profile changes need a confirmation path and a `--dry-run`.
