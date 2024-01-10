#Connect-ExchangeOnline
#-------------------------------------------------------------------------
#V2 - https://go.microsoft.com/fwlink/p/?linkid=2249705 and https://seesmitty.com/how-to-update-user-photos-in-azure-ad-with-powershell/
#Install-Module Microsoft.Graph
Connect-MgGraph
#-------------------------------------------------------------------------
$continue = $false
$default_path = "C:\Temp"
Clear-host
$file = $null
While ( $file -eq $null ) {
    $email = Read-Host "Insert the login (like user)"
    If ( ($email -notlike "*@*") -and ($email -notlike "*.org.br") ){
        $ldapmail = $null
        $ldapmail = (get-aduser $email -properties mail).mail
        If ( $ldapmail ){
            $email = $ldapmail
            $file = $email.Split("@")[0]+".jpg"
        }
        Else
        {
            Write-host "User not found, try again"
        }
    }
}
$folder = "Z:"
While ( -not (Test-Path -Path $folder) ) {
    $folder = Read-Host "Insert the folder (like $default_path )"
    If ( $folder -eq "" ){$folder = $default_path}
    #If ( -not (Test-Path -Path $folder\$file) ) {Write-host "Photo on $folder\$file not found, try again" }
}
$choose = $null
While ( -not (($choose -eq "get") -OR ($choose -eq "set")) ) {
    $choose = Read-Host "Type set (to set a photo), or get (to get a photo)"
    $choose = $choose.ToLower();
    If ( -not ( ($choose -eq "get") -OR ($choose -eq "set") ) ){Write-Host "This options do not exist, try again."}
}
switch ( $choose )
{
    #set { Set-UserPhoto $email -PictureData ([System.IO.File]::ReadAllBytes("$folder\$file")) }
    #get { (Get-UserPhoto $email).PictureData | Set-Content "$folder\$file" -Encoding byte }
    set { Set-MgUserPhotoContent -UserId $email -InFile "$folder\$file" }
    get { Get-MgUserPhotoContent -UserId $email -OutFile "$folder\$file" }
}

