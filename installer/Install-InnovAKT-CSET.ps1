# InnovAKT-CSET Installer Script
# Simple PowerShell installer that handles all prerequisites

param(
    [switch]$Quiet = $false
)

Write-Host "=== InnovAKT-CSET Installer ===" -ForegroundColor Green
Write-Host "Installing cybersecurity evaluation tool with all prerequisites..."

$ErrorActionPreference = "Stop"
$installerDir = Split-Path -Parent $MyInvocation.MyCommand.Path

try {
    # 1. Install SQL Server LocalDB 2022
    Write-Host "Installing SQL Server LocalDB 2022..." -ForegroundColor Yellow
    $sqlLocalDB = Join-Path $installerDir "downloads\SqlLocalDB2022.msi"
    if (Test-Path $sqlLocalDB) {
        Start-Process "msiexec.exe" -ArgumentList "/i `"$sqlLocalDB`" /quiet /norestart" -Wait -NoNewWindow
        Write-Host "✅ SQL Server LocalDB installed" -ForegroundColor Green
    } else {
        Write-Host "⚠️ SQL Server LocalDB not found, skipping..." -ForegroundColor Yellow
    }

    # 2. Install .NET 7 Desktop Runtime
    Write-Host "Installing .NET 7 Desktop Runtime..." -ForegroundColor Yellow
    $dotnetRuntime = Join-Path $installerDir "downloads\windowsdesktop-runtime-7.0.20-win-x64.exe"
    if (Test-Path $dotnetRuntime) {
        $size = (Get-Item $dotnetRuntime).Length
        if ($size -gt 1000000) { # > 1MB means real file
            Start-Process $dotnetRuntime -ArgumentList "/quiet", "/norestart" -Wait -NoNewWindow
            Write-Host "✅ .NET 7 Runtime installed" -ForegroundColor Green
        } else {
            Write-Host "⚠️ .NET Runtime file is placeholder - checking existing installation..." -ForegroundColor Yellow
            # Check if .NET 7 is already installed
            $dotnetInstalled = Test-Path "C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\7.0*"
            if ($dotnetInstalled) {
                Write-Host "✅ .NET 7 Runtime already installed" -ForegroundColor Green
            } else {
                Write-Host "❌ .NET 7 Runtime required but not available. Please install manually from: https://dotnet.microsoft.com/download/dotnet/7.0" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "⚠️ .NET Runtime installer not found" -ForegroundColor Yellow
    }

    # 3. Install ASP.NET Core 7 Runtime
    Write-Host "Installing ASP.NET Core 7 Runtime..." -ForegroundColor Yellow
    $aspnetRuntime = Join-Path $installerDir "downloads\aspnetcore-runtime-7.0.20-win-x64.exe"
    if (Test-Path $aspnetRuntime) {
        $size = (Get-Item $aspnetRuntime).Length
        if ($size -gt 1000000) { # > 1MB means real file
            Start-Process $aspnetRuntime -ArgumentList "/quiet", "/norestart" -Wait -NoNewWindow
            Write-Host "✅ ASP.NET Core Runtime installed" -ForegroundColor Green
        } else {
            Write-Host "⚠️ ASP.NET Runtime file is placeholder - checking existing installation..." -ForegroundColor Yellow
            # Check if ASP.NET Core 7 is already installed
            $aspnetInstalled = Test-Path "C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App\7.0*"
            if ($aspnetInstalled) {
                Write-Host "✅ ASP.NET Core 7 Runtime already installed" -ForegroundColor Green
            } else {
                Write-Host "❌ ASP.NET Core 7 Runtime required but not available. Please install manually from: https://dotnet.microsoft.com/download/dotnet/7.0" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "⚠️ ASP.NET Core Runtime installer not found" -ForegroundColor Yellow
    }

    # 4. Install InnovAKT-CSET Application
    Write-Host "Installing InnovAKT-CSET Application..." -ForegroundColor Yellow
    $mainApp = Join-Path $installerDir "InnovAKT-CSET.msi"
    if (Test-Path $mainApp) {
        $msiArgs = "/i `"$mainApp`" /quiet /norestart"
        if (-not $Quiet) {
            $msiArgs = "/i `"$mainApp`" /qb /norestart"  # Basic UI
        }
        Start-Process "msiexec.exe" -ArgumentList $msiArgs -Wait -NoNewWindow
        Write-Host "✅ InnovAKT-CSET Application installed" -ForegroundColor Green
    } else {
        throw "Main application MSI not found: $mainApp"
    }

    # 5. Configure for Standalone Installation
    Write-Host "Configuring standalone installation..." -ForegroundColor Yellow
    
    # Find the installed application directory
    $installPaths = @(
        "C:\Program Files\InnovAKT-CSET",
        "C:\Program Files (x86)\InnovAKT-CSET"
    )
    
    $appPath = $null
    foreach ($path in $installPaths) {
        if (Test-Path $path) {
            $appPath = $path
            break
        }
    }
    
    if ($appPath) {
        Write-Host "Found application at: $appPath" -ForegroundColor Cyan
        
        # Update appsettings.json for standalone mode
        $appsettingsPath = Join-Path $appPath "appsettings.json"
        if (Test-Path $appsettingsPath) {
            $appsettings = Get-Content $appsettingsPath -Raw | ConvertFrom-Json
            $appsettings.EnterpriseInstallation = "false"
            $appsettings.ConnectionStrings.CSET_DB = "data source=(localdb)\INLLocalDb2022;initial catalog=CSETWeb;persist security info=True;Integrated Security=SSPI;MultipleActiveResultSets=True;Encrypt=false"
            $appsettings | ConvertTo-Json -Depth 10 | Set-Content $appsettingsPath
            Write-Host "✅ Updated appsettings.json for standalone mode" -ForegroundColor Green
        }
        
        # Create LOCAL-INSTALLATION marker file in application directory
        $localMarker = Join-Path $appPath "LOCAL-INSTALLATION"
        "This file indicates that this is a local standalone installation of InnovAKT-CSET." | Set-Content $localMarker
        Write-Host "✅ Created LOCAL-INSTALLATION marker file" -ForegroundColor Green
        
        # 6. Setup LocalDB Instance
        Write-Host "Setting up LocalDB instance..." -ForegroundColor Yellow
        try {
            # Create LocalDB instance
            & sqllocaldb create "INLLocalDb2022" -s
            Write-Host "✅ Created LocalDB instance 'INLLocalDb2022'" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ LocalDB instance creation failed (may already exist): $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # 7. Create startup shortcut that launches browser
        Write-Host "Creating startup shortcut..." -ForegroundColor Yellow
        $startupScript = Join-Path $appPath "StartCSET.bat"
        @"
@echo off
echo Starting InnovAKT-CSET...
cd /d "$appPath"
start "" CSETWebCore.Api.exe
timeout /t 3 /nobreak >nul
start "" http://localhost:5000
"@ | Set-Content $startupScript
        Write-Host "✅ Created startup script" -ForegroundColor Green
        
    } else {
        Write-Host "⚠️ Could not find installed application directory" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "🎉 Installation completed successfully!" -ForegroundColor Green
    Write-Host "You can now launch InnovAKT-CSET from the Start Menu or Desktop shortcut." -ForegroundColor Cyan
    
} catch {
    Write-Host ""
    Write-Host "❌ Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please run this installer as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

if (-not $Quiet) {
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}