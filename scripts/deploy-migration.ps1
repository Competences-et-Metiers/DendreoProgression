# DendreoProgression Database Migration Script (PowerShell)
# This script applies the time tracking migration to your production database
# For Windows users who need to run this locally

param(
    [string]$DBHost = "your-production-db-host",
    [string]$DBPort = "5432",
    [string]$DBName = "your-production-db-name",
    [string]$DBUser = "your-production-db-user",
    [string]$DBPassword = "your-production-db-password"
)

# Migration file path
$MigrationFile = "database/migrations/001-add-time-tracking-columns.sql"

Write-Host "=== DendreoProgression Database Migration ===" -ForegroundColor Green
Write-Host "This script will add time tracking columns to your production database."
Write-Host ""

# Check if migration file exists
if (-not (Test-Path $MigrationFile)) {
    Write-Host "Error: Migration file not found at $MigrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "Database Configuration:" -ForegroundColor Yellow
Write-Host "  - DB_HOST: $DBHost"
Write-Host "  - DB_PORT: $DBPort"
Write-Host "  - DB_NAME: $DBName"
Write-Host "  - DB_USER: $DBUser"
Write-Host "  - DB_PASSWORD: [hidden]"
Write-Host ""

# Ask for confirmation
$confirm = Read-Host "Have you updated the database configuration? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Migration cancelled. Please update the configuration and run again." -ForegroundColor Yellow
    exit 1
}

Write-Host "Warning: This will modify your production database." -ForegroundColor Yellow
$confirm = Read-Host "Are you sure you want to proceed? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Migration cancelled." -ForegroundColor Yellow
    exit 1
}

# Test database connection
Write-Host "Testing database connection..." -ForegroundColor Green
try {
    $env:PGPASSWORD = $DBPassword
    $testResult = & psql -h $DBHost -p $DBPort -U $DBUser -d $DBName -c "SELECT 1;" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Database connection failed"
    }
    Write-Host "Database connection successful!" -ForegroundColor Green
} catch {
    Write-Host "Error: Cannot connect to database. Please check your configuration." -ForegroundColor Red
    exit 1
}

# Create backup
Write-Host "Creating database backup..." -ForegroundColor Green
$BackupFile = "dendreo_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"
try {
    & pg_dump -h $DBHost -p $DBPort -U $DBUser -d $DBName > $BackupFile
    Write-Host "Backup created: $BackupFile" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not create backup. Proceeding anyway..." -ForegroundColor Yellow
}

# Run migration
Write-Host "Running migration..." -ForegroundColor Green
try {
    & psql -h $DBHost -p $DBPort -U $DBUser -d $DBName -f $MigrationFile
    Write-Host "Migration completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error: Migration failed. Check the error messages above." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart your application to pick up the new columns"
Write-Host "2. Run a sync to populate the new time tracking data"
Write-Host "3. Verify the migration by checking the new columns in your database"
Write-Host ""
if (Test-Path $BackupFile) {
    Write-Host "Backup file: $BackupFile" -ForegroundColor Green
    Write-Host "Keep this backup file for safety."
}
