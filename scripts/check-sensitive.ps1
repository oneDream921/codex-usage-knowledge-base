param(
    [switch]$StagedOnly
)

$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel
if (-not $repoRoot) {
    throw "Current directory is not a Git repository."
}

Set-Location $repoRoot

if ($StagedOnly) {
    $files = git diff --cached --name-only --diff-filter=ACMR
} else {
    $files = git ls-files --cached --others --exclude-standard
}

$files = $files | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) }

$blockedPathPatterns = @(
    '(^|/)\.env(\..*)?$',
    '(^|/)(id_rsa|id_ed25519|known_hosts)$',
    '\.(pem|key|p12|pfx|ovpn|mobileconfig)$',
    '(^|/).*(clash|mihomo|v2ray|xray|sing-box).*\.(ya?ml|json|txt)$'
)

$secretPatterns = @(
    '-----BEGIN (OPENSSH|RSA|DSA|EC|PRIVATE) PRIVATE KEY-----',
    '\b(sk-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16})\b',
    '\b(vless|vmess|trojan|ss)://[^\s<>\x22\x27]+',
    '(?i)\b(password|passwd|token|secret|api[_-]?key|access[_-]?key)\b\s*[:=]\s*[\x22\x27](?!只在当前|这里|example|demo|dummy|fake|your-|<|x\.x\.x\.x|os\.environ\b)[^\x22\x27\s]{8,}',
    '(?i)\$env:[A-Za-z0-9_]*(password|passwd|token|secret|api[_-]?key|access[_-]?key)[A-Za-z0-9_]*\s*=\s*[\x22\x27](?!只在当前|这里|example|demo|dummy|fake|your-|<|x\.x\.x\.x)[^\x22\x27\s]{8,}'
)

$findings = New-Object System.Collections.Generic.List[string]

foreach ($file in $files) {
    $normalized = $file -replace '\\', '/'

    foreach ($pattern in $blockedPathPatterns) {
        if ($normalized -match $pattern) {
            $findings.Add("Blocked file path: $file")
            break
        }
    }

    $content = Get-Content -LiteralPath $file -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($null -eq $content) {
        continue
    }

    foreach ($pattern in $secretPatterns) {
        $matches = [regex]::Matches($content, $pattern)
        foreach ($match in $matches) {
            $lineNumber = ($content.Substring(0, $match.Index) -split "`n").Count
            $findings.Add("Possible sensitive value at ${file}:$lineNumber")
        }
    }
}

if ($findings.Count -gt 0) {
    Write-Host "Possible sensitive data or blocked files found:" -ForegroundColor Red
    $findings | Sort-Object -Unique | ForEach-Object { Write-Host " - $_" }
    Write-Host ""
    Write-Host "Use obvious fake values for examples. Move real secrets out of the repository and re-run this check."
    exit 1
}

Write-Host "Sensitive data check passed."
