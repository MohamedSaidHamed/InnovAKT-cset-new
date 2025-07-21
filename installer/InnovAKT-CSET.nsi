; InnovAKT-CSET NSIS Installer Script
; Simple, reliable installer using NSIS instead of WiX

!define PRODUCT_NAME "InnovAKT-CSET"
!define PRODUCT_VERSION "12.5.0.0"
!define PRODUCT_PUBLISHER "InnovAKT"

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "InnovAKT-CSET-v${PRODUCT_VERSION}-Setup.exe"
InstallDir "$PROGRAMFILES64\InnovAKT-CSET"
RequestExecutionLevel admin

; Interface Settings
!include "MUI2.nsh"
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "License.rtf"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Languages
!insertmacro MUI_LANGUAGE "English"

Section "Prerequisites" SecPrereq
  SetOutPath "$TEMP"
  
  ; Install SQL Server LocalDB 2022
  DetailPrint "Installing SQL Server LocalDB 2022..."
  File "downloads\SqlLocalDB2022.msi"
  ExecWait 'msiexec /i "$TEMP\SqlLocalDB2022.msi" /quiet /norestart'
  
  ; Install .NET 7 Runtime
  DetailPrint "Installing .NET 7 Desktop Runtime..."
  File "downloads\windowsdesktop-runtime-7.0.20-win-x64.exe"
  ExecWait '"$TEMP\windowsdesktop-runtime-7.0.20-win-x64.exe" /quiet /norestart'
  
  ; Install ASP.NET Core 7 Runtime
  DetailPrint "Installing ASP.NET Core 7 Runtime..."
  File "downloads\aspnetcore-runtime-7.0.20-win-x64.exe"
  ExecWait '"$TEMP\aspnetcore-runtime-7.0.20-win-x64.exe" /quiet /norestart'
  
  ; Clean up temp files
  Delete "$TEMP\SqlLocalDB2022.msi"
  Delete "$TEMP\windowsdesktop-runtime-7.0.20-win-x64.exe"
  Delete "$TEMP\aspnetcore-runtime-7.0.20-win-x64.exe"
SectionEnd

Section "InnovAKT-CSET Application" SecMain
  ; Install main application MSI
  DetailPrint "Installing InnovAKT-CSET Application..."
  File "InnovAKT-CSET.msi"
  ExecWait 'msiexec /i "$OUTDIR\InnovAKT-CSET.msi" /quiet /norestart INSTALLFOLDER="$INSTDIR"'
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  ; Registry entries for Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "DisplayName" "${PRODUCT_NAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
  ; Remove application via MSI
  ExecWait 'msiexec /x "$INSTDIR\InnovAKT-CSET.msi" /quiet'
  
  ; Remove uninstaller and registry entries
  Delete "$INSTDIR\Uninstall.exe"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
  
  RMDir "$INSTDIR"
SectionEnd