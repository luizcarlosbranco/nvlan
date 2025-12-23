#https://www.sharepointdiary.com/2018/01/migrate-file-share-to-sharepoint-online-using-powershell.html
#https://www.youtube.com/watch?v=WceeMca_vwY
#https://www.youtube.com/watch?v=xwKTFfhQWLY
#---------------------------------------------------------------------------------------------------------------------------------
#Install-Module SharePointPnPPowerShellOnline
#Install-Module -Name Microsoft.Online.SharePoint.PowerShell
#---------------------------------------------------------------------------------------------------------------------------------
#UTF-8
#chcp 65001
#$OutputEncoding = [Console]::OutputEncoding = [Text.Encoding]::UTF8
$handBrakeFile = "T:\Temp\CTI\HandBrakeCLI.exe"
$Counter = 0
$env:PNPLEGACYMESSAGE='false'
$PathMaxLength = 240
$FileMaxSize = 250MB
Clear-Host

#Get Sharepoint URL
Write-Host "Inform your COMPLETE URL"-NoNewline
$completeURL = Read-Host " "
$tenant = $completeURL.split("./")[2]
$SharePointSite = $completeURL.split("/")[4]
Write-Host "Your Site is https://" -NoNewline
Write-Host $tenant -ForegroundColor Yellow -NoNewline
Write-Host ".sharepoint.com/sites/" -NoNewline
Write-Host $SharePointSite -ForegroundColor Red
$askContinue = Read-Host "If its right, press Y and ENTER to continue..."
if ( ($askContinue -ne "y") -or ($askContinue -ne "Y") ) {break}

#Get local folder
$folderDialog = New-Object -ComObject Shell.Application
$folder = $folderDialog.BrowseForFolder(0, "Choose the folder to check", 0, 0)
$SourceFolder = $folder.Self.Path

#Listing local content
Write-Host "----- Listing the current content"
#Remove thumbs.db files
#gci -Force "$SourceFolder" -Recurse | ?{$_ -match "thumbs.db"} | Remove-Item -Force | Out-Null
$items = Get-ChildItem $SourceFolder -Recurse -File | Select-Object Basename,Name,FullName,Extension,DirectoryName,Length,@{Name="Date"; Expression={$_.LastAccessTime}},@{Name="Hash"; Expression={$null}}, @{Name="NomeSemDigitos"; Expression={ $_.Name -replace '\d', '' }}, @{Name="SizeInBytes"; Expression={ [Math]::Round([float]$_.Length / 1024) }}
$LongPaths = $items | Where-object { $_.FullName.Length -gt $PathMaxLength }
$BigFiles = $items | Where-Object {$_.Length -gt $FileMaxSize}
#Checking (and removing) if already has a compressed video.
$BiggerCompressed = @()
If ( ($BigFiles).count -ge 1 ) {
    $BigFiles | ForEach-Object {
        $Remove = $_
        $Extension = $_.Extension
        $BaseName = $_.BaseName
        If ($Extension -match '\.(mp4|mov|vob|avi|mkv|wmv)$') {$Extension = ".mp4"}
        $outputFile = Join-Path $_.DirectoryName ($BaseName + "_compressed" +$Extension)
        If (Test-Path $outputFile) {
            If ($outputFile.Length -lt 250MB) {
                $BigFiles = $BigFiles | Where-object { $_ -ne $Remove }
                $BiggerCompressed += $_
            }
        }
    }
}
$wildcardChars = '#*?%&/'
$escapedChars = [regex]::Escape($wildcardChars)
$fullpathWithWildcards = $items | Where-Object { $_.FullName -match "[$escapedChars]" }
#Ask to compress the videos
$bigVideos = $BigFiles | Where-Object { $_.Name -match '\.(mp4|mov|vob|avi|mkv|wmv)$' }
If ( ($bigVideos.count -ge 1) -AND (Test-Path $handBrakeFile) ) {
    Write-Host ""
    Write-Host "You have $($bigVideos.count) videos bitther than 250MB, do you want compress then"
    $compressVideos = Read-Host "Press Y and ENTER to create the compressed file, or just ENTER to continue... "
    If ( ($compressVideos).ToLower() -eq "y" ) {
        $bigVideos | ForEach-Object {
            $inputFile = $_.FullName
            $outputFile = Join-Path $_.DirectoryName ($_.BaseName + "_compressed.mp4")
            If (! (Test-Path $outputFile) ) {
                Get-date
                Write-Host "Compressing $inputFile" -NoNewline
                & $handBrakeFile -i "$inputFile" -o "$outputFile" --disable-hw-decoding --preset "Fast 720p30" -e x264 -q 30 -B 160 -E av_aac --mixdown mono > $null 2>&1
                If (Test-Path $outputFile) { Write-Host " - DONE" -ForegroundColor Green }
                Else { Write-Host " - Failed" -ForegroundColor Red }
            }
        }
    }
}
#Listing the Files that need some correction
If ( ($LongPaths).count -ge 1 ) {
    Write-Host "---- Paths with more then $PathMaxLength caracteres ----------------------------------------"
    $LongPaths | ForEach-Object { "$($_.FullName)`r`n" }
#        $FileName = $_.Name
#        $newFileName = $_.Name
#        $FullName = $_.FullName
#        $newFileName = $newFileName.Replace("  ", " ")
#        $newFileName = $newFileName.Replace("..", ".")
#        If ($FileName -ne $newFileName) {
#            Rename-Item -Path $FullName -NewName $newFileName
#            Write-host $FullName
#            Write-host ""
#        }
}
If ( ($BigFiles).count -ge 1 ) {
    Write-Host "---- Files with more then 250MB ----------------------------------------"
    $BigFiles | ForEach-Object { "$($_.FullName)`r`n" }
}
If ( ($BiggerCompressed).count -ge 1 ) {
    Write-Host "---- Files Compressed ----------------------------------------"
    $BiggerCompressed | ForEach-Object { "$($_.FullName)`r`n" }
}
If ( ($fullpathWithWildcards).count -ge 1 ) {
    Write-Host "---- Folders with wildcards ----------------------------------------"
    $fullpathWithWildcards | ForEach-Object {
        $FileName = $_.Name
        $newFileName = $_.Name
        $FullName = $_.FullName
        ($wildcardChars -split '') | Where-Object { $_ -and $_ -ne ' ' } | ForEach-Object {
            $newFileName = $newFileName.Replace($_, "_")
        }
        $newFileName = $newFileName.Replace("  ", " ")
        $newFileName = $newFileName.Replace("..", ".")
        If ($FileName -ne $newFileName) {
            #Rename-Item -Path $FullName -NewName $newFileName
            Write-host $FullName
            Write-host ""
        }
    }
    Write-Host "---- Files with wildcards ----------------------------------------"

}
If ( (($LongPaths).count -ge 1) -OR (($BigFiles).count -ge 1) -OR (($fullpathWithWildcards).count -ge 1) ) { Read-Host "Press ENTER, to continue anyway" }
#($LongPaths).Fullname | clip
#($BigFiles).Fullname | clip
#($BiggerCompressed).Fullname | clip
#($fullpathWithWildcards).Fullname | clip

