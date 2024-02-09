function Main {
    # Prompt user for the file path and group name
    $filePath = Read-Host "Enter the path to the file"
    $groupName = Read-Host "Enter the Active Directory group name"
    # Check if the file exists
    if (-not (Test-Path $filePath)) {
        Write-Host "File not found. Please ensure the file path is correct." -ForegroundColor Red
        return
    }
    # Initialize arrays for members and non-members
    $members = @()
    $nonMembers = @()
    # Get the specified group's members
    $groupMembers = Get-ADGroupMember -Identity $groupName -Recursive | Select-Object -ExpandProperty SamAccountName
    # Read each line in the file
    Get-Content $filePath | ForEach-Object {
        $userIdentifier = $_.Trim()
        # Determine if the identifier is an email or username
        if ($userIdentifier -match "@") {
            # Assume it's an email and try to find the corresponding AD user
            $user = Get-ADUser -Filter { EmailAddress -eq $userIdentifier } -Properties UserPrincipalName -ErrorAction SilentlyContinue
        } else {
            # Assume it's a username
            $user = Get-ADUser -Identity $userIdentifier -Properties UserPrincipalName -ErrorAction SilentlyContinue
        }
        if ($user -and $groupMembers -contains $user.SamAccountName) {
            # User is a member of the group
            $members += $user.UserPrincipalName
        } elseif ($user) {
            # User exists but is not a member of the group
            $nonMembers += $user.UserPrincipalName
        }
    }
    # Output members in green
    $members | ForEach-Object {
        Write-Host $_ -ForegroundColor Green
    }
    # Output non-members in red and ask for addition to the group
    $nonMembers | ForEach-Object {
        $upn = $_
        Write-Host $upn -ForegroundColor Red
        $response = Read-Host "Do you want to add this user to the group? (Y/N)"
        if ($response -eq 'Y') {
            try {
                Add-ADGroupMember -Identity $groupName -Members $upn -ErrorAction Stop
                Write-Host "User $upn added to the group successfully." -ForegroundColor Green
            } catch {
                Write-Host "Failed to add user $upn to the group. Error: $_" -ForegroundColor Red
            }
        }
    }
}
# Main script loop
do {
    Main
    # Ask user if they want to exit or restart the script
    $userChoice = Read-Host "Do you want to exit or start over? (Exit/Over)"
} while ($userChoice -eq 'Over')
Write-Host "Exiting script. Have a good day!"
