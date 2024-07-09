#Definir aqui HÁ QUANTOS dias a atualização precisa ter para ser usada em produção (ex: para pelo menos 14 dias, definir $maturidade  = 14)
$maturidade  = 14
# TOMAR AS AÇÕES BASEADAS NA ULTIMA SINCRONIZAÇÃO (BAIXAR ATUALIZACOES DO WSUS (FAÇO POR FIM POIS NAO SEI QUANTO TEMPO IRA DEMORAR, NA PROXIMA EXECUÇÃO DO SCRIPT QUE SERÃO APROVADAS E/OU RECUSADAS)
# DEFININDO A DATA DE APROVACAO DE UPDATE
$data = (Get-Date).adddays(-$maturidade)
#--------------------------------------------------------------------------------------------------------------
# REMOVER PACOTES QUE NAO INTERESSERAM
Get-WsusUpdate | Where {$_.update.title -like "*itanium*" -or $_.update.title -like "*ARM64*" -or $_.update.title -like "*32 Bits*" -or $_.update.title -like "*x86*" -or $_.update.title -like "*LanguageFeatureOnDemand*" -or $_.update.title -like "*farm do Microsoft*"} | Deny-WsusUpdate
Start-Sleep -s 5
# RETIRAR DA LISTA TOTAL AS ATUALIZACÕES "VENCIDAS"
#Get-WsusUpdate | Where-Object { $_.Update.GetRelatedUpdates(([Microsoft.UpdateServices.Administration.UpdateRelationship]::UpdatesThatSupersedeThisUpdate)).Count -gt 0 } | Deny-WsusUpdate
Get-WSUSUpdate -Classification All -Approval any | Where-Object { $_.Update.IsSuperseded -eq $True} | Deny-WsusUpdate
Start-Sleep -s 30
# ACEITANDO A EULA DOS PACOTES QUE EXIGEM E QUE ESTAO DENTRO DO PERIODO APROVADO
Get-WsusUpdate -Classification All -Approval Unapproved | Where-Object { ($_.Update.CreationDate -lt $data) -and ($_.update.isdeclined -ne $true) -and ($_.update.RequiresLicenseAgreementAcceptance -eq $true) } | ForEach { $_.update.AcceptLicenseAgreement() }
# APROVANDO O QUE HÁ DE NOVO DENTRO DO PERIODO APROVADO
Get-WsusUpdate -Classification All -Approval Unapproved | Where-Object { $_.Update.CreationDate -lt $data } | Approve-WsusUpdate -Action Install -TargetGroupName "All Computers"
Start-Sleep -s 5
#--------------------------------------------------------------------------------------------------------------
# CONEXAO COM O SERVIDOR WSUS
[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | Out-Null
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($env:computername, $False,8530);
Start-Sleep -s 5
#--------------------------------------------------------------------------------------------------------------
# LIMPEZA DO WSUS (LIBERAR DISCO)
# FONTE: https://www.vanstechelman.eu/content/how-to-run-the-wsus-server-cleanup-wizard-from-command-line
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
#--------------------------------------------------------------------------------------------------------------
# BAIXAR ATUALIZACOES DO WSUS (FAÇO POR FIM POIS NAO SEI QUANTO TEMPO IRA DEMORAR, NA PROXIMA EXECUÇÃO DO SCRIPT QUE SERÃO APROVADAS E/OU RECUSADAS)
$wsus.GetSubscription().StartSynchronization();
