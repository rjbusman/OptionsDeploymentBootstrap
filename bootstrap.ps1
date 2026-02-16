<#
    bootstrap.ps1
    Purpose: Download, validate, and launch the OptionsDeployment installer.
    Author: Richard (rjbusman)
    Notes:
        - Validates PowerShell version
        - Downloads latest installer package
        - Performs SHA-256 integrity check
        - Logs all actions
        - Self-updates if a newer bootstrap version exists
#>

# -----------------------------
# CONFIGURATION
# -----------------------------

$BootstrapVersion = "1.0.0"
$RepoRawBase = "https://raw.githubusercontent.com/rjbusman/OptionsDeploymentBootstrap/main"
$InstallerUrl = "$RepoRawBase/installer.ps1"   # You can change this later
$BootstrapUrl = "$RepoRawBase/bootstrap.ps1"
$TempPath = "$env:TEMP\OptionsDeployment"
$BootstrapPath = "$TempPath\bootstrap.ps1"
$InstallerPath = "$TempPath\installer.ps1"
$LogPath = "$TempPath\bootstrap.log"

# Expected SHA-256 hash of installer.ps1 (optional but recommended)
$ExpectedInstallerHash = ""   # Fill in once you finalize installer.ps1

# -----------------------------
# FUNCTIONS
# -----------------------------

function Write-Log {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "$timestamp  $Message"
    Add-Content -Path $LogPath -Value $entry
    Write-Host $Message
}

function Ensure-TempFolder {
    if (-not (Test-Path $TempPath)) {
        New-Item -ItemType Directory -Path $TempPath | Out-Null
        Write-Log "Created temp folder: $TempPath"
    }
}

function Validate-PowerShell {
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Log "ERROR: PowerShell 5.0 or higher is required."
        throw "PowerShell version too old."
    }
    Write-Log "PowerShell version OK: $($PSVersionTable.PSVersion)"
}

function Download-File {
    param(
        [string]$Url,
        [string]$Destination
    )
    try {
        Write-Log "Downloading: $Url"
        Invoke-WebRequest -Uri $Url -OutFile $Destination -ErrorAction Stop
        Write-Log "Downloaded to: $Destination"
    }
    catch {
        Write-Log "ERROR: Failed to download $Url"
        throw
    }
}

function Validate-Hash {
    param(
        [string]$FilePath,
        [string]$ExpectedHash
    )

    if ([string]::IsNullOrWhiteSpace($ExpectedHash)) {
        Write-Log "Skipping hash validation (no expected hash provided)."
        return
    }

    $actual = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash.ToLower()
    if ($actual -ne $ExpectedHash.ToLower()) {
        Write-Log "ERROR: Hash mismatch for $FilePath"
        Write-Log "Expected: $ExpectedHash"
        Write-Log "Actual:   $actual"
        throw "Integrity check failed."
    }

    Write-Log "Hash OK for $FilePath"
}

function Self-Update {
    Write-Log "Checking for bootstrap updates..."

    $LatestBootstrap = "$TempPath\bootstrap_latest.ps1"
    Download-File -Url $BootstrapUrl -Destination $LatestBootstrap

    $localHash = (Get-FileHash -Path $BootstrapPath -Algorithm SHA256).Hash
    $remoteHash = (Get-FileHash -Path $LatestBootstrap -Algorithm SHA256).Hash

    if ($localHash -ne $remoteHash) {
        Write-Log "New bootstrap version detected. Updating..."
        Copy-Item -Path $LatestBootstrap -Destination $BootstrapPath -Force
        Write-Log "Bootstrap updated. Relaunching..."
        & $BootstrapPath
        exit
    }

    Write-Log "Bootstrap is up to date."
}

# -----------------------------
# MAIN EXECUTION
# -----------------------------

Ensure-TempFolder
Write-Log "Bootstrap starting (v$BootstrapVersion)"

# Save a copy of this script for self-update
if (-not (Test-Path $BootstrapPath)) {
    Copy-Item -Path $PSCommandPath -Destination $BootstrapPath -Force
}

Validate-PowerShell
Self-Update

# Download installer
Download-File -Url $InstallerUrl -Destination $InstallerPath

# Validate installer integrity
Validate-Hash -FilePath $InstallerPath -ExpectedHash $ExpectedInstallerHash

# Run installer
Write-Log "Launching installer..."
& $InstallerPath

Write-Log "Bootstrap completed successfully."
