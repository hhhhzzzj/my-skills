<#
.SYNOPSIS
  Install my-claude-skills on Windows.

.DESCRIPTION
  Clones the repo to %LOCALAPPDATA%\my-claude-skills (or pulls if it already exists),
  creates Junctions from each skills/<name> directory into ~/.claude/skills/,
  and copies real directories into ~/.codeium/windsurf/skills/ for Windsurf.

.EXAMPLE
  Remote one-liner:
    irm https://raw.githubusercontent.com/hhhhzzzj/my-skills/main/install.ps1 | iex

  Local:
    .\install.ps1
#>

$ErrorActionPreference = 'Stop'

$Repo              = 'hhhhzzzj/my-skills'
$InstallDir        = Join-Path $env:LOCALAPPDATA 'my-claude-skills'
$ClaudeSkillsDir   = Join-Path $env:USERPROFILE '.claude\skills'
$WindsurfSkillsDir = Join-Path $env:USERPROFILE '.codeium\windsurf\skills'

Write-Host "==> my-claude-skills installer" -ForegroundColor Cyan

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Error "git is required but not found in PATH. Install Git first: https://git-scm.com/"
  exit 1
}

if (Test-Path $InstallDir) {
  Write-Host "[1/4] Updating existing install at $InstallDir"
  git -C $InstallDir pull --ff-only | Out-Host
} else {
  Write-Host "[1/4] Cloning $Repo to $InstallDir"
  git clone --depth=1 "https://github.com/$Repo.git" $InstallDir | Out-Host
}

Write-Host "[2/4] Ensuring target directories exist"
New-Item -ItemType Directory -Force -Path $ClaudeSkillsDir | Out-Null
New-Item -ItemType Directory -Force -Path $WindsurfSkillsDir | Out-Null

function Test-IsOurLink {
  param([string]$Path, [string]$ExpectedRoot)
  $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  if (-not $item) { return $false }
  if ($item.LinkType -notin @('Junction', 'SymbolicLink')) { return $false }
  $target = $item.Target
  if (-not $target) { return $false }
  if ($target -is [array]) { $target = $target[0] }
  return $target.TrimEnd('\') -like "$($ExpectedRoot.TrimEnd('\'))\*"
}

function Test-IsOurCopy {
  param([string]$Path)
  $marker = Join-Path $Path '.my-claude-skills-managed'
  return (Test-Path -LiteralPath $marker)
}

$srcRoot = Join-Path $InstallDir 'skills'
$skills  = Get-ChildItem $srcRoot -Directory -ErrorAction SilentlyContinue
if (-not $skills) {
  Write-Warning "No skills found under $srcRoot. Did the clone succeed?"
  exit 1
}
$repoNames = $skills | ForEach-Object { $_.Name }

Write-Host "[3/4] Syncing Claude Code skills"
$existing = Get-ChildItem $ClaudeSkillsDir -Force -ErrorAction SilentlyContinue
foreach ($e in $existing) {
  if ((Test-IsOurLink -Path $e.FullName -ExpectedRoot $srcRoot) -and ($e.Name -notin $repoNames)) {
    cmd /c rmdir "$($e.FullName)" 2>$null | Out-Null
    Write-Host "  - $($e.Name) (removed: no longer in repo)" -ForegroundColor DarkYellow
  }
}

$claudeCounts = @{ added = 0; kept = 0; skipped = 0 }
foreach ($s in $skills) {
  $linkPath = Join-Path $ClaudeSkillsDir $s.Name
  if (-not (Test-Path -LiteralPath $linkPath)) {
    cmd /c mklink /J "$linkPath" "$($s.FullName)" | Out-Null
    Write-Host "  + $($s.Name)" -ForegroundColor Green
    $claudeCounts.added++
  }
  elseif (Test-IsOurLink -Path $linkPath -ExpectedRoot $srcRoot) {
    Write-Host "  = $($s.Name) (already linked, content updated via git pull)" -ForegroundColor DarkGray
    $claudeCounts.kept++
  }
  else {
    Write-Warning "  ! $($s.Name) (skipped: $linkPath exists and is NOT managed by my-claude-skills)"
    $claudeCounts.skipped++
  }
}

Write-Host "[4/4] Syncing Windsurf skills"
$existing = Get-ChildItem $WindsurfSkillsDir -Force -ErrorAction SilentlyContinue
foreach ($e in $existing) {
  if ((Test-IsOurCopy -Path $e.FullName) -and ($e.Name -notin $repoNames)) {
    Remove-Item $e.FullName -Recurse -Force
    Write-Host "  - $($e.Name) (removed: no longer in repo)" -ForegroundColor DarkYellow
  }
}

$windsurfCounts = @{ added = 0; updated = 0; skipped = 0 }
foreach ($s in $skills) {
  $copyPath = Join-Path $WindsurfSkillsDir $s.Name
  if (-not (Test-Path -LiteralPath $copyPath)) {
    Copy-Item $s.FullName $copyPath -Recurse
    New-Item -ItemType File -Path (Join-Path $copyPath '.my-claude-skills-managed') -Force | Out-Null
    Write-Host "  + $($s.Name)" -ForegroundColor Green
    $windsurfCounts.added++
  }
  elseif (Test-IsOurCopy -Path $copyPath) {
    Remove-Item $copyPath -Recurse -Force
    Copy-Item $s.FullName $copyPath -Recurse
    New-Item -ItemType File -Path (Join-Path $copyPath '.my-claude-skills-managed') -Force | Out-Null
    Write-Host "  = $($s.Name) (copied latest content)" -ForegroundColor DarkGray
    $windsurfCounts.updated++
  }
  else {
    Write-Warning "  ! $($s.Name) (skipped: $copyPath exists and is NOT managed by my-claude-skills)"
    $windsurfCounts.skipped++
  }
}

Write-Host ""
Write-Host ("Claude Code: {0} new, {1} already linked, {2} skipped." -f $claudeCounts.added, $claudeCounts.kept, $claudeCounts.skipped) -ForegroundColor Cyan
Write-Host ("Windsurf:    {0} new, {1} updated, {2} skipped." -f $windsurfCounts.added, $windsurfCounts.updated, $windsurfCounts.skipped) -ForegroundColor Cyan
if (($claudeCounts.skipped + $windsurfCounts.skipped) -gt 0) {
  Write-Host "  -> To replace a skipped one with my-claude-skills' version: remove that path manually, then re-run." -ForegroundColor DarkYellow
}
Write-Host "Installed location: $InstallDir"
Write-Host "Claude linked to:   $ClaudeSkillsDir"
Write-Host "Windsurf copied to: $WindsurfSkillsDir"
Write-Host "Restart Claude Code / Windsurf (or reload skills) to pick them up."
