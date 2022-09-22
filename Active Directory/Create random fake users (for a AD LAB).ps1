$ErrorActionPreference= 'silentlycontinue'
Clear-Host
#Random password function
Add-Type -AssemblyName System.Web
$Password = $null

Import-Module ActiveDirectory
Write-host "Getting Active Directory actual datas..."
$lista_ad = Get-ADUser -filter *

Write-host "Download data (random) via API"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Cookie", "layer0_bucket=68; layer0_destination=default; layer0_environment_id_info=1680b086-a116-4dc7-a17d-9e6fdbb9f6d9")

#If you have any SSL problemas to use the API
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true } 
#[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$response = Invoke-RestMethod 'https://my.api.mockaroo.com/template-ad.json?key=482be530' -Method 'GET' -Headers $headers

$response=$response.TrimEnd()
$array = $response.Split("`n")

$collum_names = ($array | Select-Object -First 1).split(",")

Write-host "Populating array with random data..."
$KeysArray = @()
$array | select -Skip 1 | ForEach-Object {
    $line = $_.split(",")
    $KeyData = $null
    $KeyData = New-Object PSObject
    For ($i=0; $i -lt $collum_names.count; $i++) {
        $name = $collum_names[$i]
        $value = $line[$i]
        #Retirar acentos (caso existam)
        $name = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding(1251).GetBytes($name))
        $value = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding(1251).GetBytes($value)) 
        $KeyData | Add-Member -MemberType NoteProperty -Name "$name" -Value "$value"
    }
    #Adicionar o nome completo
    $KeyData | Add-Member -MemberType NoteProperty -Name "full_name" -Value  ($KeyData.first_name.ToString() + " " +  $KeyData.last_name.ToString())
    #Definir possíveis Logins
    $QUAL_LOGIN = $null
    $possiveis_login = @()
    $possiveis_login += $KeyData.first_name.ToString() + "." + $KeyData.last_name.ToString()
    $possiveis_login += $KeyData.first_name.ToString() + "." + $KeyData.last_name.ToString().substring(0,1)
    $possiveis_login += $KeyData.first_name.ToString() + "." + $KeyData.last_name.ToString().substring(0,2)
    $possiveis_login += $KeyData.first_name.ToString().substring(0,1) + "." + $KeyData.last_name.ToString()
    $possiveis_login += $KeyData.first_name.ToString().substring(0,1) + "." + $KeyData.last_name.ToString().substring(0,1)
    $possiveis_login += $KeyData.first_name.ToString().substring(0,1) + "." + $KeyData.last_name.ToString().substring(0,2)
    $possiveis_login += $KeyData.first_name.ToString().substring(0,2) + "." + $KeyData.last_name.ToString()
    $possiveis_login += $KeyData.first_name.ToString().substring(0,2) + "." + $KeyData.last_name.ToString().substring(0,1)
    $possiveis_login += $KeyData.first_name.ToString().substring(0,2) + "." + $KeyData.last_name.ToString().substring(0,2)
    if ($KeyData.first_name.ToString().count -gt 2)
    {
        $possiveis_login += $KeyData.first_name.ToString().substring(0,3) + "." + $KeyData.last_name.ToString()
        $possiveis_login += $KeyData.first_name.ToString().substring(0,3) + "." + $KeyData.last_name.ToString().substring(0,1)
        $possiveis_login += $KeyData.first_name.ToString().substring(0,3) + "." + $KeyData.last_name.ToString().substring(0,2)
    }
    if ($KeyData.last_name.ToString().count -gt 2)
    {
        $possiveis_login += $KeyData.first_name.ToString() + "." + $KeyData.last_name.ToString().substring(0,3)
        $possiveis_login += $KeyData.first_name.ToString().substring(0,1) + "." + $KeyData.last_name.ToString().substring(0,3)
        $possiveis_login += $KeyData.first_name.ToString().substring(0,2) + "." + $KeyData.last_name.ToString().substring(0,3)
    }
    $possiveis_login = $possiveis_login.replace(".","") + $possiveis_login
    #Remover logins que não podem ser usados
    $possiveis_login = $possiveis_login | where {($_.length -ge 4) -and ($_.length -le 12)}
    $possiveis_login = $possiveis_login | select -Unique
    #Escolher o primeiro login da lista que não existe ainda
    $QUAL_LOGIN = $possiveis_login.ToLower() | where {$lista_ad.samaccountname -notcontains $_} | where {$KeysArray.login -notcontains $_} | Select-Object -first 1 
    $KeyData | Add-Member -MemberType NoteProperty -Name "login" -Value $QUAL_LOGIN
    #Adicionar o membro ao Array
    $KeysArray += $KeyData
}
#Remover nomes duplicados (se houver)
$KeysArray = $KeysArray | sort full_name -unique
#Organizar a lista
$KeysArray = $KeysArray | Sort-Object -Property city, departament

Write-host ""
Write-host "Populating the AD for LAB..."

$OU_city = $null 
$OU_departament = $null
$AD_DN = (Get-ADDomain).distinguishedname

$KeysArray | ForEach-Object {
    $first_name = $_.first_name
    $last_name = $_.last_name
    $city = $_.city
    $job_title = $_.job_title
    $departament = $_.departament
    $full_name = $_.full_name
    $login = $_.login 
    If ($OU_city -ne $city) {
        New-ADOrganizationalUnit -Name $city -Path $("$AD_DN").ToString()
    }
    $OU_city = $city
    If ($OU_departament -ne $departament) {
        New-ADOrganizationalUnit -Name $departament -Path $("OU=$OU_city,$AD_DN").ToString()
    }
    $OU_departament = $departament
    $Password = $null
    while( !($Password -cmatch "[A-Z\p{Lu}\s]") -and !($Password -cmatch "[a-z\p{Ll}\s]") -and !($Password -match "[\d]") -and !($Password -match "[^\w]") ){$Password=[System.Web.Security.Membership]::GeneratePassword(10,1)}
    New-ADUser -Name $full_name -DisplayName $full_name -GivenName $first_name -Surname $last_name -Description "A senha e: $Password" -Department $departament -SamAccountName $login -path $("OU=$OU_departament,OU=$OU_city,$AD_DN").ToString() -Title $job_title -Enabled $true -ChangePasswordAtLogon $false -AccountPassword (ConvertTo-SecureString -AsPlainText "$Password " -force) -passThru | Out-Null
}

Write-host "Finished, the password for each account is in the description attritubes"