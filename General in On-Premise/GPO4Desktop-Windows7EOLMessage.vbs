Dim strComputer, objWMIService, colItems, SupportURL, WindowsVersion
strComputer = "." 
SupportURL = "https://suporte.suaempresa.com"
WindowsVersion = "Windows 7"
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2") 
Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_OperatingSystem",,48)

For Each objItem in colItems 

'	If InStr(objItem.Name, WindowsVersion) > 0 Then
		dim answer
		answer=MsgBox("Essa é uma mensagem automática da equipe da TI!" & vbcrlf &""& vbcrlf &_
		"Seu computador possuí o "&WindowsVersion&" e essa versão não terá mais suporte a partir de 2020" & vbcrlf &"" & vbcrlf &_
		"Se você ainda não quer solicitar o upgrade do seu Windows, clique em CANCELAR" & vbcrlf &"" & vbcrlf &_
		"Caso não haja impedimento, clique em OK para abrir um chamado para este computador ser atualizado",17,"Seu Windows irá EXPIRAR")

		'MsgBox(prompt[,buttons][,title][,helpfile,context])
		'0 = vbOKOnly - OK button only
		'1 = vbOKCancel - OK and Cancel buttons
		'2 = vbAbortRetryIgnore - Abort, Retry, and Ignore buttons
		'3 = vbYesNoCancel - Yes, No, and Cancel buttons
		'4 = vbYesNo - Yes and No buttons
		'5 = vbRetryCancel - Retry and Cancel buttons
		'16 = vbCritical - Critical Message icon
		'32 = vbQuestion - Warning Query icon
		'48 = vbExclamation - Warning Message icon
		'64 = vbInformation - Information Message icon
		'0 = vbDefaultButton1 - First button is default
		'256 = vbDefaultButton2 - Second button is default
		'512 = vbDefaultButton3 - Third button is default
		'768 = vbDefaultButton4 - Fourth button is default
		'0 = vbApplicationModal - Application modal (the current application will not work until the user responds to the message box)
		'4096 = vbSystemModal - System modal (all applications wont work until the user responds to the message box)
		If answer = vbOK Then
			Dim WscriptSchell
			Set WscriptSchell = CreateObject("WScript.Shell")
			WscriptSchell.Run SupportURL, 9
		Else
			MsgBox"Você cancelou o aviso, você continuará recebendo essa notificação toda vez que ligar o computador",48,"Script CANCELADO"
		End If
'	End If
	wscript.quit
Next