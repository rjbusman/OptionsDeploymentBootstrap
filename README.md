OptionsDeploymentBootstrap
Overview

This folder contains the public bootstrap installer for Options.
The bootstrap script is the only publicly accessible component of the deployment system. Its purpose is to download and run the full installer from OneDrive, which then sets up the application, staging engine, and scheduled tasks on the user’s PC.
All application code, sync logic, and backups remain private and are stored in secure OneDrive locations.
Only the files in this folder are intended for public access.

What’s Inside
bootstrap.ps1
A lightweight PowerShell script that:
• 	Downloads the full installer () from OneDrive
• 	Executes it automatically
• 	Begins the initial setup process on the user’s PC
This script is safe to share publicly and is the only entry point users need.

powershell -ExecutionPolicy Bypass -Command "iwr  'https://https://1drv.ms/u/c/55038de5082a697d/IQBNGIgHelvPQ61dQHOvYit6AdPDEngyF-lR3Kmv4_VnZUs?e=ssp7rJ/bootstrap.ps1' | iex"
This command:
1. 	Downloads the bootstrap script
2. 	Downloads the full installer
3. 	Installs MyApp locally
4. 	Sets up automatic code staging
5. 	Sets up weekly backups
No manual file handling is required.

What Happens During Installation
The installer will:
• 	Create the local working directory
• 	Copy the latest master code from OneDrive
• 	Install the CodeSync engine
• 	Create two scheduled tasks:
• 	MyApp‑Stage (runs at logon + every 2 hours)
• 	MyApp‑Backup (runs weekly)
• 	Ensure the system stays updated automatically
After installation, MyApp maintains itself without user intervention. The desktop shortcut runs `bootstrap.ps1` on logon, which updates code from OneDrive, performs a daily backup of the local staging folder to `C:\ExcelApp\Backups`, and launches Excel.
\
Developer: Publishing and structure

- **Config file**: Edit `config.json` to customize paths (e.g., if OneDrive is in a different location). Paths support environment variables like `$env:USERPROFILE`.

- **OneDrive layout**: create `OneDrive\\ExcelApp` with these subfolders:
	- `Master` — canonical code base (xlsm, modules, assets)
	- `Users` — per-user folders (e.g. `Users\\alice`, `Users\\bob`) containing user-specific overrides

- **Build manifest**: run the manifest builder to publish the master copy (produces `manifest.json` and `Version.txt` in `Master`):

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\build-master-manifest.ps1
```

- **Publish per-user source**: copy user-specific files into OneDrive Users area:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\publish-user-source.ps1 -UserName alice -SourceDir C:\path\to\alice_source
```

- **How bootstrap uses this**: the public `bootstrap.ps1` reads `OneDrive\\ExcelApp\\Master\\manifest.json` and `Version.txt`, stages files into `C:\ExcelApp\\Staging`, then launches the `MainApp.xlsm` from staging. Keep your VBA-enabled workbook in `Master` so users get latest code on logon.

Developer notes:
- Test `build-master-manifest.ps1` after updating files in `Master` to ensure manifests/hash values are correct.
- Use the `publish-user-source.ps1` script to manage per-user customizations or test deployments.

## Implementation and Testing Guide

Follow these steps to set up, implement, and test the staged Excel/VBA deployment system.

### 1. Set Up OneDrive Structure
- Create the folder `OneDrive\ExcelApp` in your OneDrive.
- Inside it, create subfolders:
  - `Master` — Place your canonical Excel workbook (e.g., `MainApp.xlsm`), VBA modules, and shared assets here.
  - `Users` — This will hold per-user folders (e.g., `Users\alice` for user-specific overrides).
- Edit `config.json` if your OneDrive path differs (e.g., if not at `$env:USERPROFILE\OneDrive`).

### 2. Develop and Publish Master Code
- Update files in `OneDrive\ExcelApp\Master` (e.g., add new VBA code or update the workbook).
- Run the manifest builder to publish changes:
  ```
  PowerShell -ExecutionPolicy Bypass -File .\scripts\build-master-manifest.ps1
  ```
  - This generates `manifest.json` (file hashes and versions) and `Version.txt` in `Master`.
- Test locally: Copy `Master` contents to a test `C:\ExcelApp\Staging` folder and open the workbook in Excel to verify macros work.

### 3. Publish Per-User Sources (Optional)
- For user-specific customizations (e.g., config files or overrides), create a source folder (e.g., `C:\dev\alice_source`).
- Run the publish script:
  ```
  PowerShell -ExecutionPolicy Bypass -File .\scripts\publish-user-source.ps1 -UserName alice -SourceDir C:\dev\alice_source
  ```
  - This copies files into `OneDrive\ExcelApp\Users\alice`.
- The bootstrap will merge user files with Master during staging.

### 4. Install on User PC
- Share the `PublicInstall` folder publicly (e.g., via OneDrive link).
- On the user's PC, run:
  ```
  PowerShell -ExecutionPolicy Bypass -Command "iwr 'https://your-onedrive-link/bootstrap.ps1' | iex"
  ```
  - This downloads `bootstrap.ps1`, sets up `C:\ExcelApp\Staging`, creates a desktop shortcut, and launches Excel.
- The shortcut runs on logon, updating code and performing daily backups.

### 5. Test the System
- **Unit Test Scripts**:
  - Run `build-master-manifest.ps1` and verify `manifest.json` contains correct file hashes.
  - Run `publish-user-source.ps1` and check OneDrive\Users\{UserName}.
  - Run `backup-local.ps1` manually to test backup creation in `C:\ExcelApp\Backups`.
- **Integration Test**:
  - On a test PC, run `bootstrap.ps1` and confirm:
    - Staging folder is created/updated.
    - Workbook opens in Excel.
    - Log file (`C:\ExcelApp\Bootstrap.log`) shows success.
    - Backup zip is created if >1 day since last.
  - Simulate update: Change `Version.txt` in Master, re-run bootstrap, and verify staging updates.
- **User Test**:
  - Have a user run the install command and use the app.
  - Check for errors in logs or Excel macro issues.
- **Edge Cases**:
  - Test with no internet (should use cached staging).
  - Test with corrupted OneDrive files (should log errors).
  - Test multiple users on the same PC (different $UserName).

### 6. Maintenance
- **Updates**: Edit Master, rebuild manifest, and users get updates on next logon.
- **Backups**: Daily zips in `C:\ExcelApp\Backups` (configurable in `config.json`).
- **Logs**: Monitor `C:\ExcelApp\Bootstrap.log` for issues.
- **Troubleshooting**: If staging fails, check OneDrive sync status or path in `config.json`.

For issues, ensure PowerShell execution policy allows scripts, and OneDrive is synced.
