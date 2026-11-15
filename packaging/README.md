# Package manifests

These files are templates for winget, Scoop, and Homebrew. Replace every
`0000000000000000000000000000000000000000000000000000000000000000` hash with
the matching line from the GitHub release `SHA256SUMS` before submitting them
upstream. The install scripts `install.ps1` and `install.sh` download
`SHA256SUMS` and check it, so they do not need a baked-in hash.
