	$YourDomain = "yourdomain.com"
	$ITEmail = "it@yourdomain.com"
    $Teams = "Marketing", "IT"
	$MainDrive = "E:\"
	$Server = "youserserver"
    $HomeArchiveFolder = "$MainDrive\ArquivoMorto"
	$SharedArchiveFolder = "ArquivoMorto"
    $TeamFolder = "$MainDrive\deptos"
    $ProjectsFolder = "$MainDrive\Projetos"
	$SmtpServer = "youremailserver.yourdomain.com"
    $YearsLimitForAllFiles = 10
    $YearsLimitForLargeFiles = 5
    $AgeLimitForLargeFiles = 300MB
    #chcp 1252
    #$ErrorActionPreference = 'silentlycontinue'
	#---------------------------------------------------------------------------------
    $FSRMReportFolder = (Get-FsrmSetting).ReportLocationOnDemand
    Clear-Host
	$ServerName = "\\$Server.$YourDomain\"
    $Days4ExpirationFile = ((Get-date)-(get-date).AddYears(-$YearsLimitForAllFiles)).Days
    foreach ($team in $Teams){
        
        If (! (Test-Path "$HomeArchiveFolder\$team")) {
            robocopy "$TeamFolder\$team" "$HomeArchiveFolder\$team" /copy:S /NS /NJH /NJS /NP /UNILOG+:C:\Temp\LOG_ArquivoMorto.txt | Out-Null
            Get-Acl -Path "$TeamFolder\$team" | Set-Acl -Path "$HomeArchiveFolder\$team"
        }

        robocopy "$TeamFolder\$team\0 - Mover para o Arquivo Morto\" "$HomeArchiveFolder\$team\" /move /E /R:1 /W:1 /NS /NJH /NJS /NP /UNILOG+:C:\Temp\LOG_ArquivoMorto.txt | Out-Null
        New-Item -Path "$TeamFolder\$team\" -Name "0 - Mover para o Arquivo Morto" -ItemType "directory"

        $ArquivosMovidos = 0

        $CorpoDoEmail = $null
        $mandaEmail = $false

        #LIMPA thumbs.db
        gci -Force "$TeamFolder\$team" -Recurse | ?{$_ -match "thumbs.db"} | Remove-Item -Force | Out-Null
        gci -Force "$ProjectsFolder" -Recurse | ?{$_ -match "thumbs.db"} | Remove-Item -Force | Out-Null
        #VER - gci -Force "$TeamFolder\$team" -Recurse | ?{$_ -match "~$*.*"} | Remove-Item -Force

        #LISTA DE ARQUIVOS EXPIRADOS
        New-FsrmStorageReport -Name "Arquivos Expirados - $team" -Namespace @("$TeamFolder\$team") -Interactive -ReportType @("LeastRecentlyAccessed") -LeastAccessedMinimum $Days4ExpirationFile -ReportFormat Csv | Out-Null
        Wait-FsrmStorageReport -Name "Arquivos Expirados - $team" | Out-Null
        $LeastRecentlyAccessed = (gci $FSRMReportFolder | ?{$_ -match "LeastRecentlyAccessed"} | sort LastWriteTime | select -last 1).VersionInfo.FileName

        $KeysArray = @()
        $FullList = @()
        $comecaagravar = $false
        foreach($line in Get-Content $LeastRecentlyAccessed) {
            if($line -eq "File name,Folder,Last accessed,Size on Disk,Size,Owner"){
                $comecaagravar = $true
            }
            if($comecaagravar -eq $true){
                if($line -eq ""){
                    $comecaagravar = $false
                    $FullList += $KeysArray
                    $KeysArray = @()
                }
                else
                {
                    if($line -ne "File name,Folder,Last accessed,Size on Disk,Size,Owner"){
                        $line = $line.replace('","',"|").Trim(" ").Trim(",").trim('"')
                        $values = $line.Split("|") | where {$_ -ne ""}
                        $FileName = $values[0]
                        $FolderName = $values[1]
                        $KeyData = $null
                        $KeyData = New-Object PSObject
                        $KeyData | Add-Member -MemberType NoteProperty -Name "FileName" -Value $FileName
                        $KeyData | Add-Member -MemberType NoteProperty -Name "FolderName" -Value $FolderName
                        $KeysArray += $KeyData
                    }
                }
            }
        }
        $ArchivedList = $FullList
        if ($ArchivedList.Count -gt 1) {
            $mandaEmail = $true
            $CorpoDoEmail += "<h3>- Arquivos <u>Expirados</u> (mais de $YearsLimitForAllFiles anos):</h3>"
            $ArchivedList | ForEach-Object {
                $Source = $_.FolderName
                $FolderDestination = $Source.Replace("$TeamFolder\", "$HomeArchiveFolder\").Replace("$ProjectsFolder\", "$HomeArchiveFolder\Projetos\")
                $File = $_.FileName
                $PathMensagem = $Source.Replace("$TeamFolder\", "$MainDrive").Replace("$MainDrive", "$ServerName")
                If (Test-Path -Path "$Source\$File" -PathType leaf) {
                    Add-Content -Path C:\Temp\LOG_ArquivoMorto.txt -Value (Get-Date) -PassThru | Out-Null
                    robocopy "$Source" "$FolderDestination\." "$File" /mov /R:1 /W:1 /NS /NJH /NJS /NP /UNILOG+:C:\Temp\LOG_ArquivoMorto.txt | Out-Null
                    $CorpoDoEmail += "<li><span style='color:darkred'>Movido</span>: <a href=`"$PathMensagem\$File`">$PathMensagem\$File</a>"
                    $ArquivosMovidos++
                }
            }
        }
        Remove-Item -Path $LeastRecentlyAccessed

        #LISTA DE ARQUIVOS ANTIGOS E GRANDES
        New-FsrmStorageReport -Name "Arquivos Antigos - $team" -Namespace @("$TeamFolder\$team") -Interactive -ReportType @("LargeFiles") -LargeFileMinimum $AgeLimitForLargeFiles -ReportFormat Csv | Out-Null
        Wait-FsrmStorageReport -Name "Arquivos Antigos - $team" | Out-Null
        $MyLargeFilesReport = (gci $FSRMReportFolder | ?{$_ -match "LargeFiles"} | sort LastWriteTime | select -last 1).VersionInfo.FileName

        $KeysArray = @()
        $FullList = @()
        $comecaagravar = $false
        $CurrentDate = Get-Date
        $ThresholdDate = $CurrentDate.AddYears(-$YearsLimitForLargeFiles)
        foreach($line in Get-Content $MyLargeFilesReport) {
            if($line -eq "File name,Folder,Owner,Size on Disk,Size,Last accessed"){
                $comecaagravar = $true
            }
            if($comecaagravar -eq $true){
                if($line -eq ""){
                    $comecaagravar = $false
                    $FullList += $KeysArray
                    $KeysArray = @()
                }
                else
                {
                    if($line -ne "File name,Folder,Owner,Size on Disk,Size,Last accessed"){
                        $line = $line.replace('","',"|").Trim(" ").Trim(",").trim('"')
                        $values = $line.Split("|") | where {$_ -ne ""}
                        $FileName = $values[0]
                        $FolderName = $values[1]
                        $FileSize = $values[4]
                        $ThisFileDate = $values[5]
                        $FileDate = Get-Date "$ThisFileDate"
                        $KeyData = $null
                        $KeyData = New-Object PSObject
                        $KeyData | Add-Member -MemberType NoteProperty -Name "FileName" -Value $FileName
                        $KeyData | Add-Member -MemberType NoteProperty -Name "FolderName" -Value $FolderName
                        $KeyData | Add-Member -MemberType NoteProperty -Name "FileDate" -Value $FileDate
                        $KeyData | Add-Member -MemberType NoteProperty -Name "FileSize" -Value $FileSize
                        $KeysArray += $KeyData
                    }
                }
            }
        }
        $ArchivedList = $FullList | Where-Object { (get-date $_.FileDate) -lt $ThresholdDate }
        if ($ArchivedList.Count -gt 1) {
            $mandaEmail = $true
            $AgeLimitText = (($AgeLimitForLargeFiles)/1024)/1024
            $CorpoDoEmail += "<h3>- Arquivos <u>Expirados</u> (mais de $AgeLimitText MB e mais de $YearsLimitForLargeFiles anos):</h3>"
            $ArchivedList | ForEach-Object {
                $Source = $_.FolderName
                $FolderDestination = $Source.Replace("$TeamFolder\", "$HomeArchiveFolder\").Replace("$ProjectsFolder\", "$HomeArchiveFolder\Projetos\")
                $File = $_.FileName
                $PathMensagem = $Source.Replace("$TeamFolder\", "$MainDrive").Replace("$MainDrive", "$ServerName")
                If (Test-Path -Path "$Source\$File" -PathType leaf) {
                    Add-Content -Path C:\Temp\LOG_ArquivoMorto.txt -Value (Get-Date) -PassThru | Out-Null
                    robocopy "$Source" "$FolderDestination\." "$File" /mov /R:1 /W:1 /NS /NJH /NJS /NP /UNILOG+:C:\Temp\LOG_ArquivoMorto.txt | Out-Null
                    $CorpoDoEmail += "<li><span style='color:darkred'>Movido</span>: <a href=`"$PathMensagem\$File`">$PathMensagem\$File</a>"
                    $ArquivosMovidos++
                }
            }
        }
        Remove-Item -Path $MyLargeFilesReport

        #LISTA DE ARQUIVOS DUPLICADOS NA AREA (APENAS NA AREA)
        New-FsrmStorageReport -Name "Arquivos duplicados - $team" -Namespace @("$TeamFolder\$team") -Interactive -ReportType @("DuplicateFiles") -ReportFormat Csv | Out-Null
        Wait-FsrmStorageReport -Name "Arquivos duplicados - $team" | Out-Null
        $MyDuplicatedFilesReport = (gci $FSRMReportFolder | ?{$_ -match "DuplicateFiles"} | sort LastWriteTime | select -last 1).VersionInfo.FileName
        $CorpoDoEmailSwp = $null
        $comecaagravar = $false
        Get-Content $MyDuplicatedFilesReport | ForEach-Object {
            $linha = $_
            if ($comecaagravar -eq $true){
                if ($linha -eq ""){
                    if ($KeysArray -ne $null) {
                        $KeysArray = $KeysArray | Sort-Object -Property Date -Descending
                        $File = $KeysArray.FileName | Get-Unique
                        $CorpoDoEmailSwp += "<p>"
                        $CorpoDoEmailSwp += "<h3><span style='color:gray'>$File</span></h3>"
                        if ($KeysArray.Count -gt 1) {
                            $mandaEmail = $true
                            $KeysArray | ForEach-Object {
                                $File = $_.FileName
                                $FolderNameFSRM = $_.FolderName
                                $FolderDestination = $FolderNameFSRM.Replace("$TeamFolder\", "$HomeArchiveFolder\").Replace("$ProjectsFolder\", "$HomeArchiveFolder\Projetos\")
                                if ($_ -eq $KeysArray[0]) {
                                    $PathMensagem = $FolderNameFSRM.Replace("$TeamFolder\", "$ServerName").Replace("$MainDrive", "$ServerName")
                                    $CorpoDoEmailSwp += "<li><span style='color:green'>Mantido</span>: <a href=`"$PathMensagem\$File`">$PathMensagem\$File</a>"
                                }
                                else {
                                    If (Test-Path -Path "$FolderNameFSRM\$File" -PathType leaf) {
                                        $PathMensagem = $FolderNameFSRM.Replace("$TeamFolder\", "$ServerName\$SharedArchiveFolder\").Replace("$MainDrive", "$ServerName\$SharedArchiveFolder\")
                                        If (! (Test-Path "$FolderDestination")) {
                                            $FolderSource = "$TeamFolder\"
                                            If ($FolderNameFSRM -like "$ProjectsFolder\*") {$FolderSource = "$ProjectsFolder\"}
                                            $FolderSource = $FolderSource+$FolderNameFSRM.Split("\")[2]
                                            $CreateFolder = $FolderSource.Replace("$TeamFolder\","$HomeArchiveFolder\").Replace("$ProjectsFolder\", "$HomeArchiveFolder\Projetos\")
                                            If (! (Test-Path "$CreateFolder")) {
                                                robocopy "$FolderSource" "$CreateFolder" /copy:S /NS /NJH /NJS /NP /UNILOG+:C:\Temp\LOG_ArquivoMorto.txt | Out-Null
                                                Get-Acl -Path $FolderSource | Set-Acl -Path $CreateFolder
                                            }
                                        }
                                        Add-Content -Path C:\Temp\LOG_ArquivoMorto.txt -Value (Get-Date) -PassThru | Out-Null
                                        robocopy "$FolderNameFSRM" "$FolderDestination\." "$File" /mov /R:1 /W:1 /NS /NJH /NJS /NP /UNILOG+:C:\Temp\LOG_ArquivoMorto.txt | Out-Null
                                        $CorpoDoEmailSwp += "<li><span style='color:darkred'>Movido</span>: <a href=`"$PathMensagem\$File`">$PathMensagem\$File</a>"
                                        $ArquivosMovidos++
                                    }
                                }
                            }
                        }
                    }
                    $KeysArray = @()
                    $comecaagravar = $false
                }
                else{  
                    $teste = $linha 
                    $array=$linha.replace('","','|').trim('",').split("|")
                    if ($array.Count -eq 4){
                        $FileName = $array[0]
                        $FolderName = $array[1]
                        $GetDate = $array[3]
                        $Date = Get-Date $GetDate
                        #Adicionando uma nova linha
                        $KeyData = $null
                        $KeyData = New-Object PSObject
                        $KeyData | Add-Member -MemberType NoteProperty -Name "FileName" -Value $FileName
                        $KeyData | Add-Member -MemberType NoteProperty -Name "FolderName" -Value $FolderName
                        $KeyData | Add-Member -MemberType NoteProperty -Name "Date" -Value $Date
                        $KeysArray += $KeyData
                    }
                }
            }
            if ($linha -eq "File name,Folder,Owner,Last accessed"){
                $comecaagravar = $true
            }
        }
        if ($CorpoDoEmailSwp -ne $null){
            $CorpoDoEmail += "<p><h3>- Arquivos <u>Duplicados dentro de sua área</u>:</h3></p>"
            $CorpoDoEmail += $CorpoDoEmailSwp
        }
        Remove-Item -Path $MyDuplicatedFilesReport

        #LISTA DE ARQUIVOS DUPLICADOS NA AREA E PROJETOS
        New-FsrmStorageReport -Name "$team com Projetos" -Namespace @("$TeamFolder\$team", "$ProjectsFolder") -Interactive -ReportType @("DuplicateFiles") -ReportFormat csv | Out-Null
        Wait-FsrmStorageReport -Name "$team com Projetos" | Out-Null
        $MyDuplicatedFilesReport = (gci $FSRMReportFolder | ?{$_ -match "DuplicateFiles"} | sort LastWriteTime | select -last 1).VersionInfo.FileName
        $KeysArray = @()
        $grava = $false
        $DuplicatedWithProject = $false
        $CorpoDoEmailSwp = $null
        foreach($line in Get-Content $MyDuplicatedFilesReport) {
            if($grava -eq $true){
                if($line -eq ""){
                    $grava = $false
                    if( @($KeysArray | Where-Object Source -Like "$ProjectsFolder\*").count -ge 1 -AND @($KeysArray | Where-Object Source -NotLike "$ProjectsFolder\*").count -ge 1){
                        $DuplicatedWithProject = $true
                        $File = $KeysArray.File | Get-Unique
                        $CorpoDoEmailSwp += "<p>"
                        $CorpoDoEmailSwp += "<h3><span style='color:gray'>$File</span></h3>"
                        $KeysArray | Where-Object Source -Like "$ProjectsFolder\*" | ForEach-Object {
                            $Source = $_.Source
                            $File = $_.File
                            $PathMensagem = $Source.Replace("$TeamFolder\", "$ServerName").Replace("$MainDrive", "$ServerName")
                            $CorpoDoEmailSwp += "<li><span style='color:green'>Mantido</span>: <a href=`"$PathMensagem\$File`">$PathMensagem\$File</a>"
                        }
                        $KeysArray | Where-Object Source -NotLike "$ProjectsFolder\*" | ForEach-Object {
                            $Source = $_.Source
                            $FolderDestination = $Source.Replace("$TeamFolder\", "$HomeArchiveFolder\").Replace("$ProjectsFolder\", "$HomeArchiveFolder\Projetos\")
                            $File = $_.File
                            $PathMensagem = $Source.Replace("$TeamFolder\", "$MainDrive").Replace("$MainDrive", "$ServerName")
                            If (Test-Path -Path "$Source\$File" -PathType leaf) {
                                Add-Content -Path C:\Temp\LOG_ArquivoMorto.txt -Value (Get-Date) -PassThru | Out-Null
                                robocopy "$Source" "$FolderDestination\." "$File" /mov /R:1 /W:1 /NS /NJH /NJS /NP /UNILOG+:C:\Temp\LOG_ArquivoMorto.txt | Out-Null
                                $CorpoDoEmailSwp += "<li><span style='color:darkred'>Movido</span>: <a href=`"$PathMensagem\$File`">$PathMensagem\$File</a>"
                                $ArquivosMovidos++
                            }
                        }
                    }
                    $KeysArray = @()
                }
                else
                {
                    $line = $line.replace('","',"|").Trim(" ").Trim(",").trim('"')
                    $values = $line.Split("|") | where {$_ -ne ""}
                    if($values.count -eq 4){
                       $Source = $values[1]
                       $KeyData = $null
                       $KeyData = New-Object PSObject
                       $KeyData | Add-Member -MemberType NoteProperty -Name "File" -Value $values[0]
                       $KeyData | Add-Member -MemberType NoteProperty -Name "Source" -Value $Source
                       $KeysArray += $KeyData
                    }
                }
            }
            if($line -eq "File name,Folder,Owner,Last accessed"){
                $grava = $true
                $CorpoDoEmailSwp += "<p></p>"
            }
        }
        Remove-Item -Path $MyDuplicatedFilesReport
        if ($DuplicatedWithProject -eq $true){
        #if ($CorpoDoEmailSwp -ne $null){
            $CorpoDoEmail += "<p><h3>- Arquivos <u>Duplicados na sua área e em Projetos</u>:</h3></p>"
            $CorpoDoEmail += $CorpoDoEmailSwp
        }

        $FsrmQuota = Get-FsrmQuota -Path "$TeamFolder\$team"
        If (($FsrmQuota).Size -gt ($FsrmQuota).Template)
        {
            $QuotaSize = [math]::Floor((($FsrmQuota).Usage/90)*100)
            If (($FsrmQuota).Size -gt $QuotaSize){
                If ($QuotaSize -gt ($FsrmQuota).Template) {Set-FsrmQuota -Path "$TeamFolder\$team" -Size $QuotaSize}
                else {Set-FsrmQuota -Path "$TeamFolder\$team" -Size ($FsrmQuota).Template}
            }
        }

        #ENVIO DE E-MAIL
        If ($mandaEmail -eq $true) {
            $sendMailMessageSplat = @{
                From = "$ITEmail"
                To = "$team@$YourDomain"
                CC = "cti@$YourDomain"
                Subject = "Conteudo movido da $team para o Arquivo Morto"
                Body = "Foram movidos $ArquivosMovidos arquivos para o Arquivo Morto. Segue a lista dos arquivos movidos: <p>$CorpoDoEmail</p> "
                SmtpServer = "$SmtpServer"
            }
            Send-MailMessage @sendMailMessageSplat -BodyAsHtml -Encoding 'utf8'
        }
    }