#EWS_PreReq - https://docs.microsoft.com/pt-br/dotnet/api/microsoft.exchange.webservices.data.exchangeservice?view=exchange-ews-api
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------
# CHANGE THE VARIABLES BELOW
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------
# FOR Exchange OnPremise
#$UserName = $env:UserName
#$Domain =$env:USERDNSDOMAIN
# FOR Exchange Online
$UserName = "your_email@your_domain.com"
$Password = "YOUR_PASSWORD"
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------
#$MAIL_TO = "person1@yourdomain.com", "person2@yourdomain.com"
$MAIL_TO = $UserName
#$MAIL_CC = "person3@yourdomain.com", "person4@yourdomain.com"
$MAIL_CC = $null
$MAIL_SUBJECT = "MAIL_SUBJECT"
$MAIL_MESSAGE = "<p><img src='data:image/jpeg;base64,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' alt='' width='430' height='37' /></p>"
$MAIL_MESSAGE += "<h1>TEST MESSAGE</h1>"
$MAIL_MESSAGE += "<p>&nbsp;</p>"
$MAIL_MESSAGE += "<p>This is just a test.</p>"
$MAIL_MESSAGE += "<p>&nbsp;</p>"
$MAIL_MESSAGE += "<p><b>Att</b>,</p>"
$MAIL_MESSAGE += "<p>$MAIL_FROM</p>"
$MAIL_MESSAGE += "<p>&nbsp;</p>"
$EWS_DLL = (Get-Location).Path+"\EWS\Microsoft.Exchange.WebServices.dll"
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------
# BEGIN
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------
If (!(Test-Path $EWS_DLL))
{
    Write-Host "EWS not found"
    break
}
Import-Module -Name "$EWS_DLL"
$service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService
$MAIL_FROM = "$UserName@$Domain"
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------
#If Exchange OnPremise
#$Service.UseDefaultCredentials = $true
#If Exchange Online
$service.Credentials = New-Object System.Net.NetworkCredential -ArgumentList $UserName, $Password
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------
$service.URL = New-Object Uri("https://outlook.office365.com/EWS/Exchange.asmx")
$mbx = New-Object Microsoft.Exchange.WebServices.Data.Mailbox($MAIL_FROM)
$folderId = New-Object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot, $mbx )
$view = New-Object Microsoft.Exchange.WebServices.Data.FolderView(100)
$view.PropertySet = New-Object Microsoft.Exchange.WebServices.Data.PropertySet([Microsoft.Exchange.Webservices.Data.BasePropertySet]::FirstClassProperties)
$view.PropertySet.Add([Microsoft.Exchange.Webservices.Data.FolderSchema]::DisplayName)
$view.Traversal = [Microsoft.Exchange.Webservices.Data.FolderTraversal]::Deep
$rootFolder = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service, [Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot)
$eMail = New-Object -TypeName Microsoft.Exchange.WebServices.Data.EmailMessage -ArgumentList $Service
$eMail.Subject = "$MAIL_SUBJECT"
If ($MAIL_TO) { $MAIL_TO | ForEach-Object { $eMail.ToRecipients.Add($_) | Out-Null } }
If ($MAIL_CC) { $MAIL_CC | ForEach-Object { $eMail.ToRecipients.Add($_) | Out-Null } }
If ($Attachment_File) {$eMail.Attachments.AddFileAttachment("$Attachment_File") | Out-Null }
$eMail.Body = "$MAIL_MESSAGE"
#$eMail.Send()
$eMail.SendAndSaveCopy()
Write-Host " Mail Sent!"