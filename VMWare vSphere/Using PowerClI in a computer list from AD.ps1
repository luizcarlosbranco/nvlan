#SET THE vSphere root password
$senharoot = "the_password"
$reportfolder = "C:\Temp\VMWare"
#------------------------------------------------------------------------------------------------------
Import-Module "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
$data = Get-Date -Format "yyyy-MM-dd"

#FALTA: snmp, versão do vmware (se é dell)
#Versão do vmwaretools
#Versão de vmhardware
echo "NetworkInfo;IP;Model;Version;LicenseKey;VMHostStartPolicy;ntpd;ntps;super;suporte;vswitchInternet;vmnic1status;fwstate;dcstate;isstate" > $reportfolder\$data.txt
Get-ADComputer -Filter * -SearchBase 'OU=VMWARE_OUs,DC=yourdomain,DC=com' | ForEach-Object {
    $server=$_.Name
    if (Connect-VIServer -Server $server -User "root" -Password $senharoot)
    {	
        $NetworkInfo=(get-vmhost).NetworkInfo
        $Name=(get-vmhost).Name
        $Model=(get-vmhost).Model
        $Version=(get-vmhost).Version
        $LicenseKey=(get-vmhost).LicenseKey
        $VMHostStartPolicy=(Get-VMHostStartPolicy).enabled
        $ntpd=(Get-VMHostService | where {$_.key -eq "ntpd"}).Policy
        Get-VmHostNtpServer | ForEach-Object {
            $ntps=$_
        }
        $super=(Get-VIAccount | where {$_.Name -eq "super"}).name
		$suporte=(Get-VIAccount | where {$_.Name -eq "suporte"}).name
		$vswitchInternet=(Get-VirtualPortGroup -name INTERNET).VirtualSwitchId.Replace('key-vim.host.VirtualSwitch-','')
		$statusvmfw=(get-vm | where {$_.Name -like "*-FW*"}).PowerState
		$vmnic1status=(Get-VMHostNetworkAdapter -name vmnic1).BitRatePerSec
		$dcstate=(get-vm | where {$_.Name -like "*-DC"}).PowerState
		$isstate=(get-vm | where {$_.Name -like "*-IS"}).PowerState
		echo "$NetworkInfo;$Name;$Model;$Version;$LicenseKey;$VMHostStartPolicy;$ntpd;$ntps;$super;$suporte;$vswitchInternet;$vmnic1status;$statusvmfw;$dcstate;$isstate" >> $reportfolder\$data.txt
	}
	Else
	{
		echo ";$server;;;;;;;;;;;;" >> C:\Temp\VMWare\$data.txt
	}
	Disconnect-VIServer $server -Confirm:$false
}