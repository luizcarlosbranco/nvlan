#1 - RUN AS ADMIN
#If it is the first time, run the command: Install-Module -Name ExchangeOnlineManagement -RequiredVersion 1.0.1
#----------------------------------------------------------------------------------------------------------------------------------------
$message = "OOO Message.<br><br>Thist is a OutOfOffice Mesage<br><br>Contact the support team."
$mailbox = "reinaldocesar@cnt.org.br"
#----------------------------------------------------------------------------------------------------------------------------------------
#enabling modules
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline
#----------------------------------------------------------------------------------------------------------------------------------------
Set-MailboxAutoReplyConfiguration -Identity $mailbox -AutoReplyState Scheduled -StartTime "12/27/2021 00:00:01" -EndTime "1/9/2022 23:59:59" -InternalMessage $message -ExternalMessage $message
#Set-MailboxAutoReplyConfiguration -Identity $mailbox -AutoReplyState Enabled -InternalMessage $message -ExternalMessage $message
