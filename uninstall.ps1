<#
.SYNOPSIS
  Uninstall my-claude-skills (Windows): remove Junctions and the install dir.
#>

$ErrorActionPreference = 'Stop'

$InstallDir = Join-Path $env:LOCALAPPDATA 'my-claude-skills'
$SkillsDir  = Join-Path $env:USERPROFILE '.claude\skills'

if (-not (Test-Path $InstallDir)) {
  Write-Host "Not installed at $InstallDir. Nothing to do."
  exit 0
}

# Unlink each skill from ~/.claude/skills/
$skills = Get-ChildItem (Join-Path $InstallDir 'skills') -Directory -ErrorAction SilentlyContinue
foreach ($s in $skills) {
  $linkPath = Join-Path $SkillsDir $s.Name
  if (Test-Path $linkPath) {
    cmd /c rmdir "$linkPath" 2>$null
    Write-Host "  - $($s.Name)" -ForegroundColor Yellow
  }
}

# Remove the install dir
Remove-Item $InstallDir -Recurse -Force
Write-Host ""
Write-Host "Uninstalled my-claude-skills." -ForegroundColor Green
