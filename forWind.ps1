#!/usr/bin/env pwsh
# Publish the blog from Windows. Same steps as forLinux.sh; the sync logic lives in sync.py.
$ErrorActionPreference = "Stop"

# === CONFIG === (paths are derived from where this repo sits inside the vault)
$HugoRepo     = $PSScriptRoot
$BlogFolder   = Split-Path -Parent $HugoRepo
$VaultRoot    = Split-Path -Parent $BlogFolder
$ObsidianBlog = Join-Path $BlogFolder "BLOG"
$ObsidianIlt  = Join-Path $BlogFolder "ILT"
$Attachments  = Join-Path $VaultRoot "attachments"

function Invoke-Step([string]$What, [scriptblock]$Cmd) {
    # git/hugo write progress to stderr; with "Stop", PowerShell 5.1 turns that into
    # an error whenever output is redirected. Judge native commands by exit code only.
    $ErrorActionPreference = "Continue"
    & $Cmd
    if ($LASTEXITCODE -ne 0) { throw "$What failed (exit $LASTEXITCODE) - nothing was pushed." }
}

Set-Location -Path $HugoRepo

Write-Host "=== 1. Pulling latest from GitHub (other machine's posts/edits/deletes) ==="
Invoke-Step "git pull"   { git pull --rebase --autostash origin master }
Invoke-Step "submodule"  { git submodule update --init --recursive }

Write-Host "=== 2. Syncing vault <-> content ==="
Invoke-Step "sync.py" { python "$HugoRepo\sync.py" --repo "$HugoRepo" --blog "$ObsidianBlog" --ilt "$ObsidianIlt" --attachments "$Attachments" }

Write-Host "=== 3. Test build with Hugo (GitHub Actions does the real build) ==="
Invoke-Step "hugo build" { hugo --minify }

Write-Host "=== 4. Committing and pushing ==="
git add -A
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "Nothing to publish - no changes."
} else {
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Invoke-Step "git commit" { git commit -m "Auto-publish (windows): $date" }
    Invoke-Step "git push"   { git push origin master }
}

Write-Host "=== Done! ==="
