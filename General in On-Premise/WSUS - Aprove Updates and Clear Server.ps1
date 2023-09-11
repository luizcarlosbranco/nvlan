#--------------------------------------------------------------------------------------------------------------
# REMOVER PACOTES QUE NAO INTERESSERAM
Get-WsusUpdate | Where {$_.update.title -like "*itanium*" -or $_.update.title -like "*ARM64*" -or $_.update.title -like "*32 Bits*" -or $_.update.title -like "*x86*" -or $_.update.title -like "*LanguageFeatureOnDemand*"} | Deny-WsusUpdate
Get-WsusUpdate | Where {$_.update.title -like "*farm do Microsoft*"} | Deny-WsusUpdate
#Get-WsusUpdate | Where {$_.update.title -like "*Windows 10*" -and $_.update.title -like "*en-us*"} | Deny-WsusUpdate
Get-WSUSUpdate | Where-Object { $_.Update.GetRelatedUpdates(([Microsoft.UpdateServices.Administration.UpdateRelationship]::UpdatesThatSupersedeThisUpdate)).Count -gt 0 } | Deny-WsusUpdate
Get-WsusUpdate -Classification All -Approval Unapproved | Approve-WsusUpdate -Action Install -TargetGroupName "All Computers"
#--------------------------------------------------------------------------------------------------------------
# LIMPEZA DO WSUS
# FONTE: https://www.vanstechelman.eu/content/how-to-run-the-wsus-server-cleanup-wizard-from-command-line
[reflection.assembly]::LoadWithPartialName(“Microsoft.UpdateServices.Administration”) | Out-Null
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer()
$cleanupScope = new-object Microsoft.UpdateServices.Administration.CleanupScope;
$cleanupScope.DeclineSupersededUpdates = $true      
$cleanupScope.DeclineExpiredUpdates = $true
$cleanupScope.CleanupObsoleteUpdates = $true
$cleanupScope.CompressUpdates = $true
$cleanupScope.CleanupObsoleteComputers = $true
$cleanupScope.CleanupUnneededContentFiles = $true
$cleanupManager = $wsus.GetCleanupManager();
$cleanupManager.PerformCleanup($cleanupScope);
Invoke-WsusServerCleanup -CleanupObsoleteComputers -CleanupObsoleteUpdates