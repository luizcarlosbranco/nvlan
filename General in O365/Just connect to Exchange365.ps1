#Run AS ADMIN
#In the first time, run:
Install-Module -Name ExchangeOnlineManagement -RequiredVersion 1.0.1

#With the module, execute:
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -ShowProgress $true

#Now, just test:
Get-AddressList