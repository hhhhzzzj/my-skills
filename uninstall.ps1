<#
.SYNOPSIS
  Uninstall my-claude-skills (Windows): remove managed Claude Code Junctions, managed Windsurf copies, and the install dir.
#>

$ErrorActionPreference = 'Stop'

$InstallDir        = Join-Path $env:LOCALAPPDATA 'my-claude-skills'
$ClaudeSkillsDir   = Join-Path $env:USERPROFILE '.claude\skills'
$WindsurfSkillsDir = Join-Path $env:USERPROFILE '.codeium\windsurf\skills'

if (-not (Test-Path $InstallDir)) {
  Write-Host "Not installed at $InstallDir. Nothing to do."
  exit 0
}

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
  return (Test-Path -LiteralPath (Join-Path $Path '.my-claude-skills-managed'))
}

$srcRoot = Join-Path $InstallDir 'skills'
$skills = Get-ChildItem $srcRoot -Directory -ErrorAction SilentlyContinue
foreach ($s in $skills) {
  $linkPath = Join-Path $ClaudeSkillsDir $s.Name
  if (Test-IsOurLink -Path $linkPath -ExpectedRoot $srcRoot) {
    cmd /c rmdir "$linkPath" 2>$null | Out-Null
    Write-Host "  - Claude Code: $($s.Name)" -ForegroundColor Yellow
  }

  $copyPath = Join-Path $WindsurfSkillsDir $s.Name
  if ((Test-Path -LiteralPath $copyPath) -and (Test-IsOurCopy -Path $copyPath)) {
    Remove-Item $copyPath -Recurse -Force
    Write-Host "  - Windsurf:    $($s.Name)" -ForegroundColor Yellow
  }
}

Remove-Item $InstallDir -Recurse -Force
Write-Host ""
Write-Host "Uninstalled my-claude-skills." -ForegroundColor Green
