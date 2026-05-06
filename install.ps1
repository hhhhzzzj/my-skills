<#
.SYNOPSIS
  Install my-claude-skills on Windows.

.DESCRIPTION
  Clones the repo to %LOCALAPPDATA%\my-claude-skills (or pulls if it already exists),
  then creates Junctions from each skills/<name> directory into ~/.claude/skills/.

.EXAMPLE
  Remote one-liner:
    irm https://raw.githubusercontent.com/hhhhzzzj/my-skills/main/install.ps1 | iex

  Local:
    .\install.ps1
#>

$ErrorActionPreference = 'Stop'

$Repo        = 'hhhhzzzj/my-skills'
$InstallDir  = Join-Path $env:LOCALAPPDATA 'my-claude-skills'
$SkillsDir   = Join-Path $env:USERPROFILE '.claude\skills'

Write-Host "==> my-claude-skills installer" -ForegroundColor Cyan

# 1. Check git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Error "git is required but not found in PATH. Install Git first: https://git-scm.com/"
  exit 1
}

# 2. Clone or update
if (Test-Path $InstallDir) {
  Write-Host "[1/3] Updating existing install at $InstallDir"
  git -C $InstallDir pull --ff-only | Out-Host
} else {
  Write-Host "[1/3] Cloning $Repo to $InstallDir"
  git clone --depth=1 "https://github.com/$Repo.git" $InstallDir | Out-Host
}

# 3. Ensure ~/.claude/skills exists
Write-Host "[2/3] Ensuring $SkillsDir exists"
New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null

# Helper: is this entry a junction/symlink whose target lives under our InstallDir?
function Test-IsOurLink {
  param([string]$Path, [string]$ExpectedRoot)
  $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  if (-not $item) { return $false }
  if ($item.LinkType -notin @('Junction', 'SymbolicLink')) { return $false }
  $target = $item.Target
  if (-not $target) { return $false }
  # $item.Target is an array on PS 7+, string on PS 5
  if ($target -is [array]) { $target = $target[0] }
  return $target.TrimEnd('\') -like "$($ExpectedRoot.TrimEnd('\'))\*"
}

# 4. Link each skill (idempotent + safe)
Write-Host "[3/3] Syncing skills"
$srcRoot = Join-Path $InstallDir 'skills'
$skills  = Get-ChildItem $srcRoot -Directory -ErrorAction SilentlyContinue
if (-not $skills) {
  Write-Warning "No skills found under $srcRoot. Did the clone succeed?"
  exit 1
}
$repoNames = $skills | ForEach-Object { $_.Name }

# 4a. Clean up stale links: ours but the skill is no longer in the repo
$existing = Get-ChildItem $SkillsDir -Force -ErrorAction SilentlyContinue
foreach ($e in $existing) {
  if ((Test-IsOurLink -Path $e.FullName -ExpectedRoot $srcRoot) -and ($e.Name -notin $repoNames)) {
    cmd /c rmdir "$($e.FullName)" 2>$null | Out-Null
    Write-Host "  - $($e.Name) (removed: no longer in repo)" -ForegroundColor DarkYellow
  }
}

# 4b. Link / skip / warn each repo skill
$counts = @{ added = 0; kept = 0; skipped = 0 }
foreach ($s in $skills) {
  $linkPath = Join-Path $SkillsDir $s.Name

  if (-not (Test-Path -LiteralPath $linkPath)) {
    cmd /c mklink /J "$linkPath" "$($s.FullName)" | Out-Null
    Write-Host "  + $($s.Name)" -ForegroundColor Green
    $counts.added++
  }
  elseif (Test-IsOurLink -Path $linkPath -ExpectedRoot $srcRoot) {
    # Already a link pointing into our install dir — git pull has already updated content, no action needed
    Write-Host "  = $($s.Name) (already linked, content updated via git pull)" -ForegroundColor DarkGray
    $counts.kept++
  }
  else {
    # Some other directory or link to elsewhere — protect the user's existing entry
    Write-Warning "  ! $($s.Name) (skipped: $linkPath exists and is NOT managed by my-claude-skills)"
    $counts.skipped++
  }
}

Write-Host ""
Write-Host ("Done. {0} new, {1} already linked, {2} skipped." -f $counts.added, $counts.kept, $counts.skipped) -ForegroundColor Cyan
if ($counts.skipped -gt 0) {
  Write-Host "  -> To replace a skipped one with my-claude-skills' version: remove that path manually, then re-run." -ForegroundColor DarkYellow
}
Write-Host "Installed location: $InstallDir"
Write-Host "Linked to:          $SkillsDir"
Write-Host "Restart Claude Code (or reload skills) to pick them up."
