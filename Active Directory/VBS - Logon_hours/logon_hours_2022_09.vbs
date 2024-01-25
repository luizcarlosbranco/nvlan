On Error Resume Next

'Obtem os dados da conta LDAP
Dim objSysInfo, objUser
Set objSysInfo = CreateObject("ADSystemInfo")
'5 tentativas de conexão ao AD (problemas em laptops em Wifi, logar em cache, mas ainda não tem acesso à rede)
xcount = 0
While xcount < 5
	Set objUser = GetObject("LDAP://" & objSysInfo.UserName)
	If IsNull(objUser) or IsEmpty(objUser) Then
		xcount = xcount+1
		If (xcount = 5) Then
			Wscript.quit
		Else
			Wscript.sleep 3000
		End If
	Else
		xcount = 5
	End If
Wend
arrLogonHours = objUser.Get("logonHours")

Dim arrLogonHoursBytes(20)
Dim Schedule(7,23)
For i = 1 To LenB(arrLogonHours)
     arrLogonHoursBytes(i-1) = AscB(MidB(arrLogonHours, i, 1))
Next

'Obtem a agenda de horarios da conta LDAP
intCounter = 0
For Each LogonHourByte In arrLogonHoursBytes
	arrLogonHourBits = GetLogonHourBits(LogonHourByte)
 	For Each LogonHourBit In arrLogonHourBits
		'Sei que passando 24 horas é outro dia, então vou obter o dia a partir do total de horas dividido por 24
		check_day = intCounter\24
		'Vou obter a hora DESSE dia pegando o total de horas e subtraindo as horas dos dias anteriores
		check_hour = (intCounter - (check_day*24))
		'wscript.echo "semana " & check_day & " - as " & check_hour & " horas - liberacao: "& LogonHourBit
		Schedule(check_day,check_hour) = LogonHourBit
	        intCounter = 1 + intCounter
	Next
Next

'OBTENDO O DIA DA SEMANA E A HORA EM UTC
Set dateTime = CreateObject("WbemScripting.SWbemDateTime")
dateTime.SetVarDate (now())
This_Moment_UTC = dateTime.GetVarDate (false)
'Vou obter a data futura em uma hora (pois se for 23 horas, vai mudar o dia também)
dateTime.Hours = dateTime.Hours+1
NextHour_UTC = dateTime.GetVarDate (false)
'Vou obter os valores com o timezone local, para usar na hora de exibir a mensagem para o usuário
NextHour_TZ = dateTime.GetVarDate ()
'Defindo todas os dias e horas que usaremos nesse script
Now_Weekday = Weekday(This_Moment_UTC)-1
NextHour_UTC_Weekday = Weekday(NextHour_UTC)-1
Now_Hour_UTC = DatePart("h", This_Moment_UTC)
NextHour_UTC_Hour = DatePart("h", NextHour_UTC)
NextHour_Hour_TZ = DatePart("h", NextHour_TZ)

'Vamos dar alerta se na proxima hora vai acabar o horario de logon OU bloquear se já acabou o tempo
If Schedule(Now_Weekday,Now_Hour_UTC) = 0 Then
	Set oShell = WScript.CreateObject ("WScript.Shell")
	oShell.run "Rundll32.exe User32.dll,LockWorkStation"
ElseIf Schedule(Now_Weekday,NextHour_UTC_Hour) = 0 Then
	dim answer
	answer = MsgBox("Sua conta de rede ira bloquear as "& NextHour_Hour_TZ &" horas" & vbcrlf & "" & vbcrlf & "Se for preciso, entre em contato com o suporte",48,"Sistema CNT")
End If

Function GetLogonHourBits(x)
	Dim arrBits(7)
	For i = 7 to 0 Step -1
		If x And 2^i Then
			arrBits(i) = 1
		Else
			arrBits(i) = 0
		End If
	Next
	GetLogonHourBits = arrBits
End Function