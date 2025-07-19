# InnovAKT-CSET Installer

This directory contains the WiX Toolset configuration files and scripts to build a Windows installer for InnovAKT-CSET, similar to the original CSET standalone installer.

## What the Installer Does

The installer creates a self-contained cybersecurity evaluation environment by:

1. **Installing Dependencies**:
   - SQL Server 2022 LocalDB
   - .NET 7 Runtime
   - ASP.NET Core 7 Runtime

2. **Installing Application**:
   - CSET API server
   - Angular web interface
   - Database files
   - Configuration files

3. **Setting Up Environment**:
   - Creates LocalDB instance "INLLocalDb2022"
   - Places database in `%LOCALAPPDATA%\DHS\CSET\12.5.0.0\`
   - Creates start menu and desktop shortcuts
   - Configures local-only operation

## Files

- **`InnovAKT-CSET.wxs`** - Main WiX project file defining the application package
- **`Bundle.wxs`** - Bootstrapper that bundles dependencies with the application
- **`build-installer.ps1`** - PowerShell script to build the installer locally
- **`License.rtf`** - License agreement shown during installation
- **`LOCAL-INSTALLATION`** - Marker file indicating standalone installation

## Building the Installer

### Prerequisites

1. **WiX Toolset v4**:
   ```bash
   dotnet tool install --global wix
   ```

2. **.NET 7 SDK** (for building the application)

3. **Node.js 18+** (for building the Angular frontend)

### Local Build

Run the PowerShell build script:

```powershell
cd installer
.\build-installer.ps1 -Version "12.5.0.0"
```

This will:
- Build the CSET application
- Download Microsoft redistributables
- Create the MSI package
- Create the bootstrapper executable
- Generate SHA256 hash

### GitHub Actions Build

The installer is automatically built when you:

1. **Push a tag**:
   ```bash
   git tag v12.5.0.0-innovakt
   git push origin v12.5.0.0-innovakt
   ```

2. **Manual trigger**:
   - Go to Actions tab in GitHub
   - Select "Build InnovAKT-CSET Installer"
   - Click "Run workflow"
   - Enter version number

## Output

The build process creates:

- **`InnovAKT-CSET-v{version}.exe`** - Main installer executable
- **`InnovAKT-CSET-v{version}.exe.sha256`** - SHA256 hash for verification

## Installation Process

When users run the installer:

1. **Welcome Screen** - Shows license agreement
2. **Dependency Check** - Installs missing runtimes if needed
3. **Installation Directory** - User selects install location
4. **File Copy** - Copies application and database files
5. **Configuration** - Sets up LocalDB and creates shortcuts
6. **Completion** - Ready to launch application

## Post-Installation

After installation:
- Application launches via desktop/start menu shortcuts
- Runs on `http://localhost:8080` (or similar)
- Opens automatically in default browser
- Works completely offline
- Stores all data locally in LocalDB

## Customization

To modify the installer:

1. **Change application files**: Edit `InnovAKT-CSET.wxs` ComponentGroups
2. **Modify dependencies**: Update `Bundle.wxs` PackageGroups
3. **Update branding**: Replace license, logos, and theme files
4. **Version numbers**: Update all version references consistently

## Troubleshooting

**Build Errors**:
- Ensure all prerequisites are installed
- Check that build outputs exist in expected locations
- Verify WiX extensions are loaded

**Runtime Errors**:
- SQL Server LocalDB installation issues
- .NET Runtime version mismatches
- File permission problems during installation

## Comparison to Original CSET

This installer replicates the functionality of the original CSET standalone installer:

| Feature | Original CSET | InnovAKT-CSET |
|---------|---------------|---------------|
| SQL Server LocalDB | ✅ | ✅ |
| .NET Runtime Bundle | ✅ | ✅ |
| Offline Operation | ✅ | ✅ |
| Local Database | ✅ | ✅ |
| Web Interface | ✅ | ✅ |
| Windows Installer | ✅ | ✅ |
| MIT License | ✅ | ✅ |

The key difference is that this version is built using publicly available tools and can be completely automated via GitHub Actions.