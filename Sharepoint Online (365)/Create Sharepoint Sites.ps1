#https://docs.microsoft.com/en-us/powershell/module/sharepoint-online/new-sposite?view=sharepoint-ps
#https://docs.microsoft.com/pt-br/powershell/module/sharepoint-online/add-spouser?view=sharepoint-ps
#---------------------------------------------------------------------------------------------------------------------------------
#Import-Module -Name Microsoft.Online.SharePoint.PowerShell
#Install-Module SharePointPnPPowerShellOnline
#Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
#Update-Module -Name Microsoft.Online.SharePoint.PowerShell
#Install-Module SharePointPnPPowerShellOnline
#Update-Module SharePointPnPPowerShellOnline
#---------------------------------------------------------------------------------------------------------------------------------
$domain = "seudomionio.com.br"
$Base_OU = "Nome_da_OU_raiz_onde_tem_as_OUs_dos_setores"
$tenant = "Nome_do_Tenant"
$SP_Owner = "Login_Admin_Sharepoint_Online"
$SP_Quota_GB = "50"
#---------------------------------------------------------------------------------------------------------------------------------
$env:PNPLEGACYMESSAGE='false'
$cred = Get-Credential
#---------------------------------------------------------------------------------------------------------------------------------
$inicio_script = get-date
$sites_criados = 0
$permissoes_adicionadas = 0
$ErrorActionPreference= 'silentlycontinue'
$SP_Quota = [int]$SP_Quota_GB * "1024"
$SearchBase = "DC="+$domain.replace(".",",DC=")
If ($Base_OU) {
    $SearchBase = "OU="+$Base_OU+","+$SearchBase
}
Connect-SPOService -Url https://$tenant-admin.sharepoint.com
Clear-Host
Get-ADOrganizationalUnit -filter * -SearchBase $SearchBase -Properties Description | ForEach-Object {
    $count = $null
    $count_site = 0
    $Description = $_.Description   
    $dn = $_.distinguishedname
    $Name = $dn.ToUpper()
    [regex]$regex = ",DC="
    $Name = $regex.replace($Name,"|", 1)
    $Name = $Name.Split('|')[0].Replace('CN=','').Replace('OU=','').Replace('.','').Split(',')
    [array]::Reverse($Name)
    $Name = $Name -join "_"
    $count = ([regex]::Matches($Name, "_" )).count
    $Company = $Name.Split('_')[0]
    If ($count -ge 2) {
        $SiteURL = "https://$tenant.sharepoint.com/sites/$Name"
        $count_site = (Get-SPOSite -identity $SiteURL).count
        $count_users = 0
        $count_users = (Get-AdUser -filter * -SearchBase $dn -SearchScope OneLevel).count
        If ( ($count_site -eq 0) -and ($count_users -gt 0) ){
            Write-Host "- Creating the sharepoint site https://$tenant.sharepoint.com/sites/$Name" -NoNewline
            New-SPOSite -Url https://$tenant.sharepoint.com/sites/$Name -Owner "$SP_Owner@$domain" -LocaleID 1046 -StorageQuota $SP_Quota -CompatibilityLevel 15 -Template "BDR#0" -TimeZoneId 8 -Title "$Company - $Description"
            Set-SPOSite -Identity "https://$tenant.sharepoint.com/sites/$Name" -DisableSharingForNonOwners
            Write-Host " - Finished" -ForegroundColor Green
            $sites_criados++
        }
        Get-AdUser -filter * -SearchBase $dn -SearchScope OneLevel | ForEach-Object {
            $who = $_.UserPrincipalName
            Add-SPOUser -Site $SiteURL -LoginName $who -Group "Membros de $Company - $Description" | Out-Null
            Write-Host "     - User " -NoNewline
            Write-Host "$who" -ForegroundColor Green -NoNewline
            Write-Host " added as Membros de $Company - $Description"
            $permissoes_adicionadas++
        }
    }
	Connect-PnPOnline "https://$tenant.sharepoint.com/sites/$Name" -Credentials $cred
	Register-PnPManagementShellAccess https://$tenant.sharepoint.com/sites/$Name/Documentos
	Set-PnPList -Identity "Documentos" -ForceCheckout $false
    Write-Host "Disable the Force Checkout Setting - " -NoNewline
    Write-Host "Done" -ForegroundColor Green -NoNewline
}
$fim_script = get-date
Write-Host "O script terminou, resumo:"
Write-Host "Inicio do Script: $inicio_script"
Write-Host "Fim do Script: $fim_script"
Write-Host "Sites Criados: $sites_criados"
Write-Host "Permissoes Adiconadas: $permissoes_adicionadas"