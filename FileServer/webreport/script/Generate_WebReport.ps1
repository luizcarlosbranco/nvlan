#https://docs.microsoft.com/en-us/dotnet/api/system.windows.forms.datavisualization.charting.chart?view=netframework-4.8
#https://social.technet.microsoft.com/Forums/en-US/bc6af53d-b392-49f3-80d0-0b36157c87be/charting-with-powershell?forum=winserverpowershell
#https://www.youtube.com/watch?v=7UNgLDWtyIM
#https://nvlan.com.br/comunidade/criar-uma-variavel-com-colunas-no-powershell/
#http://woshub.com/powershell-get-folder-sizes/#:~:text=You%20can%20use%20the%20Get,(including%20subfolders)%20in%20PowerShell.
#https://docs.microsoft.com/en-us/powershell/module/fileserverresourcemanager/new-fsrmstoragereport?view=windowsserver2022-ps

# FSRM SETTINGS
#Get-FsrmSetting | Select-Object *
#Set-FsrmSetting –ReportLimitMaxFilesPerPropertyValue 1000000 –PassThru
Set-FsrmSetting –ReportLeastAccessedMinimum 730 –PassThru
Set-FsrmSetting –ReportLimitMaxDuplicateGroup 9999 –PassThru
Set-FsrmSetting –ReportLimitMaxFile 99999 –PassThru
Set-FsrmSetting –ReportLimitMaxFilesPerDuplicateGroup 9999 –PassThru

# VARIABLES (EDIT AS YOUR NEEDS)
$URLSite = "fileserver_webreport.yourdomain"
$Targetfolder = "C:\inetpub\$URLSite"
$Folders = "E:\folder1", "E:\folder2"

