Dim fso 
Set fso = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")
HOMEDRIVE = objShell.ExpandEnvironmentStrings( "%HOMEDRIVE%" )
HOMEPATH = objShell.ExpandEnvironmentStrings( "%HOMEPATH%" )
If Not(fso.FolderExists(HOMEDRIVE+""+HOMEPATH+"\Desktop\OneDrive - YOUR_COMPANY")) Then 
	objShell.Run("mshta.exe \\yourdomain.com\netlogon\Check_OneDrive\CheckOneDrive.hta")
End If