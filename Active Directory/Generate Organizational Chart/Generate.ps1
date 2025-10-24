# CUSTOM (CHANGE) THIS PART OF THE SCRIPT
#Default information (If is blank in some user, CHANGE)
$DefaultTelephone = "+55 (61) 98505-1070"
$DefaultTitle = "------------------"
$DefaultEmail = "equipe@nvlan.com.br"
# Avatar image (UTR with a Avatar image/icon)
$avatarURL = "https://openclipart.org/image/800px/307452"
$htmlFolder =  "D:\Generate Organizational chart"
$templateFile = "template5.html" #(could be template1.html to template5.html)
#-------------------------------------------------------------------------------------------
$global:OrgArray = @()
$global:UserId = 1

# Get the avatar image
$webClient = New-Object System.Net.WebClient
$imageBytes = $webClient.DownloadData($avatarURL)
$contentType = $webClient.ResponseHeaders["Content-Type"]
if (-not $contentType) {
    switch -regex ($url.ToLower()) {
        '\.jpg$|\.jpeg$' { $contentType = "image/jpeg" }
        '\.png$'         { $contentType = "image/png" }
        '\.gif$'         { $contentType = "image/gif" }
        '\.bmp$'         { $contentType = "image/bmp" }
        '\.webp$'        { $contentType = "image/webp" }
        default           { $contentType = "application/octet-stream" }
    }
}
# Convert image to Base64
$base64String = [System.Convert]::ToBase64String($imageBytes)
$DefaultIconBase64 = "data:$contentType;base64,$base64String"

function Order-OrgArray {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [array]$OrgArray
    )
    process {
        $OrgArray | 
        Select-Object *, @{Name="OrderTitle";Expression={
            switch -regex ($_.Title.ToLower()) {
                '^diretor'     { 1; break }
                '^secretar'    { 2; break }
                '^gerente'     { 3; break }
                '^coordenador' { 4; break }
                '^estagi'      { 6; break }
                'jovem'        { 7; break }
                default        { 5 }
            }
        }} |
        Sort-Object PID, OrderTitle, Name
    }
}

function Get-ADOrgTopology {  
    [CmdletBinding()]
    param(  
        [Parameter(Mandatory = $true)]
        [string]$Manager,
        [int]$Level,
        [int]$ParentId
    )    
    $UserData = Get-ADUser $Manager -Properties DisplayName, manager, mail, telephoneNumber, title, thumbnailPhoto
    If(!$UserData) {
        Write-Host "User $Manager not found!"
    }
    Else {
        if (!$Level) { $Level = 1 }
        $name = $UserData.DisplayName
        $fullname = $UserData.Name
        $title = $UserData.Title
        #Set "tag" depending of the user title (change if you want)
        switch -Wildcard ($title) {
            "diretor*"      { $tag = "ceo" }
            "secret*"       { $tag = "assistant" }
            "gerente*"      { $tag = "gerente" }
            "coordenador*"  { $tag = "coordenador" }
            "estag*"        { $tag = "estagiario" }
            default         { $tag = "0" }
        }
        #Setting default valeus, if the user value is blank
        if (!$title) { $title = $DefaultTitle }
        $mail = $UserData.mail
        if (!$mail) { $mail = $DefaultEmail }
        $telephoneNumber = $UserData.telephoneNumber
        if (!$telephoneNumber) { $telephoneNumber = $DefaultTelephone }
        $thumbnailPhoto = $UserData.thumbnailPhoto
        If (!$thumbnailPhoto)
        {
            $thumbnailPhoto = "data:image/png;base64,$DefaultIconBase64"
        }
        Else
        {
            $thumbnailPhoto = [System.Convert]::ToBase64String($thumbnailPhoto)
            $thumbnailPhoto = "data:image/png;base64,$thumbnailPhoto"
        }
        # Store the current ID
        $CurrentId = $global:UserId
        # Add to array with ParentId ($null if the first node)
        $global:OrgArray += [PSCustomObject]@{
            ID             = $CurrentId
            PID            = $ParentId
            Name           = $name
            FullName       = $fullname
            Title          = $title
            Tag            = $tag
            Email          = $mail
            Telephone       = $telephoneNumber
            thumbnailPhoto = $thumbnailPhoto
        }
        $global:UserId++
        # Search the Team
        $DirectReports = Get-ADUser -Filter { manager -eq $Manager }
        $NewLevel = $Level + 1
        $DirectReports | Where-Object { $_.Enabled -eq $true } | ForEach-Object {
            # Set the current ID as ParentId for the Team
            Get-ADOrgTopology -Manager $_.DistinguishedName -Level $NewLevel -ParentId $CurrentId
        }
    }  
}
Clear-Host
$ManagerName = Read-Host "Insert the username in the top of you Organogram"
Get-ADOrgTopology -Manager $ManagerName

#Show (for test only)
#$OrgArray | Format-Table -AutoSize

If ($OrgArray) {
    $OrgArray = Order-OrgArray -OrgArray $OrgArray
    $templateFile = $htmlFolder +"\"+ $templateFile
    If (Test-Path $templateFile) {
        $Template_DefaultSite = Get-Content $templateFile
        foreach ($line in $OrgArray) {
            $string = "      { id: `"" + $line.ID +"`","
            If ($line.PID -ne 0) { $string += "pid: `""+$line.PID+"`","}
            If ($line.Tag -ne "0") { $string += " tags: [`""+$line.Tag+"`"],"}
            $string += " name: `""+ $line.Name +"`", Title: `""+ $line.Title +"`", Phone: `""+ $line.Telephone +"`", Email: `""+ $line.Email +"`", img: `""+ $line.thumbnailPhoto +"`"},"
            $Template_DefaultSite = $Template_DefaultSite.replace("//NodeList",$string +"`n//NodeList")
        }
        $Template_DefaultSite | Out-File -Encoding utf8 -FilePath "$htmlFolder\index.html" -Force
        Write-Host "Done"
    }
    Else {Write-Host "$templateFile not found!"}
}
