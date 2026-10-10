# Builds the Google Play edition as a signed App Bundle (.aab) for Play Console.
# Run from the project folder:  powershell -ExecutionPolicy Bypass -File scripts/build_playstore_bundle.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path 'android\key.properties')) {
    Write-Error 'android\key.properties not found. Create the upload key first (see android\key.properties.example).'
}

$version = (Select-String -Path pubspec.yaml -Pattern '^version:\s*(\S+)').Matches[0].Groups[1].Value
$name = ($version -split '\+')[0]
$outDir = Join-Path $root 'releases\playstore'
$symbols = Join-Path $outDir "symbols-v$name"
New-Item -ItemType Directory -Force $outDir, $symbols | Out-Null

Write-Host "Building MeowTang Play Store v$version ..." -ForegroundColor Green
flutter build appbundle --release --no-tree-shake-icons --android-skip-build-dependency-validation `
    --dart-define=APP_EDITION=playstore --obfuscate --split-debug-info=$symbols
if ($LASTEXITCODE -ne 0) { Write-Error 'Build failed' }

# Keep only the newest bundle next to the listing files; older ones go to releases\old.
Get-ChildItem $outDir -Filter 'MeowTang-PlayStore-v*.aab' | Move-Item -Destination (Join-Path $root 'releases\old') -Force
$aab = Join-Path $outDir "MeowTang-PlayStore-v$name.aab"
Copy-Item 'build\app\outputs\bundle\release\app-release.aab' $aab -Force
Write-Host "Done: $aab" -ForegroundColor Cyan
Write-Host "Keep $symbols : the code is obfuscated, and this folder is needed to read its crash reports (flutter symbolize)."
