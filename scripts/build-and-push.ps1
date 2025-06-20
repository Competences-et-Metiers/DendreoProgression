# Build and Push Script for Windows PowerShell
# Usage: .\scripts\build-and-push.ps1 -Registry "localhost:5000" -Tag "latest"

param(
    [string]$Registry = "localhost:5000",
    [string]$Tag = "latest",
    [string]$ProjectName = "dendreo"
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"

function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ForegroundColor $Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $Red
}

# Function to check if registry is available
function Test-Registry {
    param([string]$RegistryUrl)
    
    if ($RegistryUrl -eq "localhost:5000") {
        $runningContainers = docker ps --format "table {{.Names}}"
        if ($runningContainers -notmatch "local_registry") {
            Write-Warning "Local registry not running. Starting it..."
            docker-compose -f docker-compose.local-registry.yml up -d registry
            Start-Sleep -Seconds 5
        }
    }
}

# Function to build and tag image
function Build-AndTag {
    param(
        [string]$Service,
        [string]$Dockerfile,
        [string]$Context
    )
    
    Write-Log "Building $Service image..."
    
    # Build with cache
    $buildArgs = @(
        "build",
        "--cache-from=$Registry/$ProjectName-$Service`:$Tag",
        "--cache-from=$Registry/$ProjectName-$Service`:latest",
        "-t", "$Registry/$ProjectName-$Service`:$Tag",
        "-t", "$Registry/$ProjectName-$Service`:latest",
        "-f", $Dockerfile,
        $Context
    )
    
    $result = & docker @buildArgs 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Built $Service image"
        return $true
    } else {
        Write-Error "Failed to build $Service image: $result"
        return $false
    }
}

# Function to push image with retry logic
function Push-WithRetry {
    param(
        [string]$Image,
        [int]$MaxAttempts = 3
    )
    
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        Write-Log "Pushing $Image (attempt $attempt/$MaxAttempts)..."
        
        $result = docker push $Image 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Pushed $Image"
            return $true
        } else {
            Write-Error "Failed to push $Image (attempt $attempt/$MaxAttempts): $result"
            
            if ($attempt -lt $MaxAttempts) {
                Write-Warning "Retrying in 10 seconds..."
                Start-Sleep -Seconds 10
            }
        }
    }
    
    Write-Error "Failed to push $Image after $MaxAttempts attempts"
    return $false
}

# Function to clean up old images
function Clear-OldImages {
    Write-Log "Cleaning up old images..."
    
    # Remove dangling images
    docker image prune -f | Out-Null
    
    # Remove old tagged images (keep last 3)
    @("backend", "frontend") | ForEach-Object {
        $service = $_
        $images = docker images "$Registry/$ProjectName-$service" --format "{{.Repository}}:{{.Tag}}" | Select-Object -Skip 3
        if ($images) {
            $images | ForEach-Object {
                try {
                    docker rmi $_ 2>$null | Out-Null
                } catch {
                    # Ignore errors
                }
            }
        }
    }
    
    Write-Success "Cleanup completed"
}

# Main execution
function Main {
    Write-Log "Starting build and push process..."
    Write-Log "Registry: $Registry"
    Write-Log "Tag: $Tag"
    
    # Check if Docker is running
    try {
        docker info | Out-Null
    } catch {
        Write-Error "Docker is not running. Please start Docker and try again."
        exit 1
    }
    
    # Check if registry is available
    Test-Registry $Registry
    
    # Build images
    $backendBuilt = Build-AndTag "backend" "./back/Dockerfile" "./back"
    $frontendBuilt = Build-AndTag "frontend" "./frontend/Dockerfile" "./frontend"
    
    if (-not $backendBuilt -or -not $frontendBuilt) {
        Write-Error "One or more builds failed. Aborting push process."
        exit 1
    }
    
    # Push images
    $pushResults = @(
        (Push-WithRetry "$Registry/$ProjectName-backend:$Tag"),
        (Push-WithRetry "$Registry/$ProjectName-backend:latest"),
        (Push-WithRetry "$Registry/$ProjectName-frontend:$Tag"),
        (Push-WithRetry "$Registry/$ProjectName-frontend:latest")
    )
    
    if ($pushResults -contains $false) {
        Write-Error "One or more pushes failed."
        exit 1
    }
    
    # Cleanup
    Clear-OldImages
    
    Write-Success "Build and push process completed!"
    
    # Show image sizes
    Write-Log "Image sizes:"
    docker images "$Registry/$ProjectName-*" --format "table {{.Repository}}:{{.Tag}}`t{{.Size}}"
}

# Run main function
Main 