$items = $items | Where {$LongPaths -NotContains $_}
$items = $items | Where {$BigFiles -NotContains $_}
$items = $items | Where {$fullpathWithWildcards -NotContains $_}

$LongPaths = $null
$BigFiles = $null
$BiggerCompressed = $null
$fullpathWithWildcards = $null
#$items = $null

$askSearchHash = Read-Host "Press Y (and ENTER) to check files with same hash"
If ( ($askSearchHash -eq "y") -or ($askSearchHash -eq "Y") ) {
    Write-Host "Searching for duplicated files...."
    #$PossiveisDuplicados = Get-ChildItem $SourceFolder -Recurse -File | Select-Object Name,FullName,DirectoryName,Length,@{Name="Date"; Expression={$_.LastAccessTime}},@{Name="Tipo"; Expression={$_.Basename}},@{Name="Hash"; Expression={$null}}, @{Name="NomeSemDigitos"; Expression={ $_.Name -replace '\d', '' }}, @{Name="SizeInBytes"; Expression={ [Math]::Round([float]$_.Length / 1024) }}
    #$PossiveisDuplicados = @($PossiveisDuplicados | Where-Object SizeInBytes -gt 1024 | Where-Object Name -notmatch '^~\$' | Where-Object Name -notlike '._*' | Group-Object -Property Tipo, Length | Where-Object { $_.Count -gt 1 } | Where-Object { $_.Count -lt 100 } | Select-Object -ExpandProperty Group)
    $PossiveisDuplicados = @($items | Where-Object SizeInBytes -gt 1024 | Where-Object Name -notmatch '^~\$' | Where-Object Name -notlike '._*' | Group-Object -Property Extension, Length | Where-Object { $_.Count -gt 1 } | Where-Object { $_.Count -lt 100 } | Select-Object -ExpandProperty Group)
    $PossiveisDuplicados = @($PossiveisDuplicados | Group-Object -Property DirectoryName, Name | Where-Object { $_.Count -eq 1 } | Select-Object -ExpandProperty Group)
    $PossiveisDuplicados | ForEach-Object {
        $FullName = $_.FullName
        $Name = $_.Name
        If ( ( ![System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters("$FullName") ) -and ( Test-Path -Path "$FullName" -PathType leaf ) -and ( $Name -notmatch '^~\$' ) -and !( $Name -like '._*' ) ) { $_.Hash = (Get-FileHash "$FullName").Hash }
    }
    $PossiveisDuplicados = @($PossiveisDuplicados | Where-Object {$_.Hash } | Group-Object -Property Hash, Length, BaseName | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Group)
    Write-Host "----- Filtering duplicated hashes" -NoNewline
    $HashesRepetidos = ($PossiveisDuplicados | Group-Object -Property Hash | Where-Object { $_.Count -gt 1 }).Name
    $countHashes = ($PossiveisDuplicados).count
    Write-Host " ( $countHashes )"
    foreach ($HashRepetido in $HashesRepetidos){
        $PossiveisDuplicados | Where-Object Hash -eq $HashRepetido | Sort-Object -Property Date | ForEach-Object { $_.FullName }
        Write-Host "---------------------------"
    }
}

$askCheckSPFiles = Read-Host "Press y (and ENTER) if is the FIRST COPY (will not check existing files)"

#Conecting to SharePoint
Write-Host "----- Conecting into SharePoint https://" -NoNewline
Write-Host "$tenant" -ForegroundColor Yellow -NoNewline
Write-Host ".sharepoint.com/sites/" -NoNewline
Write-Host "$SharePointSite" -ForegroundColor Red

$SiteURL = "https://$tenant.sharepoint.com/sites/$SharePointSite"
Connect-PnPOnline -Url "$SiteURL" -UseWebLogin

#Consulta mais leve (menos uso de RAM)
function Test-SPFileExists {
    param(
        [string]$SiteURL,
        [string]$ServerRelativeUrl        
    )
    try {
        #Invoke-PnPSPRestMethod -Method Get -Url "https://sestsenat.sharepoint.com/sites/CNT_DIEX_DIEXSEC/_api/web/GetFileByServerRelativeUrl('/sites/CNT_DIEX_DIEXSEC/Documentos/Arquivo Morto CNT (Q) - Atalho (2).lnk')"
        Invoke-PnPSPRestMethod -Method Get -Url "$SiteURL/_api/web/GetFileByServerRelativeUrl('$ServerRelativeUrl')" -ErrorAction SilentlyContinue 2>$null
        if ($response) { 
            return $true 
        }
    }
    catch {
        return $false
    }
}


#Creating folders
Write-Host "----- Creating folders"
$folders = ($items).DirectoryName | Get-Unique
$folders = $folders | Where-Object { $_ -ne $SourceFolder }
$folders =$folders.replace($SourceFolder+"\","")
$folders =$folders.replace("\","/")
$folders | ForEach-Object {
    $FolderURL = $_
    $FolderURL = "Documentos/"+$FolderURL
    try {
        Resolve-PnPFolder -SiteRelativePath $FolderURL -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Host "Error creating $FolderURL" -ForegroundColor Red
    }
    Finally {
        Write-Host "created $FolderURL" -ForegroundColor Green
    }
}

Write-Host "----- Copying files"
foreach ($item in $items) {
#foreach ($item in (Get-ChildItem $SourceFolder -Recurse -File)) {
        $FullName = $item.FullName
        $FolderSource = $item.DirectoryName
        $FileName = $item.Name
        $TargetFolderURL = "Documentos"+$FolderSource.Replace($SourceFolder,"").Replace("\","/")
        try {
            $CheckFolderURL ="/sites/" + $SharePointSite + "/Documentos" + $FolderSource.Replace($SourceFolder,"").Replace("\","/")
            If ( ($askCheckSPFiles -eq "y") -or ($askCheckSPFiles -eq "Y") ) {
                Add-PnPFile -Path $FullName -Folder $TargetFolderURL -ErrorAction Stop | out-null
                $Counter++
            } else {
                If(-not (Test-SPFileExists -SiteURL $SiteURL -ServerRelativeUrl "$CheckFolderURL/$FileName"))
                {
                        Add-PnPFile -Path $FullName -Folder $TargetFolderURL -ErrorAction Stop | out-null
                        #$null = Invoke-PnPSPRestMethod -Url "$SiteURL/_api/web/GetFolderByServerRelativeUrl('$TargetFolderURL')/Files/Add(url='$FileName',overwrite=true)" -Method Post -Content ([System.IO.File]::ReadAllBytes($FullName)) -ContentType "application/octet-stream"
                        $Counter++
                }
            }
        }
        catch {
            Write-Host "Not copied $FullName" -ForegroundColor Red
        }
    $FileExists = $null
}
Write-Host "$Counter files copied"
