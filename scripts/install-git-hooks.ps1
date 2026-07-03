$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel
if (-not $repoRoot) {
    throw "Current directory is not a Git repository."
}

Set-Location $repoRoot

$hookPath = ".githooks"
if (-not (Test-Path -LiteralPath (Join-Path $hookPath "pre-commit") -PathType Leaf)) {
    throw "Missing .githooks/pre-commit."
}

git config core.hooksPath $hookPath

Write-Host "Git hooks installed: core.hooksPath=$hookPath"
Write-Host "Pre-commit will run git diff --check and scripts/check-sensitive.ps1 -StagedOnly."
