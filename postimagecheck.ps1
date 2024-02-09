# Clear the console
Clear-Host

#Check if windows update module installed, install if not present
if(-not (Get-Module PSWindowsUpdate -ListAvailable)){
Install-Module PSWindowsUpdate -Scope CurrentUser -Force
}

# Define the directory and filename prefixes
$dir = "C:\Windows"
$prefix1 = "osd_build_BASE"
$prefix2 = "osc_task_sequence"

# Image Verification section
Write-Host "**************************************" -ForegroundColor "Magenta"
Write-Host "**        IMAGE VERIFICATION        **" -ForegroundColor "Magenta"
Write-Host "**************************************" -ForegroundColor "Magenta"
# Check for files starting with 'osd_build_BASE'
$files1 = Get-ChildItem -Path $dir -Filter "$prefix1*"
if ($files1) {
    foreach ($file in $files1) {
        Write-Host "Found file: $($file.FullName)" -ForegroundColor "Green"
    }
}
else {
    Write-Host "No files starting with $prefix1 were found in $dir" -ForegroundColor "Red"
}
Write-Output "`n"

# App Verification section
Write-Host "**************************************" -ForegroundColor "Magenta"
Write-Host "**         APP VERIFICATION         **" -ForegroundColor "Magenta"
Write-Host "**************************************" -ForegroundColor "Magenta"
# Check for files starting with 'osd_task_sequence'
$files2 = Get-ChildItem -Path $dir -Filter "$prefix2*"
if ($files2) {
    foreach ($file in $files2) {
        Write-Host "Found file: $($file.FullName)"  -ForegroundColor "Yellow"
        Write-Host "Contents of the file:"  -ForegroundColor "Yellow"
        Get-Content -Path $file.FullName
    }
}
else {
    Write-Host "No app installation errors reported" -ForegroundColor "Green"
}
Write-Output "`n"

# BitLocker Verification section
Write-Host "**************************************" -ForegroundColor "Magenta"
Write-Host "**      BITLOCKER VERIFICATION      **" -ForegroundColor "Magenta"
Write-Host "**************************************" -ForegroundColor "Magenta"
$bitLockerStatus = Manage-bde -Status
$protectionStatus = $bitLockerStatus | Select-String "Protection Status" | Select-Object -First 1
$protectionStatusString = $protectionStatus.ToString()

# Display the Protection status in yellow
Write-Host "$protectionStatusString" -ForegroundColor "Yellow"

# Display the rest of the BitLocker status
$bitLockerStatus | Select-String -Pattern "(?<!Protection Status.*)"
Write-Output "`n"

# OU Verification section
Write-Host "**************************************" -ForegroundColor "Magenta"
Write-Host "**          OU VERIFICATION         **" -ForegroundColor "Magenta"
Write-Host "**************************************" -ForegroundColor "Magenta"
# Get Group Policy Results
$gpresult = gpresult /R /Scope Computer | Out-String
# Split the output into lines
$lines = $gpresult -split "\r\n"
# Find the start and end lines for the "Computer Settings" section
$startLine = $lines | Where-Object { $_ -match "CN=" }
$endLine = $lines | Where-Object { $_ -match "Domain Type:" }
# Get the indexes of the start and end lines
$startIndex = $lines.IndexOf($startLine)
$endIndex = $lines.IndexOf($endLine)
# Select the lines for the "Computer Settings" section
$computerSettings = $lines[$startIndex..$endIndex] -join "`n"
# Output the "Computer Settings" section
Write-Host $computerSettings -ForegroundColor "Green"
Write-Output "`n"

# Admin Profile Verification section
Write-Host "**************************************" -ForegroundColor "Magenta"
Write-Host "**    ADMIN PROFILE VERIFICATION    **" -ForegroundColor "Magenta"
Write-Host "**************************************" -ForegroundColor "Magenta"
# Get the members of the local Administrators group
try {
    $adminMembers = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
    Write-Host "Members of the Administrators group:" -ForegroundColor "Yellow"
    foreach ($member in $adminMembers) {
        Write-Host $member.Name -ForegroundColor "Green"
    }
} catch {
    Write-Host "Failed to get the members of the Administrators group" -ForegroundColor "Red"
}
Write-Output "`n"


# Windows Activation Verification section
Write-Host "**************************************" -ForegroundColor "Magenta"
Write-Host "** WINDOWS ACTIVATION VERIFICATION  **" -ForegroundColor "Magenta"
Write-Host "**************************************" -ForegroundColor "Magenta"

Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" | where { $_.PartialProductKey } | select Description, LicenseStatus
Write-Output "`n"

# Group Policy Verification section
Write-Host "**************************************" -ForegroundColor "Magenta"
Write-Host "**    GROUP POLICY VERIFICATION     **" -ForegroundColor "Magenta"
Write-Host "**************************************" -ForegroundColor "Magenta"
# Run 'gpupdate /force' in a separate PowerShell window as administrator
Write-Host "Running 'gpupdate /force' in a separate PowerShell window..." -ForegroundColor "Green"
Start-Process -filepath "cmd.exe" -ArgumentList "/c gpupdate /force" -wait
Write-Host "Group Policy update started." -ForegroundColor "Yellow"
Write-Output "`n"

# Trigger SCCM section
Write-Host "**************************************" -ForegroundColor "Magenta"
Write-Host "**           TRIGGER SCCM           **" -ForegroundColor "Magenta"
Write-Host "**************************************" -ForegroundColor "Magenta"
# Run the batch file
$batchFilePath = "C:\Program Files (x86)\Peak6\Scripts\Trigger_SCCM_Client_Actions\Trigger_SCCM_Client_actions.bat"
if (Test-Path $batchFilePath) {
    try {
        Start-Process -FilePath $batchFilePath -Wait
        Write-Host "Trigger SCCM completed successfully." -ForegroundColor "Green"
    } catch {
        Write-Host "Failed to run Trigger SCCM: $_" -ForegroundColor "Red"
    }
} else {
    Write-Host "Trigger SCCM batch file not found at $batchFilePath." -ForegroundColor "Red"
}
Write-Output "`n"

# Windows update section
Write-Host "**************************************" -ForegroundColor "Magenta"
Write-Host "**          WINDOWS UPDATE          **" -ForegroundColor "Magenta"
Write-Host "**************************************" -ForegroundColor "Magenta"

# Start Windows Update
$session = New-Object -ComObject "Microsoft.Update.Session"
$searcher = $session.CreateUpdateSearcher()
$updates = $searcher.Search("IsInstalled=0")
if ($updates.Updates.Count -eq 0) {
    Write-Host "No updates available." -ForegroundColor "Yellow"
    exit
}
$downloader = $session.CreateUpdateDownloader()
$downloader.Updates = $updates.Updates
$downloader.Download()
# Show download progress
$updatesToDownload = $updates.Updates.Count
$downloadedUpdates = 0
foreach ($update in $updates.Updates) {
    if ($update.IsDownloaded) {
        $downloadedUpdates++
    }
}
Write-Host "Total updates to download: $updatesToDownload"
Write-Host "Updates downloaded: $downloadedUpdates"
# Install updates
$installer = $session.CreateUpdateInstaller()
$installer.Updates = $updates.Updates
$installResult = $installer.Install()
# Show install progress
Write-Host "Installing updates..."
while ($installResult.IsBusy) {
    Start-Sleep -Seconds 1
}
# Check results
if ($installResult.ResultCode -eq 2) {
    Write-Host "Updates installed successfully." -ForegroundColor "Green"
} else {
    Write-Host "Update installation failed. Result code: $($installResult.ResultCode)" -ForegroundColor "Red"
}
