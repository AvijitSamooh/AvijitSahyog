[CmdletBinding()]
param(
    [ValidateSet('all', 'ui', 'backend')]
    [string]$Target = 'all'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot

function Invoke-UiValidation {
    Write-Host '=== Flutter UI validation ===' -ForegroundColor Cyan
    Push-Location (Join-Path $RepoRoot 'app/flutter')
    try {
        flutter pub get
        flutter gen-l10n
        flutter analyze
        flutter test
        flutter build web
    } finally { Pop-Location }
}

function Invoke-BackendValidation {
    Write-Host '=== Backend validation ===' -ForegroundColor Cyan
    Push-Location (Join-Path $RepoRoot 'backend/nestjs')
    try {
        npm ci
        npm run prisma:generate
        npm run build
        npm test
    } finally { Pop-Location }
}

switch ($Target) {
    'ui' { Invoke-UiValidation }
    'backend' { Invoke-BackendValidation }
    'all' { Invoke-UiValidation; Invoke-BackendValidation }
}

Write-Host "Validation completed successfully for: $Target" -ForegroundColor Green
