#https://docs.microsoft.com/en-us/dotnet/api/system.windows.forms.datavisualization.charting.chart?view=netframework-4.8
#https://social.technet.microsoft.com/Forums/en-US/bc6af53d-b392-49f3-80d0-0b36157c87be/charting-with-powershell?forum=winserverpowershell
#https://www.youtube.com/watch?v=7UNgLDWtyIM
#https://nvlan.com.br/comunidade/criar-uma-variavel-com-colunas-no-powershell/
#http://woshub.com/powershell-get-folder-sizes/#:~:text=You%20can%20use%20the%20Get,(including%20subfolders)%20in%20PowerShell.
#https://docs.microsoft.com/en-us/powershell/module/fileserverresourcemanager/new-fsrmstoragereport?view=windowsserver2022-ps

$ErrorActionPreference= 'silentlycontinue'
$inicio = get-date
$URLSite = "servidordearquivos.cnt.org.br"
$Targetfolder = "C:\inetpub\$URLSite"
$history_filename = "script\history.csv"
#$Companies = "CNT", "ITL"
$Folders = "E:\deptos_CNT", "E:\deptos_ITL"
$ReportTypes = "DuplicateFiles", "LargeFiles", "LeastRecentlyAccessed"
$Template_Folders = Get-Content "$Targetfolder\script\Template_Folders.html"
$Template_DefaultSite = Get-Content "$Targetfolder\script\Template_DefaultSite.html"
$Template_DefaultSite = $Template_DefaultSite.replace("<a href=`"#`">Home</a>","<a href=`"https://$URLSite`">Home</a>")
$Template_Folders = $Template_Folders.replace("<a href=`"#`">Home</a>","<a href=`"https://$URLSite`">Home</a>")
$sectors = @()

$Folders | ForEach-Object {
    $Folder = $_
    $Folder_Name = $Folder.Split("\")[-1]
        If (!$Folder_Name){
        $Folder_Name = $Folder.Split("\")[0].Replace(":","")
    }
    $Template_Folders = $Template_Folders.replace("<!-- navbar -->","<li><a href=`"/reports/$Folder_Name/Report.html`">$Folder_Name</a></li>`n<!-- navbar -->")
    $Template_Folders = $Template_Folders.replace("<!-- simplenav -->","<a href=`"/reports/$Folder_Name/Report.html`">$Folder_Name</a> |`n<!-- simplenav -->")
    $Template_DefaultSite = $Template_DefaultSite.replace("<!-- navbar -->","<li><a href=`"/reports/$Folder_Name/Report.html`">$Folder_Name</a></li>`n<!-- navbar -->")
    $Template_DefaultSite = $Template_DefaultSite.replace("<!-- simplenav -->","<a href=`"/reports/$Folder_Name/Report.html`">$Folder_Name</a> |`n<!-- simplenav -->")
}
while(get-FsrmStorageReport) {
    Write-Host "|" -NoNewline
    Start-Sleep -s 15
}
If (Test-Path -Path "$Targetfolder\reports\*") { Remove-Item -Force -Path "$Targetfolder\reports\*" -Recurse -Confirm:$false | Out-Null }
If (Test-Path -Path "C:\StorageReports\Interactive\*") { Remove-Item -Force -Path "C:\StorageReports\Interactive\*" -Recurse -Confirm:$false | Out-Null }
Write-Host ""
Start-Sleep -s 5
$Folders | ForEach-Object {
    $FolderPage = $Template_Folders
    $top_qtd = "5"
    $Folder = $_
    $Folder_Name = $Folder.Split("\")[-1]
        If (!$Folder_Name){
        $Folder_Name = $Folder.Split("\")[0].Replace(":","")
    }
    $Data = Get-Date -Format "dd/MM/yyyy"
    $FolderPage = $FolderPage.replace("<!-- Title -->","<title>$Folder_Name - Consumo</title>")
    $FolderPage = $FolderPage.replace("<!-- TOP5Image -->","<p><img src=`"ranking.png`" alt=`"`" class=`"img-rounded pull-right`" width=`"800`" ></p>")
    $FolderPage = $FolderPage.replace("<!-- HTMLCode_Table -->","<table>`n<tr>`n<th>Setor</th>`n<th>Consumo</th>`n<th>Duplicados</th>`n<th>Grandes</th>`n<th>Antigos</th>`n</tr>`n<!-- HTMLCode_Table -->`n</table>")
    Write-host "Creating $Targetfolder\reports\$Folder_Name"
    New-Item -ItemType Directory -Force -Path "$Targetfolder\reports\$Folder_Name" | Out-Null
    Add-type -AssemblyName System.Windows.Forms
    Add-type -AssemblyName System.Windows.Forms.DataVisualization
    $chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
    $chart.Size = '1000,600'
    $ChartTitle = New-Object System.Windows.Forms.DataVisualization.Charting.Title
    $chart.Titles.Add($ChartTitle)
    $chart.Titles[0].Font = 'ArialBold, 18pt'
    $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
    $chart.ChartAreas.Add($ChartArea)
    $top_qtd = 0

    Get-ChildItem $Folder -Directory | ForEach-Object {
        $Name = $_.Name
        $top_qtd++
        Write-Host "$Folder_Name\$Name : " -NoNewline
        #
        #$Size = $top_qtd
        New-FsrmStorageReport -Name "$Folder_Name - $Name" -Namespace @("E:\$Folder_Name\$Name") -Interactive -ReportType @("DuplicateFiles", "LargeFiles", "LeastRecentlyAccessed") -ReportFormat DHtml | Out-Null
        $Size = [Math]::Round( ((Get-ChildItem $Folder\$Name -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB) )
        #
        $FolderPage = $FolderPage.replace("<!-- HTMLCode_Table -->","<tr>`n<td>$Name</td>`n<td>$Size GB</td>`n<td><a href=/reports/$Folder_Name/$Name`_DuplicateFiles.html><img src=`"/assets/images/Files_Duplicated.png`"></a></td>`n<td><a href=/reports/$Folder_Name/$Name`_LargeFiles.html><img src=`"/assets/images/Files_Big.png`"></a></td>`n<td><a href=/reports/$Folder_Name/$Name`_LeastRecentlyAccessed.html><img src=`"/assets/images/Files_Old.png`"></a></td>`n</tr>`n<!-- HTMLCode_Table -->")
        $dataObject = $null
        $dataObject = New-Object PSObject
        Add-Member -inputObject $dataObject -memberType NoteProperty -name "Data" -value $Data
        Add-Member -inputObject $dataObject -memberType NoteProperty -name "Folder" -value $Folder
        Add-Member -inputObject $dataObject -memberType NoteProperty -name "Name" -value $Name
        Add-Member -inputObject $dataObject -memberType NoteProperty -name "SizeGb" -value $Size
        $sectors += $dataObject
        while(get-FsrmStorageReport) {
            Write-Host "." -NoNewline
            Start-Sleep -s 15
        }
        "DuplicateFiles", "LargeFiles", "LeastRecentlyAccessed" | ForEach-Object {
           $ReportType = $_
           Move-Item -Path "C:\StorageReports\Interactive\$ReportType`*.html" -Destination "$Targetfolder\reports\$Folder_Name\$Name`_$ReportType.html"
        }
        If (Test-Path -Path "C:\StorageReports\Interactive\*") { Move-Item -Path "C:\StorageReports\Interactive\*" -Destination "$Targetfolder\reports\$Folder_Name" }
        Write-Host " Moved to: $Targetfolder\reports\$Folder_Name"
        If (!(Test-Path -Path "$Targetfolder\$history_filename"))
        {
            "Data;Folder;Name;Size" >> "$Targetfolder\$history_filename"
        }
    }

    "$Data;$Folder;$Name;$Size" >> "$Targetfolder\$history_filename"
    If ($top_qtd -gt 5) {
        $chart.Titles[0].Text = "TOP5 - $Folder_Name em $Data (em GB)"
        $topsectors = $sectors | Where-Object { $_.Folder -eq $Folder } | Sort-Object SizeGb -Descending | Select-Object -first 5
    }
    Else {
        $chart.Titles[0].Text = "$Folder_Name em $Data (em GB)"
        $topsectors = $sectors | Where-Object { $_.Folder -eq $Folder } | Sort-Object SizeGb -Descending
    }
    $chart.Series.Add("Data") | Out-Null
    $chart.BackColor = [System.Drawing.Color]::Transparent
    $chart.Series["Data"].Points.DataBindXY($topsectors.Name,$topsectors.SizeGb)
    $chart.ChartAreas.AxisX.MajorGrid.Enabled = $False
    $chart.SaveImage("$Targetfolder\reports\$Folder_Name\ranking.png",'PNG')
    $FolderPage = $FolderPage.replace("<li><a href=`"/reports/$Folder_Name/Report.html`">$Folder_Name</a></li>","<li class=`"active`"><a href=`"/reports/$Folder_Name/Report.html`">$Folder_Name</a></li>")
    $FolderPage | Out-File -Encoding utf8 -FilePath "$Targetfolder\reports\$Folder_Name\Report.html" -Force
}
$Template_DefaultSite | Out-File -Encoding utf8 -FilePath "$Targetfolder\index.html" -Force
$inicio
get-date

#$Template_DefaultSite | Out-File -Encoding unicode -FilePath "$Targetfolder\index-unicode.html" -Force
#$Template_DefaultSite | Out-File -Encoding utf8 -FilePath "$Targetfolder\index-utf8.html" -Force