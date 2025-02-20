$FolderPath = "D:\Sector" # Just an Example
$NETBIOS_DOMAINNAME = "SESTSENAT"
$ADD_GROUP_NAME = "domain admins"
$ADD_PERMITION = "FullControl" #FullControl, Modify, AppendData, CreateFiles, ReadAttributes, ReadPermissions, etc. - Use (Get-Acl 'L:\Test\Beez\RAPJOUR\Appels List\Correct').Access
$RULE = "Allow" # Allow or Deny

#If you want to create that folder first
#New-Item -ItemType directory -Path $FolderPath 

# ----------------------------- SCRIPT -----------------------------
$acl = Get-Acl $FolderPath
$acl.SetAccessRuleProtection($True, $False)
$acl.Access | %{$acl.RemoveAccessRule($_)} 
$A = New-Object System.Security.AccessControl.FileSystemAccessRule("$NETBIOS_DOMAINNAME\$GROUP_NAME","$ADD_PERMITION","ContainerInherit, ObjectInherit","None","$RULE") 
#$B = New-Object System.Security.AccessControl.FileSystemAccessRule("$NETBIOS_DOMAINNAME\$GROUP_NAME","$ADD_PERMITION","ContainerInherit, ObjectInherit","None","$RULE")
$acl.AddAccessRule($A)
#$acl.AddAccessRule($B)
Set-Acl $FolderPath $acl | Out-Null