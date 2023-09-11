cls
Get-WinEvent -Logname Security -FilterXPath "*[System[EventID=4624]]" | ForEach-Object {
    $data = $_.TimeCreated.tostring().replace("2020 ","2020;")
    $message = $_.Message -split "`n"
    $message | Select-String -Pattern '	Account Name:	' | ForEach-Object { $username=$_.tostring().replace("	Account Name:	","").Trim(" ").Trim("	")}
    if (($data -ne $data1) -and ($username -ne $username1))
    {
        echo "$data;$username"
    }
    $data1 = $data
    $username1 = $username
}
echo "--------------------------"
echo "Finalizado"