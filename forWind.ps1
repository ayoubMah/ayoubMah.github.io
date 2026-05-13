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

# --- Two-way sync ---
# 1. Git -> Vault: copy new/changed files FROM git TO vault (never delete from vault)
Write-Host "=== Syncing git -> vault ==="
if (Test-Path -Path $HugoPosts) {
    Copy-Item -Path "$HugoPosts\*" -Destination $ObsidianBlog -Recurse -Force
}
if (Test-Path -Path $HugoiLt) {
    Copy-Item -Path "$HugoiLt\*" -Destination $ObsidianIlt -Recurse -Force
}

# 2. Vault -> Content: mirror vault onto content (handles adds, edits, AND deletes)
Write-Host "=== Syncing vault -> content (with mirror) ==="
if (Test-Path -Path $ObsidianBlog) {
    robocopy "$ObsidianBlog" "$HugoPosts" /MIR /NJH /NJS /NDL /NP > $null
}
if (Test-Path -Path $ObsidianIlt) {
    robocopy "$ObsidianIlt" "$HugoiLt" /MIR /NJH /NJS /NDL /NP > $null
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

            $src = Join-Path -Path $Attachments -ChildPath $imgName
            if (Test-Path -Path $src) {
                Copy-Item -Path $src -Destination $StaticImages -Force
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
