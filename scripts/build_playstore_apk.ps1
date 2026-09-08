$sourceDir = (Get-Location).Path
$distDir = Join-Path $sourceDir "dist_apk"
$tempWorkDir = "C:\Users\LEGION\AppData\Local\Temp\build_apk_playstore"
$symbolsDir = "C:\Users\LEGION\AppData\Local\Temp\meowtang_debug_symbols"

if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Force -Path $distDir | Out-Null
}
if (-not (Test-Path $symbolsDir)) {
    New-Item -ItemType Directory -Force -Path $symbolsDir | Out-Null
}

$targetApk = Join-Path $distDir "MeowTang-PlayStore-v1.41.2.apk"

Write-Host "=== Building MeowTang PLAY STORE Edition (Freemium + Obfuscation) ===" -ForegroundColor Green
Write-Host "Source directory: $sourceDir"
Write-Host "Destination APK:  $targetApk"

Write-Host "1. Cleaning old temp directory if exists..."
Set-Location "C:\"
if (Test-Path $tempWorkDir) {
    Remove-Item -Recurse -Force $tempWorkDir
}

Write-Host "2. Copying project files to fast compilation drive (C:)..."
New-Item -ItemType Directory -Force -Path $tempWorkDir | Out-Null
& robocopy $sourceDir $tempWorkDir /E /XD build .dart_tool .git .gradle .idea dist_apk /XF *.apk /NFL /NDL /NJH /NJS /nc /ns /np

Write-Host "3. Resolving dependencies in temp work dir..."
Set-Location $tempWorkDir
flutter pub get

Write-Host "4. Compiling PLAY STORE release APK with Obfuscation (--dart-define=APP_EDITION=playstore)..."
flutter build apk --release --no-tree-shake-icons --android-skip-build-dependency-validation --dart-define=APP_EDITION=playstore --obfuscate --split-debug-info=$symbolsDir

$builtApk = Join-Path $tempWorkDir "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $builtApk) {
    Copy-Item -Force $builtApk $targetApk
    $apkItem = Get-Item $targetApk
    $apkSizeMB = [math]::Round($apkItem.Length / 1MB, 2)
    Write-Host "SUCCESS! PLAY STORE APK created at $targetApk ($apkSizeMB MB)" -ForegroundColor Cyan
} else {
    Write-Error "Build failed: app-release.apk not found at $builtApk"
}

Write-Host "5. Cleaning up temp compilation folder..."
Set-Location "C:\"
if (Test-Path $tempWorkDir) {
    Remove-Item -Recurse -Force $tempWorkDir
}
Set-Location $sourceDir
Write-Host "Play Store Build Complete!" -ForegroundColor Green
