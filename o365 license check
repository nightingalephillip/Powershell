# Check if MSOnline module is installed
if (-not (Get-Module -Name MSOnline -ListAvailable)) {
    # Install MSOnline module
    Install-Module -Name MSOnline -Force -AllowClobber -Scope CurrentUser
}
# Import MSOnline module
Import-Module -Name MSOnline
# Connect to Office 365
Connect-MsolService
# Retrieve users with the specific license. Change peak6group to your license name.
$users = Get-MsolUser -All | Where-Object { $_.Licenses.AccountSkuId -eq "peak6group:OFFICESUBSCRIPTION" }
# Sort users by display name in alphabetical order
$sortedUsers = $users | Sort-Object -Property DisplayName
# Display the sorted user display names and count of active licenses
$licenseCount = 0
foreach ($user in $sortedUsers) {
    Write-Host "User Display Name: $($user.DisplayName)"
    $licenseCount++
}
# Retrieve total number of licenses available. Change peak6group to your license name.
$totalLicenses = (Get-MsolAccountSku | Where-Object { $_.AccountSkuId -eq "peak6group:OFFICESUBSCRIPTION" }).ActiveUnits
# Calculate the number of assigned licenses
$assignedLicenses = $sortedUsers.Count
# Calculate the number of remaining free licenses
$remainingLicenses = $totalLicenses - $assignedLicenses
# Display the license information
Write-Host "Total Licenses: $totalLicenses"
Write-Host "Assigned Licenses: $assignedLicenses"
Write-Host "Remaining Free Licenses: $remainingLicenses"
Write-Host "Active License Count: $licenseCount"
Read-Host -Prompt "Press Enter to exit"
