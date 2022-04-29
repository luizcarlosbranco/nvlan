Clear-Host
$DN_OU = Read-Host "Inform the PATH (the DistinguishedName) of your Organizational Unit"
Try
{
    Get-ADOrganizationalUnit $DN_OU -ErrorAction Stop
}
Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
{ 
    Write-host "Cannot found that OU" -ForegroundColor Red
    Break
}
$DN_BKP = $DN_OU.Split(",")[0]+"-BKP"
$DN_BKP = $DN_OU.Replace($DN_OU.Split(",")[0],$DN_BKP)
Try
{
    New-ADOrganizationalUnit $DN_BKP -ErrorAction Stop
}
Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
{ 
    Write-host "Have NO permition to create OU" -ForegroundColor Red
    Break
}
Import-Module ActiveDirectory
Set-Location AD:
$OUOldAcl = (Get-Acl "AD:$DN_OU") 
$OUDefaultAcl = (Get-Acl "AD:$DN_BKP")

Set-Acl "AD:$DN_BKP" -AclObject $OUOldAcl
Set-Acl "AD:DN_OU" -AclObject $OUDefaultAcl

Write-host "Finished" -ForegroundColor Green -NoNewline
Write-host ": Created a OU " -NoNewline
Write-host "$DN_BKP" -NoNewline -ForegroundColor Green
Write-host " with the original permissions" 