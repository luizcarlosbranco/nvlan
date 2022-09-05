$continue = $false
While ( $continue -eq $false ) {
    Clear-host
    $email = Read-Host "Insert the email (like user@yourdomain.com)"
    $folder = Read-Host "Insert the folder (like C:\Temp)"
    $choose = Read-Host "Type import (to import), or export (to export)"
    If ( ($email -like "*@*") -and ($email -like "*.*") -and (Test-Path -Path "$folder") -and ( ($choose = "import") -OR ($choose = "export") ) ){
        $continue = $True
    }
    Else
    {
        Write-Host "Try againg..."
        Read-Host
    }
}
#-------------------------------------------------------------------------
Connect-ExchangeOnline
$file = $email.Split("@")[0]+".jpg"
switch ( $choose )
{
    import { Set-UserPhoto $email -PictureData ([System.IO.File]::ReadAllBytes("$folder\$file")) }
    export { (Get-UserPhoto $email).PictureData | Set-Content "$folder\$file" -Encoding byte }
}