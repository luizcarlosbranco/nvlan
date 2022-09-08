Get-ADGroupMember "Group Name" | ForEach-Object {Remove-ADGroupMember "Grop Name" $_ -Confirm:$false}
