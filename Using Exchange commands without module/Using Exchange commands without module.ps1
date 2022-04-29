$QUALRELAY = "YOUR_EXCHANGE_SERVER.yourdomain.com"
$psCred = Get-Credential -Message "Informe credencial ADMIN"
Import-PSSession (New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$QUALRELAY/PowerShell/ -Credential $psCred -Authentication Kerberos)
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
Clear-Host