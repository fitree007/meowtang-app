# deploy_web.ps1
# Automates publishing docs/ folder to gh-pages branch and pushing to GitHub Pages
$ErrorActionPreference = "Stop"
Write-Host "🚀 Deploying web build to gh-pages branch..."
$tree = (git rev-parse main:docs).Trim()
$versionMatch = (Get-Content pubspec.yaml | Select-String "^version:\s*([^\+]+)").Matches
$version = if ($versionMatch) { $versionMatch.Groups[1].Value.Trim() } else { "latest" }
$commit = (git commit-tree $tree -p origin/gh-pages -m "Deploy v$version to GitHub Pages").Trim()
git update-ref refs/heads/gh-pages $commit
git push origin gh-pages
Write-Host "✅ Deployed v$version to GitHub Pages (gh-pages) successfully!"
