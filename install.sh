#!/bin/sh
set -eu

repo="Ag1rin/flutter_easy_setup"
os=$(uname -s)
arch=$(uname -m)

case "$os-$arch" in
  Darwin-arm64) name="fes-macos-arm64" ;;
  Darwin-x86_64) name="fes-macos-x64" ;;
  Linux-x86_64) name="fes-linux-x64" ;;
  Linux-aarch64) name="fes-linux-arm64" ;;
  *) echo "Unsupported platform: $os $arch" >&2; exit 1 ;;
esac

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
api="https://api.github.com/repos/$repo/releases/latest"
json=$(curl -fsSL -H "User-Agent: fes-install" "$api")
base=$(printf '%s\n' "$json" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
case "$base" in
  v*) ;;
  *) echo "Could not read the release tag." >&2; exit 1 ;;
esac

url="https://github.com/$repo/releases/download/$base/$name"
sums_url="https://github.com/$repo/releases/download/$base/SHA256SUMS"
curl -fsSL "$url" -o "$tmpdir/$name"
curl -fsSL "$sums_url" -o "$tmpdir/SHA256SUMS"

expected=$(awk -v file="$name" '$2 == file { print tolower($1) }' "$tmpdir/SHA256SUMS")
if [ -z "$expected" ]; then
  echo "SHA256SUMS has no entry for $name" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sha256sum "$tmpdir/$name" | awk '{ print tolower($1) }')
else
  actual=$(shasum -a 256 "$tmpdir/$name" | awk '{ print tolower($1) }')
fi

if [ "$actual" != "$expected" ]; then
  echo "Checksum mismatch for $name" >&2
  exit 1
fi

dest="${HOME}/.local/bin"
mkdir -p "$dest"
cp "$tmpdir/$name" "$dest/fes"
chmod +x "$dest/fes"
echo "Installed $dest/fes"
echo "Add $dest to PATH if it is not already there, or run: fes path"
