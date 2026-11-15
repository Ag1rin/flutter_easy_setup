# Security policy

## Supported versions

Security fixes go into the latest release on the `main` branch.

## Reporting a vulnerability

Open a private GitHub security advisory on this repository. Please include the version, the platform, and a way to reproduce the issue. Do not post exploit details in a public issue.

## What this tool will and will not do

- Downloads use HTTPS and are checked with SHA-256 before extraction.
- Commands run with an argument list, not a shell string.
- PATH, user environment, and shell startup files change only after `--yes` or an explicit confirmation, and a backup is written first.
- There is no telemetry.

## Verifying a release binary

Each GitHub release includes `SHA256SUMS`. Compare it with the file you downloaded before you run it. The install scripts in the repository do this check.
