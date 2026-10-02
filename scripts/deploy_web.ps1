# deploy_web.ps1
# Automates compiling Flutter Web, syncing to docs/, and publishing to gh-pages
$ErrorActionPreference = "Stop"

Write-Host "Syncing build/web to docs/..."
if (Test-Path "build\web") {
    Copy-Item "build\web\*" "docs\" -Recurse -Force
}

Write-Host "Deploying web build to gh-pages branch..."
git add docs/
$line = (Get-Content pubspec.yaml | Select-String "version:").Line
$version = ($line -split ':')[1].Trim().Split('+')[0].Trim()
git commit -m "chore: update web build in docs to v$version" -q --allow-empty
git push origin main

$tree = (git rev-parse main:docs).Trim()
$commit = (git commit-tree $tree -p origin/gh-pages -m "Deploy v$version to GitHub Pages").Trim()
git update-ref refs/heads/gh-pages $commit
git push origin gh-pages
Write-Host "Deployed v$version to GitHub Pages successfully!"

