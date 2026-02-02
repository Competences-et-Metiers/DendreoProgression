# Clean Python Cache and Log Files
# Usage: .\scripts\clean-cache.ps1

Write-Host "🧹 Cleaning Python cache files and logs..." -ForegroundColor Blue

# Remove Python cache directories
$cachePatterns = @(
    "back\**\__pycache__",
    "**\*.pyc",
    "**\*.pyo",
    "**\*.pyd"
)

foreach ($pattern in $cachePatterns) {
    $files = Get-ChildItem -Path . -Include $pattern.Split('\')[-1] -Recurse -Force -ErrorAction SilentlyContinue
    if ($files) {
        $files | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Removed cache files matching: $pattern" -ForegroundColor Green
    }
}

# Remove log files
$logPatterns = @(
    "back\logs\*.log",
    "dev-logs\*.log",
    "logs\*.log",
    "**\*.log.*"
)

foreach ($pattern in $logPatterns) {
    $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
    if ($files) {
        $files | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Removed log files matching: $pattern" -ForegroundColor Green
    }
}

# Remove Node.js cache
if (Test-Path "frontend\node_modules\.cache") {
    Remove-Item "frontend\node_modules\.cache" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Removed Node.js cache" -ForegroundColor Green
}

Write-Host "🎉 Cache cleanup completed!" -ForegroundColor Green 