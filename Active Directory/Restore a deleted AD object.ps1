#List the deleted objects:

Get-ADObject -IncludeDeletedObjects -filter {deleted -eq $true}

#Restore a object (using ObjectGUID value, listed before)

Restore-ADObject -Identity '2cebd3a5-5897-40b4-a0eb-076dd4cc08ee' -Server your_dc.yourdomain.com