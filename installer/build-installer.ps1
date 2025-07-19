# InnovAKT-CSET Installer Build Script
# This script can be run locally to build the installer

param(
    [string]$Version = "12.5.0.0",
    [string]$Configuration = "Release"
)

Write-Host "Building InnovAKT-CSET Installer v$Version" -ForegroundColor Green

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check if WiX is installed
try {
    $wixVersion = wix --version
    Write-Host "WiX Toolset found: $wixVersion" -ForegroundColor Green
} catch {
    Write-Error "WiX Toolset not found. Please install: dotnet tool install --global wix"
    exit 1
}

# Check if .NET 7 is installed
try {
    $dotnetVersion = dotnet --version
    Write-Host ".NET version: $dotnetVersion" -ForegroundColor Green
} catch {
    Write-Error ".NET SDK not found. Please install .NET 7 SDK"
    exit 1
}

# Set paths
$rootPath = Split-Path -Parent $PSScriptRoot
$distPath = Join-Path $rootPath "dist"
$installerPath = Join-Path $rootPath "installer"
$downloadsPath = Join-Path $installerPath "downloads"
$databasePath = Join-Path $installerPath "database"

# Clean and create directories
Write-Host "Preparing build directories..." -ForegroundColor Yellow
if (Test-Path $distPath) { Remove-Item $distPath -Recurse -Force }
if (Test-Path $downloadsPath) { Remove-Item $downloadsPath -Recurse -Force }
New-Item -ItemType Directory -Force -Path $distPath | Out-Null
New-Item -ItemType Directory -Force -Path $downloadsPath | Out-Null
New-Item -ItemType Directory -Force -Path $databasePath | Out-Null

# Build Backend (API)
Write-Host "Building CSET Backend..." -ForegroundColor Yellow
$apiPath = Join-Path $rootPath "CSETWebApi\CSETWeb_Api\CSETWeb_ApiCore"
$apiOutputPath = Join-Path $distPath "api"

Push-Location $apiPath
try {
    dotnet publish -c $Configuration -o $apiOutputPath --self-contained false
    if ($LASTEXITCODE -ne 0) { throw "Backend build failed" }
    Write-Host "Backend build completed" -ForegroundColor Green
} finally {
    Pop-Location
}

# Build Frontend (Angular)
Write-Host "Building CSET Frontend..." -ForegroundColor Yellow
$ngPath = Join-Path $rootPath "CSETWebNg"
$webOutputPath = Join-Path $distPath "web"

Push-Location $ngPath
try {
    npm ci
    if ($LASTEXITCODE -ne 0) { throw "npm install failed" }
    
    npm run build -- --configuration production
    if ($LASTEXITCODE -ne 0) { throw "Angular build failed" }
    
    # Copy built files to dist
    Copy-Item -Path "dist\*" -Destination $webOutputPath -Recurse -Force
    Write-Host "Frontend build completed" -ForegroundColor Green
} finally {
    Pop-Location
}

# Download Microsoft Prerequisites
Write-Host "Downloading Microsoft prerequisites..." -ForegroundColor Yellow

$downloads = @(
    @{
        Name = "SQL Server LocalDB 2022"
        Url = "https://download.microsoft.com/download/7/c/1/7c14e92e-bdcb-4f89-b7cf-93543e7112d1/SqlLocalDB.msi"
        File = "SqlLocalDB2022.msi"
    },
    @{
        Name = ".NET 7 Desktop Runtime"
        Url = "https://download.microsoft.com/download/0/5/2/052299f4-6d9e-4c6d-b735-0d1679b33e98/windowsdesktop-runtime-7.0.20-win-x64.exe"
        File = "windowsdesktop-runtime-7.0.20-win-x64.exe"
    },
    @{
        Name = "ASP.NET Core 7 Runtime"
        Url = "https://download.microsoft.com/download/3/1/0/31022bb9-3548-4c0c-abd5-9e62b6e7c8e0/aspnetcore-runtime-7.0.20-win-x64.exe"
        File = "aspnetcore-runtime-7.0.20-win-x64.exe"
    }
)

foreach ($download in $downloads) {
    $filePath = Join-Path $downloadsPath $download.File
    if (-not (Test-Path $filePath)) {
        Write-Host "Downloading $($download.Name)..." -ForegroundColor Cyan
        try {
            Invoke-WebRequest -Uri $download.Url -OutFile $filePath -UseBasicParsing
            Write-Host "Downloaded: $($download.File)" -ForegroundColor Green
        } catch {
            Write-Error "Failed to download $($download.Name): $_"
            exit 1
        }
    } else {
        Write-Host "Already exists: $($download.File)" -ForegroundColor Green
    }
}

# Prepare database files (placeholder)
Write-Host "Preparing database files..." -ForegroundColor Yellow
# TODO: Add logic to copy or create database files
Write-Host "Database preparation completed (placeholder)" -ForegroundColor Green

# Install WiX extensions
Write-Host "Installing WiX extensions..." -ForegroundColor Yellow
wix extension add WixToolset.UI.wixext --global | Out-Null
wix extension add WixToolset.Util.wixext --global | Out-Null
wix extension add WixToolset.Bal.wixext --global | Out-Null

# Build Main MSI Package
Write-Host "Building main application MSI..." -ForegroundColor Yellow
Push-Location $installerPath
try {
    wix build InnovAKT-CSET.wxs -o InnovAKT-CSET.msi -d "BuildOutput=$distPath" -d "DatabasePath=$databasePath"
    if ($LASTEXITCODE -ne 0) { throw "MSI build failed" }
    Write-Host "MSI package created successfully" -ForegroundColor Green
} finally {
    Pop-Location
}

# Build Bundle (Bootstrapper)
Write-Host "Building installer bundle..." -ForegroundColor Yellow
Push-Location $installerPath
try {
    $bundleName = "InnovAKT-CSET-v$Version.exe"
    wix build Bundle.wxs -o $bundleName
    if ($LASTEXITCODE -ne 0) { throw "Bundle build failed" }
    Write-Host "Installer bundle created: $bundleName" -ForegroundColor Green
} finally {
    Pop-Location
}

# Generate SHA256 Hash
Write-Host "Generating SHA256 hash..." -ForegroundColor Yellow
$installerFile = Join-Path $installerPath "InnovAKT-CSET-v$Version.exe"
if (Test-Path $installerFile) {
    $hash = Get-FileHash $installerFile -Algorithm SHA256
    $hashFile = "$installerFile.sha256"
    $hash.Hash | Out-File $hashFile -Encoding ASCII
    
    Write-Host "Installer created: $installerFile" -ForegroundColor Green
    Write-Host "SHA256 hash: $($hash.Hash)" -ForegroundColor Green
    Write-Host "Hash file: $hashFile" -ForegroundColor Green
} else {
    Write-Error "Installer file not found: $installerFile"
    exit 1
}

Write-Host "`nBuild completed successfully!" -ForegroundColor Green
Write-Host "Installer location: $installerFile" -ForegroundColor Cyan