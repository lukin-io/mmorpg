# Local disk save for neverlands-mmorpg (GitHub optional).
# Saves to: %USERPROFILE%\tidekeep-local-save\

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
  throw "Not a git repo: $RepoRoot"
}

$SaveRoot = Join-Path $env:USERPROFILE "tidekeep-local-save"
$Bundles = Join-Path $SaveRoot "bundles"
$Snapshots = Join-Path $SaveRoot "snapshots"
$Notes = Join-Path $SaveRoot "notes"
@( $SaveRoot, $Bundles, $Snapshots, $Notes ) | ForEach-Object {
  New-Item -ItemType Directory -Force -Path $_ | Out-Null
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
Set-Location $RepoRoot

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
$head = (git rev-parse --short HEAD).Trim()
$status = git status -sb | Out-String

$bundleName = "neverlands-mmorpg-$stamp-$head.bundle"
$bundlePath = Join-Path $Bundles $bundleName
git bundle create $bundlePath --all
if (-not (Test-Path $bundlePath)) { throw "Bundle was not created" }

$latestBundle = Join-Path $Bundles "neverlands-mmorpg-LATEST.bundle"
Copy-Item -Force $bundlePath $latestBundle

$snapDir = Join-Path $Snapshots $stamp
New-Item -ItemType Directory -Force -Path $snapDir | Out-Null

$overnight = Join-Path $RepoRoot "OVERNIGHT.md"
if (Test-Path $overnight) {
  Copy-Item -Force $overnight (Join-Path $snapDir "OVERNIGHT.md")
}

$statusPath = Join-Path $snapDir "git-status.txt"
@"
saved_at: $(Get-Date -Format o)
repo: $RepoRoot
branch: $branch
head: $head
bundle: $bundlePath

$status
"@ | Set-Content -Encoding UTF8 -Path $statusPath

$pointer = Join-Path $Notes "LAST_SAVE.txt"
@"
last_save: $(Get-Date -Format o)
branch: $branch
head: $head
bundle: $bundleName
latest_alias: neverlands-mmorpg-LATEST.bundle
repo_on_disk: $RepoRoot
"@ | Set-Content -Encoding UTF8 -Path $pointer

# Keep at most 20 dated bundles (plus LATEST)
$old = Get-ChildItem $Bundles -Filter "neverlands-mmorpg-*.bundle" |
  Where-Object { $_.Name -ne "neverlands-mmorpg-LATEST.bundle" } |
  Sort-Object LastWriteTime -Descending |
  Select-Object -Skip 20
$old | Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host "LOCAL SAVE OK"
Write-Host "  folder:  $SaveRoot"
Write-Host "  bundle:  $bundlePath"
Write-Host "  latest:  $latestBundle"
Write-Host "  head:    $head ($branch)"
