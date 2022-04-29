Clear-Host
$username = Read-Host "Inform the username"
Try
{
    Get-ADUser $username -property * -ErrorAction Stop | ForEach-Object {
        echo $_.Name
        $_.pwdLastSet = 0
        Set-ADUser -Instance $_
        $_.pwdLastSet = -1
        Set-ADUser -Instance $_
    }
}
Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
{ 
    Write-host "Cannot do this" -ForegroundColor Red
    Break
}
Write-host "Done" -ForegroundColor Green