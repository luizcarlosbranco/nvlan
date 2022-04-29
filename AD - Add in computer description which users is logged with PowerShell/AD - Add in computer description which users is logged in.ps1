$ErrorActionPreference= 'silentlycontinue'
$date_with_offset= (Get-Date).AddDays(-30)
Get-ADComputer -Properties * -Filter {(Enabled -eq "True") -and (Description -notlike "*") -and (LastLogonDate -lt $date_with_offset) -and (OperatingSystem -notLike "*Server*") -and (OperatingSystem -Like "Windows*") -and (enabled -eq "true") } | ForEach-Object {
    $PC = $_.name
    If (Test-Connection -Count 1 -ComputerName $PC -Quiet)
    #If (test-netconnection -ComputerName $PC) 
    {
        $USER = $null
        $USER = (query user /server:$PC | select -skip 1).split(" ")[1]
        if ($USER -ne $null)
        {
            write-host "$PC - $USER"
            Set-ADComputer $PC -Description "Computador usado por $USER"
        }
    }
}