# SCRIPT
$ErrorActionPreference= 'silentlycontinue'
$history_filename = "script\history.csv"
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
    If (Test-Path -Path "$Folder") {
        $Template_Folders = $Template_Folders.replace("<!-- navbar -->","<li><a href=`"/reports/$Folder_Name/Report.html`">$Folder_Name</a></li>`n<!-- navbar -->")
        $Template_Folders = $Template_Folders.replace("<!-- simplenav -->","<a href=`"/reports/$Folder_Name/Report.html`">$Folder_Name</a> |`n<!-- simplenav -->")
        $Template_DefaultSite = $Template_DefaultSite.replace("<!-- navbar -->","<li><a href=`"/reports/$Folder_Name/Report.html`">$Folder_Name</a></li>`n<!-- navbar -->")
        $Template_DefaultSite = $Template_DefaultSite.replace("<!-- simplenav -->","<a href=`"/reports/$Folder_Name/Report.html`">$Folder_Name</a> |`n<!-- simplenav -->")
    }
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
    $Folder = $_
    $Folder_Name = $Folder.Split("\")[-1]
        If (!$Folder_Name){
        $Folder_Name = $Folder.Split("\")[0].Replace(":","")
    }
    If (Test-Path -Path "$Folder") {
        $Data = Get-Date -Format "dd/MM/yyyy"
        $FolderPage = $FolderPage.replace("<!-- Title -->","<title>$Folder_Name - Consumo</title>")
        $FolderPage = $FolderPage.replace("<!-- TOP5Image -->","<p><img src=`"ranking.png`" alt=`"`" class=`"img-rounded pull-right`" width=`"800`" ></p>")
        $FolderPage = $FolderPage.replace("<!-- HTMLCode_Table -->","<table>`n<tr>`n<th>Setor</th>`n<th>Capacidade</th>`n<th>Qtd_Utilizado</th>`n<th>Duplicados</th>`n<th>Grandes</th>`n<th>Antigos</th>`n</tr>`n<!-- HTMLCode_Table -->`n</table>")
        Write-host "Creating $Targetfolder\reports\$Folder_Name"
        New-Item -ItemType Directory -Force -Path "$Targetfolder\reports\$Folder_Name" | Out-Null

        Get-ChildItem $Folder -Directory | ForEach-Object {
            $Name = $_.Name
            $FsrmQuota = Get-FsrmQuota
#Vamos filtrar para gerar relatório APENAS das pastas que possuem conta no FSRM
            If ($FsrmQuota | Where-Object {$_.Path -eq "$Folder\$Name"}) {
                Write-Host "$Folder_Name\$Name : " -NoNewline
#Vamos gerar relatórios do FSRM
                New-FsrmStorageReport -Name "$Folder_Name - $Name" -Namespace @("$Folder\$Name") -Interactive -ReportType @("DuplicateFiles", "LargeFiles", "LeastRecentlyAccessed") -ReportFormat DHtml | Out-Null
                Wait-FsrmStorageReport -Name "$Folder_Name - $Name" | Out-Null
#Com os dados do FSRM, vamos obter os valores que desejamos usar em nosso ARRAY
                $Usage_FSRM = [Math]::Round( ($FsrmQuota | Where-Object {$_.Path -eq "$Folder\$Name"}).Usage/ 1GB) 
                $QuotaGB_FSRM = [Math]::Round( ($FsrmQuota | Where-Object {$_.Path -eq "$Folder\$Name"}).Size/1GB) 
                $UsagePercentage_FSRM = [Math]::Round( (($FsrmQuota | Where-Object {$_.Path -eq "$Folder\$Name"}).Usage * 100/($FsrmQuota | Where-Object {$_.Path -eq "$Folder\$Name"}).Size) )
#Vamos mover os relatóios do FSRM (em HTML) para nosso site
                $ReportTypes | ForEach-Object {
                   $ReportType = $_
                   Move-Item -Path "C:\StorageReports\Interactive\$ReportType`*.html" -Destination "$Targetfolder\reports\$Folder_Name\$Name`_$ReportType.html"
                }
                If (Test-Path -Path "C:\StorageReports\Interactive\*") { Move-Item -Path "C:\StorageReports\Interactive\*" -Destination "$Targetfolder\reports\$Folder_Name" }
                Write-Host " Moved to: $Targetfolder\reports\$Folder_Name"
#Vamos criar nosso ARRAY
                $dataObject = $null
                $dataObject = New-Object PSObject
                Add-Member -inputObject $dataObject -memberType NoteProperty -name "Folder" -value $Folder
                Add-Member -inputObject $dataObject -memberType NoteProperty -name "Name" -value $Name
                $ReportTypes | ForEach-Object {
                    $ReportType = $_
                    $Report_Value = 0
                    If (Test-Path -Path "$Targetfolder\reports\$Folder_Name\$Name`_$ReportType.html") {
                        $Report_Value = Get-Content -path "$Targetfolder\reports\$Folder_Name\$Name`_$ReportType.html" | Select-String -Pattern "BORDER-BOTTOM-COLOR: #c0c0c0; BORDER-BOTTOM-STYLE: solid;*" | Select-Object -First 3 | Select-Object -Last 1
                        $Report_Value = $Report_Value.ToString()
                        $Report_Value = $Report_Value.Replace("<",">")
                        $Report_Value = $Report_Value.Split(">")[2]
                        $Report_Value = $Report_Value.Split(",")[0]
                        $Report_Value = $Report_Value -replace "[^0-9]" , ''
                        $Report_Value = [Math]::Round( ($Report_Value / 1024) )
                        Add-Member -inputObject $dataObject -memberType NoteProperty -name $ReportType -value $Report_Value
                        If ($ReportType -eq "DuplicateFiles") {$DuplicateFiles_FSRM = $Report_Value}
                    }
                }
            }
            $Size_FSRM = [Math]::Round( ($Usage_FSRM - $DuplicateFiles_FSRM) )
            Add-Member -inputObject $dataObject -memberType NoteProperty -name "Usage" -value $Usage_FSRM
            Add-Member -inputObject $dataObject -memberType NoteProperty -name "Size" -value $Size_FSRM
            Add-Member -inputObject $dataObject -memberType NoteProperty -name "QuotaGB" -value $QuotaGB_FSRM
            Add-Member -inputObject $dataObject -memberType NoteProperty -name "UsagePercentage" -value $UsagePercentage_FSRM
# Vamos adicionar uma linha na tabela do site, com a pasta e seus dados
            $FolderPage = $FolderPage.replace("<!-- HTMLCode_Table -->","<tr>`n<td>$($dataObject.Name)</td>`n<td>$($dataObject.QuotaGB) GB</td>`n<td>$($dataObject.Usage) GB ($($dataObject.UsagePercentage)%)</td>`n<td><a href=/reports/$Folder_Name/$Name`_DuplicateFiles.html>$($dataObject.DuplicateFiles) GB</a></td>`n<td><a href=/reports/$Folder_Name/$Name`_LargeFiles.html>$($dataObject.LargeFiles) GB</a></td>`n<td><a href=/reports/$Folder_Name/$Name`_LeastRecentlyAccessed.html>$($dataObject.LeastRecentlyAccessed) GB</a></td>`n</tr>`n<!-- HTMLCode_Table -->")
# Vamos adicionar a pasta ao ARRAY
            $sectors += $dataObject
            If (!(Test-Path -Path "$Targetfolder\$history_filename"))
            {
                "Data;Folder;Name;Usage" >> "$Targetfolder\$history_filename"
            }
        }
#Vamos esportar o histórico da pasta (para consultar o histórico do volume)
        "$Data;$Folder;$Name;$Size" >> "$Targetfolder\$history_filename"

#Organizar os TOP5 do ARRAY, com maior consumo de dados
        $topsectors = $sectors | Where-Object { $_.Folder -eq $Folder } | Sort-Object Usage -Descending | Select-Object -first 5

#Vamos criar gráfico de consumo
        Add-type -AssemblyName System.Windows.Forms.DataVisualization
        $Chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
        $Chart.Width = 1000
        $Chart.Height = 600
        $Chart.font = "100"
																					 
        $legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
        $Chart.Legends.Add($legend)
        $Chart.Legends[0].Title = "Legend"
        $Chart.Legends[0].Docking = "Right"

        $ChartTitle = New-Object System.Windows.Forms.DataVisualization.Charting.Title
        $Chart.Titles.Add($ChartTitle)
        $Chart.Titles[0].Font = 'ArialBold, 18pt'
        $Chart.Titles[0].Text = "TOP5 - $Folder_Name em $Data (em GB)"

        $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
        $Chart.ChartAreas.Add($ChartArea)
        $ChartArea.BackColor = "White"
        $ChartArea.AxisX.MajorGrid.Interval = 100
        $ChartArea.Axisy.MajorGrid.Interval = 100
        $ChartArea.AxisY.MajorGrid.LineColor = "LightGray"
        $ChartArea.AxisX.MajorGrid.LineColor = "LightGray"
        $ChartArea.AxisX.MajorGrid.Enabled = $False

        $Chart.Series.Add("Unique") | Out-Null
        $Chart.Series["Unique"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::StackedColumn
        $Chart.Series["Unique"].YValueType = [System.Windows.Forms.DataVisualization.Charting.ChartValueType]::Double 
        $Chart.Series["Unique"].Points.DataBindXY($topsectors.Name,$topsectors.Size)
        $Chart.Series["Unique"].IsValueShownAsLabel = $true

        $Chart.Series.Add("Duplicated") | Out-Null
        $Chart.Series["Duplicated"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::StackedColumn
        $Chart.Series["Duplicated"].YValueType = [System.Windows.Forms.DataVisualization.Charting.ChartValueType]::Double
        $Chart.Series["Duplicated"].Points.DataBindXY($topsectors.Name,$topsectors.DuplicateFiles)
        $Chart.Series["Duplicated"].color = "#EE0000"
        $Chart.Series["Duplicated"].IsValueShownAsLabel = $true

        $chart.BackColor = [System.Drawing.Color]::Transparent
#Vamos salvar uma imagem com o gráfico
        $Chart.SaveImage("$Targetfolder\reports\$Folder_Name\ranking.png",'PNG')

#OPCIONAL - Abrir o gráfico gerado
#        $Form = New-Object System.Windows.Forms.Form
#        $Form.Width = 1500
#        $Form.Height = 1200
#        $Form.Controls.Add($chart)
#        $Form.ShowDialog()

#Vamos alterar e salvar o HTML
        $FolderPage = $FolderPage.replace("<li><a href=`"/reports/$Folder_Name/Report.html`">$Folder_Name</a></li>","<li class=`"active`"><a href=`"/reports/$Folder_Name/Report.html`">$Folder_Name</a></li>")
        $FolderPage | Out-File -Encoding utf8 -FilePath "$Targetfolder\reports\$Folder_Name\Report.html" -Force
    }
}
$Template_DefaultSite | Out-File -Encoding utf8 -FilePath "$Targetfolder\index.html" -Force
