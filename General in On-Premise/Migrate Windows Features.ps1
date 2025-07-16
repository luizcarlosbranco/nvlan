#-------------------------------------------- CHANGE THIS VARIABLE --------------------------------------------
$RemoteServer = "YOURSERVER.yourdomain.com"
#--------------------------------------------------------------------------------------------------------------
$NoError = $true
Clear-Host
Write-Host "!!!! ATENTION - You Need execute ALL WINDOWS UPDATE BEFORE RUNNING THIS SCRIPT !!!!"
Write-Host ""
Read-Host "Press ENTER key to start..."
For ($i=1; $i -le 4; $i++) {Write-Host ""}
$RemotePackageList = Get-WindowsFeature -ComputerName $RemoteServer | Where Installed
$MyPackageList = Get-WindowsFeature
$NotInstalledYet = $MyPackageList | Where Installed -ne $True
$InstallList = $RemotePackageList.Name | Where-Object { $_ -in $NotInstalledYet.Name  }
$InstallList = $InstallList | Where-Object { $_ -ne "NET-Framework-Core"  }
$MissingList = $RemotePackageList.Name | Where-Object { $_ -notin $MyPackageList.Name  }

If ( ($RemotePackageList | Where-Object Name -eq "NET-Framework-Core").Installed -and !($MyPackageList | Where-Object Name -eq "NET-Framework-Core").Installed) {
    Write-Host "Select the 'SXS' folder, from Windows Installation"
    $folderDialog = New-Object -ComObject Shell.Application
    $folder = $folderDialog.BrowseForFolder(0, "Select the 'SXS' folder, from Windows Installation", 0, 0)
    $selectedFolder = $folder.Self.Path
    if ( ($folder) -and (Get-ChildItem $selectedFolder -Filter "*-netfx3-*.cab" -File) ) {
        Write-Host ""
        Write-Host -NoNewline "------ Instaling NET-Framework-Core : "
        If ( !(Install-WindowsFeature -Name NET-Framework-Core -Source $selectedFolder).Success) { Write-Host -ForegroundColor Red " Error installing $DisplayName" }
        Else { Write-Host -ForegroundColor Green " OK " }
    }
    else {
        Write-Host "No SXS folder selected."
        break
    }
}
$InstallList | ForEach-Object {
    $PackageName = $_
    If ( ($MyPackageList | Where-Object Name -eq $PackageName).InstallState -eq "Removed") {
        Write-host "Skipped $PackageName (Removed)"
    }
    Else {
        Write-Host -NoNewline "------ Instaling $PackageName : "
        If ( !(Install-WindowsFeature $PackageName).Success) {
            Write-Host -ForegroundColor Red " Error installing $PackageName"
            $NoError = $false
        }
        Else { Write-Host -ForegroundColor Green " OK " }
    }
}
$MissingList | ForEach-Object {
    $PackageName = $_
    Write-Host "------ Package $PackageName do not exist in this server"
}
Write-Host ""
If ( $NoError) { Write-Host " FINISHED with NO ERRORS !!" }
