# Generates terminal-style PNG screenshots for README
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$screenshotsDir = Join-Path $PSScriptRoot "..\screenshots"
New-Item -ItemType Directory -Force -Path $screenshotsDir | Out-Null

function New-TerminalScreenshot {
    param(
        [string]$FileName,
        [string[]]$Lines,
        [hashtable]$Colors = @{}
    )

    $fontName = "Cascadia Mono"
    if (-not (Test-Path "C:\Windows\Fonts\cascadiamono.ttf")) {
        $fontName = "Consolas"
    }

    $fontSize = 16
    $padding = 24
    $lineHeight = 26
    $titleBarHeight = 36

    $font = New-Object System.Drawing.Font($fontName, $fontSize)
    $tempBmp = New-Object System.Drawing.Bitmap(1, 1)
    $tempGfx = [System.Drawing.Graphics]::FromImage($tempBmp)
    $maxWidth = 0
    foreach ($line in $Lines) {
        $size = $tempGfx.MeasureString($line, $font)
        if ($size.Width -gt $maxWidth) { $maxWidth = $size.Width }
    }
    $tempGfx.Dispose()
    $tempBmp.Dispose()

    $width = [int]($maxWidth + ($padding * 2) + 40)
    $height = [int]($titleBarHeight + ($Lines.Count * $lineHeight) + ($padding * 2))

    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    $bg = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $titleBg = [System.Drawing.Color]::FromArgb(45, 45, 48)
    $graphics.FillRectangle((New-Object System.Drawing.SolidBrush($bg)), 0, 0, $width, $height)
    $graphics.FillRectangle((New-Object System.Drawing.SolidBrush($titleBg)), 0, 0, $width, $titleBarHeight)

    $dotColors = @(
        [System.Drawing.Color]::FromArgb(255, 95, 86),
        [System.Drawing.Color]::FromArgb(255, 189, 46),
        [System.Drawing.Color]::FromArgb(39, 201, 63)
    )
    for ($i = 0; $i -lt 3; $i++) {
        $brush = New-Object System.Drawing.SolidBrush($dotColors[$i])
        $graphics.FillEllipse($brush, 14 + ($i * 18), 12, 12, 12)
        $brush.Dispose()
    }

    $titleFont = New-Object System.Drawing.Font($fontName, 11)
    $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 180, 180))
    $graphics.DrawString("Flutter Easy Setup CLI", $titleFont, $titleBrush, 70, 10)
    $titleFont.Dispose()
    $titleBrush.Dispose()

    $defaultColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $y = $titleBarHeight + $padding
    foreach ($line in $Lines) {
        $color = $defaultColor
        if ($Colors.ContainsKey($line)) {
            $color = $Colors[$line]
        } elseif ($line -match "Welcome|Flutter Installation Guide|About Flutter") {
            $color = [System.Drawing.Color]::FromArgb(80, 250, 123)
        } elseif ($line -match "Easy Setup CLI") {
            $color = [System.Drawing.Color]::FromArgb(139, 233, 253)
        } elseif ($line -match "Select an option") {
            $color = [System.Drawing.Color]::FromArgb(241, 250, 140)
        } elseif ($line -match "Exiting") {
            $color = [System.Drawing.Color]::FromArgb(80, 250, 123)
        }

        $brush = New-Object System.Drawing.SolidBrush($color)
        $graphics.DrawString($line, $font, $brush, $padding, $y)
        $brush.Dispose()
        $y += $lineHeight
    }

    $outPath = Join-Path $screenshotsDir $FileName
    $bitmap.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
    $font.Dispose()
    Write-Host "Created $outPath"
}

$menuLines = @(
    "  Easy Setup CLI - Version 1.0.6 (Supports Flutter 3.38.5 - December 2025)",
    "",
    "Welcome to Flutter Easy Setup!",
    "Options:",
    "1. Run Flutter Doctor",
    "2. Check Dart, Flutter, and Android SDKs",
    "3. Install missing components or full setup",
    "4. Check and update everything",
    "5. Installation Guide",
    "6. About",
    "0. Exit",
    "",
    "Select an option (0-6):"
)

$guideLines = @(
    "  Easy Setup CLI - Version 1.0.6 (Supports Flutter 3.38.5 - December 2025)",
    "",
    "Flutter Installation Guide (December 2025):",
    "1. Install Git from https://git-scm.com",
    "2. Run this tool -> Option 3 for automatic setup",
    "3. Add flutter/bin to your PATH permanently",
    "4. Run ""flutter doctor"" and fix remaining issues",
    "5. For Android: Licenses are auto-accepted where possible",
    "6. For iOS (macOS): Install Xcode from App Store",
    "Official guide: https://docs.flutter.dev/get-started/install",
    "",
    "Select an option (0-6):"
)

$aboutLines = @(
    "  Easy Setup CLI - Version 1.0.6 (Supports Flutter 3.38.5 - December 2025)",
    "",
    "About Flutter Easy Setup CLI",
    "Version: 1.0.6",
    "Supports Flutter 3.38.5 (Stable - December 2025)",
    "Created by Agirin",
    "GitHub: https://github.com/Ag1rin/flutter_easy_setup",
    "This tool automates Flutter setup and fixes common issues.",
    "Open source - Contributions welcome!",
    "",
    "Select an option (0-6):"
)

New-TerminalScreenshot -FileName "main-menu.png" -Lines $menuLines
New-TerminalScreenshot -FileName "installation-guide.png" -Lines $guideLines
New-TerminalScreenshot -FileName "about.png" -Lines $aboutLines
