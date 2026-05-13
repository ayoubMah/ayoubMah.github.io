#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

# === CONFIG ===
$VaultRoot    = "$env:USERPROFILE\OneDrive - KPIWEB\Bureau\ayoubObs"
$BlogFolder   = "$VaultRoot\blog"
$ObsidianBlog = "$BlogFolder\BLOG"
$ObsidianIlt  = "$BlogFolder\ILT"
$Attachments  = "$VaultRoot\attachments"

$HugoRepo      = "$BlogFolder\ayoubMah.github.io"
$HugoPosts     = "$HugoRepo\content\posts"
$HugoiLt       = "$HugoRepo\content\ilt"
$StaticImages  = "$HugoRepo\static\images"

$HugoTheme     = "hello-friend-ng"

Write-Host "=== Pulling latest blog content ==="
Set-Location -LiteralPath $HugoRepo
git pull --rebase --autostash
if (-not $?) { throw "git pull failed" }

# Ensure target dirs exist
foreach ($d in $ObsidianBlog, $ObsidianIlt, $HugoPosts, $HugoiLt, $StaticImages) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}

Write-Host "=== Syncing BLOG -> content/posts ==="
if (Test-Path -Path $ObsidianBlog) {
    Copy-Item -Path "$ObsidianBlog\*" -Destination $HugoPosts -Recurse -Force
}

Write-Host "=== Syncing ILT -> content/ilt ==="
if (Test-Path -Path $ObsidianIlt) {
    Copy-Item -Path "$ObsidianIlt\*" -Destination $HugoiLt -Recurse -Force
}

Write-Host "=== Processing Obsidian image links and copying images ==="
$imgPattern = [regex]'!?\[\[([^\]|]*\.(?:png|jpg|jpeg|gif|webp|svg|ico))(?:\|[^\]]*)?\]\]'

foreach ($rootDir in @($HugoPosts, $HugoiLt)) {
    if (-not (Test-Path -LiteralPath $rootDir)) { continue }
    Get-ChildItem -LiteralPath $rootDir -Recurse -Filter *.md | ForEach-Object {
        $fpath = $_.FullName
        $content = Get-Content -LiteralPath $fpath -Raw -Encoding UTF8
        $modified = $false

        $matches = $imgPattern.Matches($content)
        foreach ($match in $matches) {
            $imgName = Split-Path -Leaf $match.Groups[1].Value
            $altText = [System.IO.Path]::GetFileNameWithoutExtension($imgName)
            $mdImg   = "![$altText](/images/$($imgName -replace ' ', '%20'))"
            $content = $content -replace [regex]::Escape($match.Value), $mdImg
            $modified = $true

            $src = Join-Path -LiteralPath $Attachments -ChildPath $imgName
            if (Test-Path -LiteralPath $src) {
                Copy-Item -LiteralPath $src -Destination $StaticImages -Force
            }
        }

        if ($modified) {
            Set-Content -LiteralPath $fpath -Value $content -Encoding UTF8 -NoNewline
        }
    }
}

Write-Host "=== Building site with Hugo ==="
Set-Location -LiteralPath $HugoRepo
hugo -t $HugoTheme --minify

Write-Host "=== Committing and pushing to master ==="
git add .
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$commitOutput = git commit -m "Auto-publish: $date" 2>&1
if ($LASTEXITCODE -eq 0) {
    git push origin master
} else {
    Write-Host "Nothing to commit - no changes."
}

Write-Host "=== Blog published successfully! ==="
