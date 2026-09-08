$sourceDir = (Get-Location).Path
$distDir = Join-Path $sourceDir "dist_apk"
$tempWorkDir = "C:\Users\LEGION\AppData\Local\Temp\build_apk_creator"

if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Force -Path $distDir | Out-Null
}

$targetApk = Join-Path $distDir "MeowTang-Creator-v1.41.3.apk"

Write-Host "=== Building MeowTang CREATOR Edition (Full Unlimited VIP) ===" -ForegroundColor Green
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

Write-Host "4. Compiling CREATOR release APK (--dart-define=APP_EDITION=creator)..."
flutter build apk --release --no-tree-shake-icons --android-skip-build-dependency-validation --dart-define=APP_EDITION=creator

$builtApk = Join-Path $tempWorkDir "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $builtApk) {
    Copy-Item -Force $builtApk $targetApk
    $apkItem = Get-Item $targetApk
    $apkSizeMB = [math]::Round($apkItem.Length / 1MB, 2)
    Write-Host "SUCCESS! CREATOR APK created at $targetApk ($apkSizeMB MB)" -ForegroundColor Cyan
} else {
    Write-Error "Build failed: app-release.apk not found at $builtApk"
}

Write-Host "5. Cleaning up temp compilation folder..."
Set-Location "C:\"
if (Test-Path $tempWorkDir) {
    Remove-Item -Recurse -Force $tempWorkDir
}
Set-Location $sourceDir
Write-Host "Creator Build Complete!" -ForegroundColor Green
