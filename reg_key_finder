#Script to find the value of a registry key. Change $domain variable to your domain. Change $subKeyPath variable to change registry key you need value form.

do {
    # User input section
    $domainUser = Read-Host "Enter the domain user account name"
    $remoteComputer = Read-Host "Enter the remote computer name"
    # Construct the fully qualified username
    $domain = "peak6.net"
    $qualifiedUsername = "$domain\$domainUser"
    # Get the SID for the user
    try {
        $userSID = (New-Object System.Security.Principal.NTAccount($qualifiedUsername)).Translate([System.Security.Principal.SecurityIdentifier])
    } catch {
        Write-Error "Unable to find SID for user $qualifiedUsername"
        continue
    }
    # Connect to registry
    try {
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('Users', $remoteComputer)
        $subKeyPath = "$userSID\SOFTWARE\Classes\slack\shell\open\command"
        $subKey = $reg.OpenSubKey($subKeyPath)
        if ($subKey -ne $null) {
            # Display the registry key value
            $value = $subKey.GetValue('')
            Write-Output "`n"
            Write-Host "Registry key value: $value" -ForegroundColor "Green"
            Write-Output "`n"
        } else {
            Write-Warning "Registry key not found: $subKeyPath"
        }
    } catch {
        Write-Error "Error accessing remote registry: $_"
    } finally {
        if ($subKey -ne $null) {
            $subKey.Close()
        }
        if ($reg -ne $null) {
            $reg.Close()
        }
    }
    # Ask the user if they want to run the script again
    $runAgain = Read-Host "Do you want to run the script again for a different user/computer? (yes/no)"
} while ($runAgain -eq "yes")
# End of script
Write-Host "Script execution complete."
