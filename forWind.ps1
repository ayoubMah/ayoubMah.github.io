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
$TrackingFile  = "$HugoRepo\.sync-cache.json"

Write-Host "=== 1. Pulling latest content from git ==="
Set-Location -Path $HugoRepo
git pull --rebase --autostash
if (-not $?) { throw "git pull failed" }

foreach ($d in $ObsidianBlog, $ObsidianIlt, $HugoPosts, $HugoiLt, $StaticImages) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}

# Load previous vault snapshot
$prev = @{}
if (Test-Path -Path $TrackingFile) {
    $prev = Get-Content -Path $TrackingFile -Raw -Encoding UTF8 | ConvertFrom-Json
}

# Current vault files
$vault = @{}
Get-ChildItem -Path $ObsidianBlog -Recurse -File -Filter *.md | ForEach-Object {
    $rel = $_.FullName.Substring($ObsidianBlog.Length).TrimStart('\')
    $vault[$rel] = $true
}
Get-ChildItem -Path $ObsidianIlt -Recurse -File -Filter *.md | ForEach-Object {
    $rel = $_.FullName.Substring($ObsidianIlt.Length).TrimStart('\')
    $vault["ilt/$rel"] = $true
}

# Find files deleted from vault since last run and remove from content
Write-Host "=== 2. Removing deleted posts ==="
$prev.PSObject.Properties | ForEach-Object {
    $rel = $_.Name
    if (-not $vault.ContainsKey($rel)) {
        $contentPath = Join-Path -Path $HugoRepo -ChildPath "content/$rel"
        if (Test-Path -Path $contentPath) {
            Remove-Item -Path $contentPath -Force
            Write-Host "  Removed: $rel"
        }
    }
}

# Copy new files from git -> vault (so user sees them)
Write-Host "=== 3. Syncing new git content to vault ==="
Get-ChildItem -Path $HugoPosts -Recurse -File -Filter *.md | ForEach-Object {
    $rel = $_.FullName.Substring($HugoPosts.Length).TrimStart('\')
    $vaultPath = Join-Path -Path $ObsidianBlog -ChildPath $rel
    if (-not (Test-Path -Path $vaultPath)) {
        $dir = Split-Path -Parent $vaultPath
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Copy-Item -Path $_.FullName -Destination $vaultPath
        Write-Host "  New in vault: posts/$rel"
    }
}
Get-ChildItem -Path $HugoiLt -Recurse -File -Filter *.md | ForEach-Object {
    $rel = $_.FullName.Substring($HugoiLt.Length).TrimStart('\')
    $vaultPath = Join-Path -Path $ObsidianIlt -ChildPath $rel
    if (-not (Test-Path -Path $vaultPath)) {
        $dir = Split-Path -Parent $vaultPath
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Copy-Item -Path $_.FullName -Destination $vaultPath
        Write-Host "  New in vault: ilt/$rel"
    }
}

# Copy vault -> content (add/update all vault files)
Write-Host "=== 4. Copying vault files to content ==="
Copy-Item -Path "$ObsidianBlog\*" -Destination $HugoPosts -Recurse -Force
Copy-Item -Path "$ObsidianIlt\*" -Destination $HugoiLt -Recurse -Force

# Save current vault snapshot (re-read after all syncs)
$vault = @{}
Get-ChildItem -Path $ObsidianBlog -Recurse -File -Filter *.md | ForEach-Object {
    $rel = $_.FullName.Substring($ObsidianBlog.Length).TrimStart('\')
    $vault[$rel] = $true
}
Get-ChildItem -Path $ObsidianIlt -Recurse -File -Filter *.md | ForEach-Object {
    $rel = $_.FullName.Substring($ObsidianIlt.Length).TrimStart('\')
    $vault["ilt/$rel"] = $true
}
$vault | ConvertTo-Json | Set-Content -Path $TrackingFile -Encoding UTF8

Write-Host "=== 5. Processing Obsidian image links ==="
$imgPattern = [regex]'!?\[\[([^\]|]*\.(?:png|jpg|jpeg|gif|webp|svg|ico))(?:\|[^\]]*)?\]\]'

foreach ($rootDir in @($HugoPosts, $HugoiLt)) {
    if (-not (Test-Path -Path $rootDir)) { continue }
    Get-ChildItem -Path $rootDir -Recurse -Filter *.md | ForEach-Object {
        $fpath = $_.FullName
        $content = Get-Content -Path $fpath -Raw -Encoding UTF8
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
            Set-Content -Path $fpath -Value $content -Encoding UTF8 -NoNewline
        }
    }
}

Write-Host "=== 6. Building with Hugo ==="
Set-Location -Path $HugoRepo
hugo -t $HugoTheme --minify

Write-Host "=== 7. Committing and pushing ==="
git add .
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$commitOutput = git commit -m "Auto-publish: $date" 2>&1
if ($LASTEXITCODE -eq 0) {
    git push origin master
} else {
    Write-Host "Nothing to commit - no changes."
}

Write-Host "=== Done! ==="
