'https://ss64.com/vb/syntax-userinfo.html
'https://devblogs.microsoft.com/scripting/how-can-i-create-a-new-registry-key/
'https://morgantechspace.com/2015/07/vbscript-check-if-user-is-member-of-group.html
'https://stackoverflow.com/questions/37168882/search-a-string-in-vbscript-to-verify-if-contains-a-character
Option Explicit

Dim DesktopPath, link, MappedDrive, objArgs, objEnv, objExplorer, objGroup, objNetwork, objRegistry, objShell, objSysInfo, objUser, objWMIService 
Dim regkey, SectorName, SharepointMapFolder, SiteName, state, strKeyPath, strRemoteShare, Tenant

Dim array, i, InvertedArray, OrganizationalUnit

On error resume next
'----------------------------------------------------------------------------------------------------------------------------------------
' INICIO DO SCRIPT
'----------------------------------------------------------------------------------------------------------------------------------------
Set objSysInfo = CreateObject("ADSystemInfo")
Set objNetwork = WScript.CreateObject("Wscript.Network")
Set objUser = GetObject("LDAP://" & objSysInfo.UserName)
Set objExplorer = WScript.CreateObject("InternetExplorer.Application")
Set objShell = WScript.CreateObject("WScript.Shell")
Set objWMIService = GetObject("winmgmts://./root/cimv2")
'----------------------------------------------------------------------------------------------------------------------------------------
' DEFININDO VARIAVEIS
'----------------------------------------------------------------------------------------------------------------------------------------
Set objArgs = Wscript.Arguments
Tenant = objArgs(0)
MappedDrive = objArgs(1)
'Tenant = "the_name_of_your_tenant"
'MappedDrive = "H:"
If (IsNull(Tenant) Or IsEmpty(Tenant)) Or (IsNull(MappedDrive) Or IsEmpty(MappedDrive)) Then
	wscript.quit
End If
'----------------------------------------------------------------------------------------------------------------------------------------
' OBTENDO INFORMACOES DO ACTIVE DIRECTORY
'----------------------------------------------------------------------------------------------------------------------------------------
OrganizationalUnit = Replace(objUser.distinguishedName,Split(objUser.distinguishedName,",")(0)&",","",1,1)
OrganizationalUnit = Replace(OrganizationalUnit ,",DC=","|",1,1)
OrganizationalUnit = Replace(OrganizationalUnit ,".","")
OrganizationalUnit = Replace(OrganizationalUnit ,",DC=",".")
OrganizationalUnit = Replace(OrganizationalUnit ,"OU=","")
OrganizationalUnit = Replace(OrganizationalUnit ,"CN=","")
OrganizationalUnit = Replace(OrganizationalUnit ,"|" &Split(OrganizationalUnit ,"|")(1) ,"")
SectorName = Split(OrganizationalUnit ,",")(0)
array = Split(OrganizationalUnit ,",")
InvertedArray = array
For i = Ubound(array) to LBound(array) Step - 1
    InvertedArray(Ubound(array)-i) = array(i)
Next
OrganizationalUnit = join(InvertedArray,"_")
'----------------------------------------------------------------------------------------------------------------------------------------
' OBTENDO O NOME DO SITE SHAREPOINT
'----------------------------------------------------------------------------------------------------------------------------------------
SiteName = OrganizationalUnit
'----------------------------------------------------------------------------------------------------------------------------------------
' CRIANDO ATALHO NO DESKTOP
'----------------------------------------------------------------------------------------------------------------------------------------
DesktopPath = objShell.SpecialFolders("Desktop")
Set link = objShell.CreateShortcut(DesktopPath & "\Sharepoint " & SiteName & ".lnk")
link.Arguments = "https://" & Tenant & ".sharepoint.com/sites/" & SiteName & "/Documentos/"
link.TargetPath = "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
link.WindowStyle = 3
link.WorkingDirectory = DesktopPath
link.Save
'----------------------------------------------------------------------------------------------------------------------------------------
' ABRINDO O NAVEGADOR
'----------------------------------------------------------------------------------------------------------------------------------------
'objShell.Run "msedge https://" & Tenant & ".sharepoint.com/sites/" & SiteName & "/Documentos --hide-scrollbars --content-shell-hide-toolbar"
'objExplorer.Navigate "https://" & Tenant & ".sharepoint.com/sites/" & SiteName & "/Documentos"
'objExplorer.Visible = true 
'Set objExplorer = Nothing
objShell.Run "C:\PROGRA~1\INTERN~1\iexplore.exe https://" & Tenant & ".sharepoint.com/sites/" & SiteName & "/Documentos/ -extoff"
'----------------------------------------------------------------------------------------------------------------------------------------
' DAR 60 SEGUNDOS PARA O USUARIO SE AUTENTICAR (CASO NAO ESTEJA)
'----------------------------------------------------------------------------------------------------------------------------------------
wscript.sleep 60000
'----------------------------------------------------------------------------------------------------------------------------------------
' ESPERANDO O SERVICO WEBCLIENT ESTAR OPERANDO
'----------------------------------------------------------------------------------------------------------------------------------------
state = objWMIService.Get("Win32_Service.Name='WebClient'").State
Do Until state="Running"
	state = objWMIService.Get("Win32_Service.Name='WebClient'").State
	wscript.sleep 5000
Loop
'----------------------------------------------------------------------------------------------------------------------------------------
' MAPEANDO DRIVE DE REDE
'----------------------------------------------------------------------------------------------------------------------------------------
strRemoteShare = "\\" & Tenant & ".sharepoint.com@SSL\sites\" & SiteName & "\Documentos"
objNetwork.MapNetworkDrive MappedDrive, strRemoteShare, False
'----------------------------------------------------------------------------------------------------------------------------------------
' ALTERANDO O NOME DO COMPARTILHAMENTO
'----------------------------------------------------------------------------------------------------------------------------------------
strKeyPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##" & Tenant & ".sharepoint.com@SSL#sites#" & SiteName & "#Documentos"
regkey = objshell.RegRead ("HKCU\" & strKeyPath & "\_LabelFromReg")
Const HKEY_CURRENT_USER = &H80000001
'strComputer = "."
'Set objRegistry = GetObject("winmgmts:\\" & strComputer & "\root\default:StdRegProv")
Set objRegistry = GetObject("winmgmts:\\.\root\default:StdRegProv")
If err.number<>0 then
	objRegistry.CreateKey HKEY_CURRENT_USER, strKeyPath
End If
strValueName = "_LabelFromReg"
szValue = "SharepointOnline - "& SectorName
objRegistry.SetStringValue HKEY_CURRENT_USER, strKeyPath, strValueName, szValue
'----------------------------------------------------------------------------------------------------------------------------------------
' DEFININDO VARIAVEIS DE AMBIENTE
'----------------------------------------------------------------------------------------------------------------------------------------
'Set objEnv = objShell.Environment("System")
Set objEnv = objShell.Environment("User")
objEnv("SharepointMapFolder") = SiteName
objEnv("SectorName") = SectorName