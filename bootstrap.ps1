<# =====================================================================
    bootstrap.ps1
    Tiny web-facing launcher for the OptionsDeployment system

    Recommended one-liner:
      powershell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile `
        -Command "Invoke-WebRequest 'https://your-public-url/bootstrap.ps1' -UseBasicParsing | Invoke-Expression"
===================================================================== #>

$ErrorActionPreference = 'Stop'

# === EDIT THIS FOR YOUR PUBLIC HOSTING ===
# Raw URL to Start-OptionsDeployment.ps1 in PublicInstall
$StartScriptUrl = 'https://1drv.ms/u/c/55038de5082a697d/IQCfGsXEtpXmSaSjKEy6VWghAb-2RH-ORlw4mL43Qwnhai4?e=LeAfjF'

# Temp path to save the downloaded script
$TempRoot = Join-Path $env:TEMP 'OptionsDeployment_Bootstrap'
$StartFilePath = Join-Path $TempRoot 'Start-OptionsDeployment.ps1'

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )
    Write-Host "[bootstrap][$Level] $Message"
}

function Ensure-Folder {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

Write-Log "Starting web bootstrap for OptionsDeployment..."

try {
    Ensure-Folder -Path $TempRoot

    Write-Log "Downloading Start-OptionsDeployment.ps1 from: $StartScriptUrl"
    Invoke-WebRequest -Uri $StartScriptUrl -OutFile $StartFilePath -UseBasicParsing
    Write-Log "Download complete: $StartFilePath"

    Write-Log "Invoking Start-OptionsDeployment.ps1..."
    & powershell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile -File $StartFilePath

    Write-Log "bootstrap.ps1 completed."
}
catch {
    Write-Log "Bootstrap failed: $($_.Exception.Message)" 'ERROR'
    throw
}