$ErrorActionPreference = 'Stop'

$repo = 'Ag1rin/flutter_easy_setup'
$release = Invoke-RestMethod -Headers @{ 'User-Agent' = 'fes-install' } `
  -Uri "https://api.github.com/repos/$repo/releases/latest"

$assetName = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
  'fes-windows-arm64.exe'
} else {
  'fes-windows-x64.exe'
}

$asset = $release.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
$sumsAsset = $release.assets | Where-Object { $_.name -eq 'SHA256SUMS' } | Select-Object -First 1
if (-not $asset -or -not $sumsAsset) {
  throw "Release is missing $assetName or SHA256SUMS."
}

$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("fes-install-" + [guid]::NewGuid().ToString('n'))
New-Item -ItemType Directory -Path $temp | Out-Null
$binary = Join-Path $temp $assetName
$sumsPath = Join-Path $temp 'SHA256SUMS'
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $binary
Invoke-WebRequest -Uri $sumsAsset.browser_download_url -OutFile $sumsPath

$expected = $null
foreach ($line in Get-Content -LiteralPath $sumsPath) {
  if ($line -match '^([a-fA-F0-9]{64})\s+\*?(.+)$' -and $Matches[2] -eq $assetName) {
    $expected = $Matches[1].ToLower()
  }
}
if (-not $expected) {
  throw "SHA256SUMS has no entry for $assetName."
}
$actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $binary).Hash.ToLower()
if ($actual -ne $expected) {
  Remove-Item -LiteralPath $binary -Force
  throw "Checksum mismatch for $assetName."
}

$destDir = Join-Path $env:LOCALAPPDATA 'fes'
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
$dest = Join-Path $destDir 'fes.exe'
Copy-Item -LiteralPath $binary -Destination $dest -Force
Write-Host "Installed $dest"
Write-Host "Add $destDir to your user PATH, or run: fes path"
