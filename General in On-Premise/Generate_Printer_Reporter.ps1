#https://stackoverflow.com/questions/33707193/how-to-convert-string-to-integer-in-powershell
#https://stackoverflow.com/questions/17548523/the-term-get-aduser-is-not-recognized-as-the-name-of-a-cmdlet
#https://bytecookie.wordpress.com/category/winforms/
#3D - https://docs.microsoft.com/pt-br/dotnet/api/system.windows.forms.datavisualization.charting.chartarea.area3dstyle?view=netframework-4.8#system-windows-forms-datavisualization-charting-chartarea-area3dstyle
#StackedColumn - https://stackoverflow.com/questions/6131991/microsoft-chart-stacked-column-chart-has-gaps
#Add Label to each graphic - https://social.msdn.microsoft.com/Forums/vstudio/en-US/ce236753-1bc3-4dce-8753-f8509c2a2082/fixed-percentage-labels-on-axis-bar-chart?forum=MSWinWebChart
#show all Xlegends - https://stackoverflow.com/questions/61515760/how-to-display-start-and-end-points-x-axis-label-in-a-chart-in-c-sharp-windows-f
#dicas https://social.msdn.microsoft.com/Forums/vstudio/en-US/ce236753-1bc3-4dce-8753-f8509c2a2082/fixed-percentage-labels-on-axis-bar-chart?forum=MSWinWebChart
#https://stackoverflow.com/questions/53695686/chart-point-labels-wont-work-with-2-charts-created-instead-of-1
#https://communities.vmware.com/t5/VMware-PowerCLI-Discussions/Unable-to-add-used-inside-the-doughnut-chart/td-p/510798

#Se não tiver os módulos de AD:
#Import-Module ServerManager
#Add-WindowsFeature RSAT-AD-PowerShell
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------
#    NAO ALTERE ESSES
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------
#$Checked_Date = [int](get-date -Format "yyyyMMdd")
#$ThisDay = (get-date -Format "dd")

#$Printer_Name = "DIEX_14A"

$DestinationFolder = "C:\inetpub\wwwroot\impressao.cnt.org.br"
$PaperCutLogFolder = "C:\Program Files (x86)\PaperCut Print Logger\logs\csv\monthly\$PaperCutFile"
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------
#    LOADING GRAPH LIBRARIES
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------
Add-type -AssemblyName System.Windows.Forms
Add-type -AssemblyName System.Windows.Forms.DataVisualization
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------
#    FUNCTIONS
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------
Function CalculateTotalsOfAnList{
    param(
     [PSObject]$List,
     [string]$Unique
    )
    Write-Host "Initializing CalculateTotalsOfAnList"
    $List_CalculateTotalsOfAnList = New-Object PSObject
    $List_CalculateTotalsOfAnList = @()
    $List | select $Unique -Unique | ForEach-Object {
        $UniqueValue = $_.$Unique
        $dataObject = $null
        $dataObject = New-Object PSObject
        Add-Member -inputObject $dataObject -memberType NoteProperty -name $Unique -value $UniqueValue
        $List | Select-Object -Property * -ExcludeProperty $Unique | Get-Member | Where-Object MemberType -eq "NoteProperty" | ForEach-Object {
            $CalculateTotalsOfAnList_Name = $_.Name
            Add-Member -inputObject $dataObject -memberType NoteProperty -name $CalculateTotalsOfAnList_Name -value ($List | Where-Object $Unique -eq $UniqueValue | Measure-Object $CalculateTotalsOfAnList_Name -Sum).Sum
        }
        $List_CalculateTotalsOfAnList += $dataObject
    }
    Write-Host "CalculateTotalsOfAnList Finished"
    return $List_CalculateTotalsOfAnList
}

Function ConvertFromPaperCutLog{
    param(
        [String]$PaperCutLogFile,
        [String]$PrinterName
    )
    Write-Host "Initializing ConvertFromPaperCutLog"
    If (Test-Path -Path $PaperCutLogFile){
        $List_ConvertFromPaperCutLog = Get-Content "$PaperCutLogFile" | select -Skip 1 | ConvertFrom-Csv | Where-Object { $_.Printer -like "$PrinterName*" } | select User,Pages,Copies,"Paper Size",Duplex,Grayscale
        $List_ConvertFromPaperCutLog | Add-Member -MemberType NoteProperty -Name "PrintedInColor" -Value "0"
        $List_ConvertFromPaperCutLog | Add-Member -MemberType NoteProperty -Name "PrintedInBW" -Value "1"
        $List_ConvertFromPaperCutLog | Add-Member -MemberType NoteProperty -Name "CountedPages" -Value "1"
        $List_ConvertFromPaperCutLog | ForEach-Object {
            $_.CountedPages = [Math]::Round([int]$_.Pages*[int]$_.Copies)
            If ($_."Paper Size" -eq "A3") { $_.CountedPages = [Math]::Round($_.CountedPages*2) }
            #If ($_.Duplex -ne "NOT DUPLEX") { $_.CountedPages = [Math]::Round($_.CountedPages*2) }
            If ($_.Grayscale -eq "NOT GRAYSCALE")
            {
                $_.PrintedInBW = "0"
                $_.PrintedInColor = "1"
            }
            $_.PrintedInBW = [Math]::Round([int]$_.PrintedInBW*[int]$_.CountedPages)
            $_.PrintedInColor = [Math]::Round([int]$_.PrintedInColor*[int]$_.CountedPages)
        }
        $List_ConvertFromPaperCutLog = $List_ConvertFromPaperCutLog | Select-Object -Property * -ExcludeProperty Grayscale,Pages,Copies,"Paper Size",CountedPages,Duplex
        Write-Host "ConvertFromPaperCutLog Finished"
        Return $List_ConvertFromPaperCutLog
    }
    Else {
        Write-Host "$PaperCutLogFile not found !"
        break
    }
}

Function ConvertFromListLDAPUsertoSector {
    param(
        [PSObject]$List,
        [String]$UserColumnName
    )
    Write-Host "Initializing ConvertFromListLDAPUsertoDepartment"
    If ($List){
        $List_ConvertFromListLDAPUsertoSector = $List
        $List_ConvertFromListLDAPUsertoSector | ForEach-Object {
            If ($_.$UserColumnName)
            {
                #$distinguishedname = (Get-ADUser daniellequeiroz).distinguishedname
                $distinguishedname = (Get-ADUser $_.$UserColumnName).distinguishedname
                [regex]$domain = ",DC="
                $distinguishedname = $domain.replace($distinguishedname, ";|", 1)
                $distinguishedname = $distinguishedname.Split(';|')[0]
                $distinguishedname = $distinguishedname.replace($distinguishedname.Split(',')[0]+',','')
                $distinguishedname = $distinguishedname.replace(','+$distinguishedname.Split(',')[-1],'')
                $distinguishedname = $distinguishedname.Replace('CN=','').Replace('OU=','').Replace('.','').Split(',')
                [array]::Reverse($distinguishedname)
                $distinguishedname = $distinguishedname | select -Unique
                $Department = $distinguishedname -join "_"
                #$Department = $Department.Replace('DIEX_DIEX','DIEX')
                #$Department = $Department.Replace('DIRI_DINST','DIRI')
                #$Department = $Department.Replace('CONT_CONT','CONT')
                If ($Department)
                {
                    $_.$UserColumnName = $Department
                }
            }
        }
        Write-Host "ConvertFromPaperCutLog Finished"
        Return $List_ConvertFromListLDAPUsertoSector
    }
    Else {
        Write-Host "$List not found !"
        break
    }
}

Function CreateGraph{
# https://www.powershellgallery.com/packages/PScriboCharts/0.9.0/Content/PScriboCharts.psm1
# Area, Bar, BoxPlot, Bubble, Candlestick, Column, Doughnut, ErrorBar, FastLine, FastPoint, Funnel, Kagi, Line, Pie, Point, PointAndFigure, Polar, Pyramid, Radar, Range, RangeBar, RangeColumn, Renko, Spline, SplineArea, SplineRange, StackedArea, StackedArea100, StackedBar, StackedBar100, StackedColumn, StepLine, Stock, ThreeLineBreak
    param(
        [PSObject]$List,
        [String]$SaveAs,
        [int]$Width,
        [int]$Height,
        [String]$ChartType,
        [switch]$With3D,
        [String]$WithLegendOn,
        [String]$MainTitle,
        [String]$TitleAxisX,
        [String]$TitleAxisy,
        [String]$Series1Name,
        [String]$Series1Color,
        [String]$Series1AxisXSource,
        [String]$Series1AxisYSource,
        [String]$Series2Name,
        [String]$Series2Color,
        [String]$Series2AxisXSource,
        [String]$Series2AxisYSource
    )
    If ($ChartType -eq ""){$ChartType = "Column"}
    $Chart_PrinterHistory = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
    $Chart_PrinterHistory.Width = $Width
    $Chart_PrinterHistory.Height = $Height
    $Chart_PrinterHistory.Location = '0,500'
    If ($WithLegendOn -ne "")
    {
        $legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
        $Chart_PrinterHistory.Legends.Add($legend)
        $Chart_PrinterHistory.Legends[0].Title = "Legend"
        $Chart_PrinterHistory.Legends[0].Docking = $WithLegendOn
    }
    $ChartTitle_PrinterHistory = New-Object System.Windows.Forms.DataVisualization.Charting.Title
    $Chart_PrinterHistory.Titles.Add($ChartTitle_PrinterHistory)
    $Chart_PrinterHistory.Titles[0].Font = 'ArialBold, 18pt'
    $Chart_PrinterHistory.Titles[0].Text = $MainTitle
    $Chart_PrinterHistoryArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
    $Chart_PrinterHistoryArea.Area3DStyle.Enable3D = $With3D.ToBool()
    $Chart_PrinterHistoryArea.Area3DStyle.Inclination = 50
    $Chart_PrinterHistoryArea.Area3DStyle.PointDepth = 50
    $Chart_PrinterHistoryArea.Area3DStyle.Rotation = 5

    $Chart_PrinterHistory.ChartAreas.Add($Chart_PrinterHistoryArea)
    $Chart_PrinterHistoryArea.AxisX.Title = $TitleAxisX
    $Chart_PrinterHistoryArea.AxisY.Title = $TitleAxisy
    $Chart_PrinterHistoryArea.AxisX.MajorGrid.Enabled = $False
    $Chart_PrinterHistory.font = "100"
    $Chart_PrinterHistory.Series.Add($Series1Name)
    $Chart_PrinterHistory.Series.Add($Series2Name)
    $Chart_PrinterHistory.Series[$Series1Name].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::$ChartType
    $Chart_PrinterHistory.Series[$Series2Name].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::$ChartType

    If ( ($ChartType = "Funnel") -and ($With3D) )
    {
        $Chart_PrinterHistory.Series[$Series2Name].CustomProperties = "Funnel3DDrawingStyle=CircularBase"
        $Chart_PrinterHistory.Series[$Series2Name].CustomProperties = "FunnelPointGap=20"
        $Chart_PrinterHistory.Series[$Series2Name].CustomProperties = "Funnel3DRotationAngle=10"
        $Chart_PrinterHistory.Series[$Series2Name].CustomProperties = "FunnelStyle=YIsHeight"
        $Chart_PrinterHistory.Series[$Series2Name].CustomProperties = "FunnelLabelStyle=Outside"
    }

    $Chart_PrinterHistory.Series[$Series1Name].YValueType = [System.Windows.Forms.DataVisualization.Charting.ChartValueType]::Double 
    $Chart_PrinterHistory.Series[$Series2Name].YValueType = [System.Windows.Forms.DataVisualization.Charting.ChartValueType]::Double
    $Chart_PrinterHistory.Series[$Series1Name].Points.DataBindXY($List.$Series1AxisXSource,$List.$Series1AxisYSource)
    $Chart_PrinterHistory.Series[$Series2Name].Points.DataBindXY($List.$Series2AxisXSource,$List.$Series2AxisYSource)
    $Chart_PrinterHistory.Series[$Series1Name].color = $Series1Color
    $Chart_PrinterHistory.Series[$Series2Name].color = $Series2Color
    $Chart_PrinterHistory.Series[$Series1Name].IsValueShownAsLabel = $true
    $Chart_PrinterHistory.Series[$Series2Name].IsValueShownAsLabel = $true
    $Chart_PrinterHistoryArea.AxisX.LabelStyle.Enabled = $true
    $Chart_PrinterHistoryArea.AxisX.LabelStyle.Angle = 0
    $Chart_PrinterHistoryArea.AxisX.IsLabelAutoFit = $true
    $Chart_PrinterHistoryArea.AxisX.Interval = 1
    $Chart_PrinterHistoryArea.AxisX.LabelAutoFitStyle = "WordWrap"
    $Chart_PrinterHistory.SaveImage("$SaveAs",'PNG')
}

Function CreateSNMPList{
    param(
        [String]$Printer_Name,
        [Bool]$FirstMonthCheck
    )
    $PrintList | Where-Object Name -eq $Printer_Name | ForEach-Object {
        $SNMP_Counter_copied_BW = GetSNMPValue -IP_Address $_.IP_Address -SNMP_Community $_.SNMP_Community -SNMP_Version $_.SNMP_Version -SNMP_OID $_.SNMP_Counter_copied_BW
        $SNMP_Counter_printed_BW = GetSNMPValue -IP_Address $_.IP_Address -SNMP_Community $_.SNMP_Community -SNMP_Version $_.SNMP_Version -SNMP_OID $_.SNMP_Counter_printed_BW
        $SNMP_Counter_copied_color = GetSNMPValue -IP_Address $_.IP_Address -SNMP_Community $_.SNMP_Community -SNMP_Version $_.SNMP_Version -SNMP_OID $_.SNMP_Counter_copied_color
        $SNMP_Counter_printed_color = GetSNMPValue -IP_Address $_.IP_Address -SNMP_Community $_.SNMP_Community -SNMP_Version $_.SNMP_Version -SNMP_OID $_.SNMP_Counter_printed_color
        $SNMP_TotalBWPrinted = $SNMP_Counter_copied_BW+$SNMP_Counter_printed_BW
        $SNMP_TotalColorPrinted = $SNMP_Counter_copied_color+$SNMP_Counter_printed_color
        $SNMPList = $null
        $SNMPList = New-Object PSObject
        Add-Member -inputObject $SNMPList -memberType NoteProperty -name "FirstMonthCheck" -value $FirstMonthCheck
        Add-Member -inputObject $SNMPList -memberType NoteProperty -name "Checked_Date" -value $(get-date -Format "yyyyMMdd")
        Add-Member -inputObject $SNMPList -memberType NoteProperty -name "Printer_Name" -value $Printer_Name
        Add-Member -inputObject $SNMPList -memberType NoteProperty -name "Counter_copied_BW" -value $SNMP_Counter_copied_BW
        Add-Member -inputObject $SNMPList -memberType NoteProperty -name "Counter_printed_BW" -value $SNMP_Counter_printed_BW
        Add-Member -inputObject $SNMPList -memberType NoteProperty -name "Counter_copied_color" -value $SNMP_Counter_copied_color
        Add-Member -inputObject $SNMPList -memberType NoteProperty -name "Counter_printed_color" -value $SNMP_Counter_printed_color
        Add-Member -inputObject $SNMPList -memberType NoteProperty -name "TotalBWPrinted" -value $($SNMP_Counter_copied_BW+$SNMP_Counter_printed_BW)
        Add-Member -inputObject $SNMPList -memberType NoteProperty -name "TotalColorPrinted" -value $($SNMP_Counter_copied_color+$SNMP_Counter_printed_color)

    }
    Return $SNMPList
} 

Function GetSNMPValue{
    param(
        [String]$IP_Address,
        [String]$SNMP_Community,
        [int]$SNMP_Version,
        [String]$SNMP_OID
    )
    Write-Host "Initializing GetSNMPValue"
    $SNMPValue = $null
    If ($SNMP_OID) {
        $SNMP = New-Object -ComObject olePrn.OleSNMP
        $SNMP.open($IP_Address,$SNMP_Community,$SNMP_Version,1000)
        $SNMPValue = $SNMP.get("."+$SNMP_OID)
        $SNMP.Close()
    }
    Write-Host "GetSNMPValue Finished"
    return $SNMPValue
}

Function GetPrinterCost{
    param(
        [String]$Printer_Rent_Value,
        [String]$Printer_Rent_Quota,
        [String]$Printer_Color_Page_Cost,
        [String]$PrinterBW_Page_Cost,
        [String]$TotalPrintedInColor,
        [String]$TotalPrintedInBW
    )
    Write-Host "Initializing GetPrinterCost"
    $PrinterCost = 0
    $Printer_Rent_Quota = $Printer_Rent_Quota - $TotalPrintedInColor
    If ($Printer_Rent_Quota -ge 0 )
    {
        $Printer_Rent_Quota = $Printer_Rent_Quota - $TotalPrintedInBW
        $TotalPrintedInColor = 0
            If ($Printer_Rent_Quota -ge 0 )
            {
                $TotalPrintedInBW = 0
            }
            Else
            {
                $TotalPrintedInBW = $Printer_Rent_Quota * -1
            }
    }
    Else
    {
        $TotalPrintedInColor = $Printer_Rent_Quota * -1
    }
    $PrinterCost = [Math]::Round( ($TotalPrintedInColor * $Printer_Color_Page_Cost) + ($TotalPrintedInBW * $PrinterBW_Page_Cost) + $Printer_Rent_Value ,2 )
    $PrinterCost = $PrinterCost.ToString('C',[cultureinfo]'pt-BR')
    Write-Host "GetPrinterCost Finished"
    return $PrinterCost
}

Function ImportPrintList{
    param(
        [String]$Path
    )
    Write-Host "Initializing ImportPrintList"
    If (Test-Path -Path $Path){
        $List_ImportPrintList = Import-Csv -Encoding UTF8 -Delimiter ';' $Path
        Write-Host "ImportPrintList Finished"
        Return $List_ImportPrintList
    }
    Else {
        Write-Host "$Path not found !"
        break
    }
}

Function ImportPrinterHistory{
    param(
        [String]$Path
    )
    Write-Host "Initializing ImportPrinterHistory"
    If (Test-Path -Path $Path) {
        $List_ImportPrinterHistory = Import-Csv -Encoding UTF8 -Delimiter ';' $Path | select -Property @{n='Checked_Date';e={[int]$_.Checked_Date}},@{n='Counter_copied_BW';e={[int]$_.Counter_copied_BW}},@{n='Counter_printed_BW';e={[int]$_.Counter_printed_BW}},@{n='Counter_copied_color';e={[int]$_.Counter_copied_color}},@{n='Counter_printed_color';e={[int]$_.Counter_printed_color}},@{n='TotalBWPrinted';e={[int]$_.TotalBWPrinted}},@{n='TotalColorPrinted';e={[int]$_.TotalColorPrinted}},* -Exclude 'Checked_Date','Counter_copied_BW','Counter_printed_BW','Counter_copied_color','Counter_printed_color','TotalColorPrinted','TotalBWPrinted' 
        Write-Host "ImportPrinterHistory Finished"
        return $List_ImportPrinterHistory
    }
    Else {
        Write-Host "$Path not found !"
        break
    }
}

Function PrinterConsumptionHistory{
    param(
        [PSObject]$List
    )
    Write-Host "Initializing PrinterConsumptionHistory"
    $List_PrinterConsumptionHistory = @()
    [int]$last_check_color = 0
    [int]$last_check_bw = 0
    $List | ForEach-Object {
        $Printer_Name = $_.Printer_Name
        $Checked_Date = $null
        $TotalColorPrinted = $null
        $TotalBWPrinted = $null
        $Checked_Date = $_.Checked_Date.tostring()
        $Date = ($Checked_Date.ToString().Substring(6,2) +"-"+ $Checked_Date.ToString().Substring(4,2) +"-"+ $Checked_Date.ToString().Substring(0,4)).tostring()
        [int]$TotalColorPrinted = [int]$_.TotalColorPrinted
        [int]$TotalBWPrinted = [int]$_.TotalBWPrinted
        $dataObject = $null
        $dataObject = New-Object PSObject
        $TotalColor = ([Math]::Round($TotalColorPrinted-$last_check_color))
        $TotalBW = ([Math]::Round($TotalBWPrinted-$last_check_bw))
        If ($TotalColor -lt 0) {$TotalColor=0}
        If ($TotalBW -lt 0) {$TotalBW=0}
        Add-Member -inputObject $dataObject -memberType NoteProperty -name "Printer_Name" -value $Printer_Name
        Add-Member -inputObject $dataObject -memberType NoteProperty -name "Checked_Date" -value $Date
        Add-Member -inputObject $dataObject -memberType NoteProperty -name "TotalBWPrinted" -value $TotalBW
        Add-Member -inputObject $dataObject -memberType NoteProperty -name "TotalColorPrinted" -value $TotalColor
        $List_PrinterConsumptionHistory += $dataObject
        [int]$last_check_color = [int]$_.TotalColorPrinted
        [int]$last_check_bw = [int]$_.TotalBWPrinted
    }
    $List_PrinterConsumptionHistory = $List_PrinterConsumptionHistory | Select-Object -Skip 1 | Select-Object -Last 12
    Write-Host "PrinterConsumptionHistory Finished"
    return $List_PrinterConsumptionHistory
}

#verificar QUANTAS vezes uso essa variavel (SE só usei uma vez... não precisa da variável, já coloca direto)
$ThisYear = (get-date -Format "yyyy")
$ThisMonth = (get-date -Format "MM")
$Year_LastMonth = (Get-Date).date.AddMonths(-1).Year
$LastMonth =  '{0:d2}' -f (Get-Date).date.AddMonths(-1).Month

$PrintList = ImportPrintList -Path "$DestinationFolder\script\PrintList.csv"
$PaperCutLogFolder = "C:\Program Files (x86)\PaperCut Print Logger\logs\csv\monthly"
Clear-Host
$PrintList | ForEach-Object {
    If ((Test-NetConnection $_.IP_Address).PingSucceeded) {
        $PrinterHistory = ImportPrinterHistory "$DestinationFolder\script\history.csv"
        $Name = $_.Name
        $PrinterHistory_FirstMonthCheck = $PrinterHistory | Where-Object { $_.Printer_Name -eq $Name -AND $_.FirstMonthCheck -eq "True" }
        If ($PrinterHistory_FirstMonthCheck | Where-Object { $_.Checked_Date -ge [int]("$ThisYear"+"$ThisMonth"+"00") })
        {
            $PaperCutFile = "papercut-print-log-$ThisYear-$ThisMonth.csv"
            $Save_PerMouth_History = $false
        }
        Else 
        {
            $PaperCutFile = "papercut-print-log-$Year_LastMonth-$LastMonth.csv"
            $Save_PerMouth_History = $true
        }
        $SNMP_List = CreateSNMPList -Printer_Name $Name -FirstMonthCheck $Save_PerMouth_History
        $SNMP_List | Select "FirstMonthCheck","Checked_Date","Printer_Name","Counter_copied_BW","Counter_printed_BW","Counter_copied_color","Counter_printed_color","TotalBWPrinted","TotalColorPrinted" | Export-Csv -NoTypeInformation -Encoding UTF8 -Delimiter ';' "$DestinationFolder\script\history.csv" –Append
        $PaperCutLog = ConvertFromPaperCutLog -PaperCutLogFile "$PaperCutLogFolder\$PaperCutFile" -PrinterName $Name
        $PaperCutLog = ConvertFromListLDAPUsertoSector -List $PaperCutLog -UserColumnName "User"
        $PaperCutLog = CalculateTotalsOfAnList -List $PaperCutLog -Unique "User"
        $PrinterConsumption = $null
        $PrinterConsumption = New-Object PSObject
        Add-Member -inputObject $PrinterConsumption -memberType NoteProperty -name "User" -value "Printer"
        $PrintedInBW = $null
        $PrintedInColor = $null
        $PrintedInBW = $( $($SNMP_List.TotalBWPrinted-$PrinterHistory_FirstMonthCheck[-1].TotalBWPrinted)+$($SNMP_List.Counter_copied_BW-$PrinterHistory_FirstMonthCheck[-1].Counter_copied_BW)-$($PaperCutLog | Measure-Object "PrintedInBW" -Sum).Sum)
        $PrintedInColor = $( $($SNMP_List.TotalColorPrinted-$PrinterHistory_FirstMonthCheck[-1].TotalColorPrinted)+$($SNMP_List.Counter_copied_color-$PrinterHistory_FirstMonthCheck[-1].Counter_copied_color)-$($PaperCutLog | Measure-Object "PrintedInColor" -Sum).Sum)
        If ($PrintedInColor -lt 0)
        {
            If ($($PrintedInBW+$PrintedInColor) -gt 0)
            {
                $PrintedInBW=$PrintedInBW+$PrintedInColor
            }
            $PrintedInColor=0
        }
        Add-Member -inputObject $PrinterConsumption -memberType NoteProperty -name "PrintedInBW" -value $PrintedInBW
        Add-Member -inputObject $PrinterConsumption -memberType NoteProperty -name "PrintedInColor" -value $PrintedInColor
        $PaperCutLog += $PrinterConsumption
        $PaperCutLog | Add-Member -MemberType NoteProperty -Name "UnitPrice_PrintedInBW" -Value $_.BW_Page_Cost
        $PaperCutLog | Add-Member -MemberType NoteProperty -Name "UnitPrice_PrintedInColor" -Value $_.Color_Page_Cost
        $PaperCutLog | Add-Member -MemberType NoteProperty -Name "PrintedInBW_TotalCost" -Value "0"
        $PaperCutLog | Add-Member -MemberType NoteProperty -Name "PrintedInColor_TotalCost" -Value "0"
        $PaperCutLog | ForEach-Object {
            $_.PrintedInBW_TotalCost = [int]$_.PrintedInBW*[double]$_.UnitPrice_PrintedInBW.Replace(",",".")
            $_.PrintedInColor_TotalCost = [int]$_.PrintedInColor*[double]$_.UnitPrice_PrintedInColor.Replace(",",".")
        }
        $PaperCutLog | Add-Member -MemberType NoteProperty -Name "TotalCosted" -Value "0"
        $PaperCutLog | ForEach-Object {
            $_.TotalCosted = $_.PrintedInColor_TotalCost+$_.PrintedInBW_TotalCost
        }
        $PaperCutLog = $PaperCutLog | Sort-Object -Property TotalCosted -Descending
        $PrinterMountlyCost = GetPrinterCost -Printer_Rent_Value ($PrintList | Where-Object { $_.Name -eq $Name }).Rent_Value -Printer_Rent_Quota ($PrintList | Where-Object { $_.Name -eq $Name }).Rent_Quota -Printer_Color_Page_Cost ($PrintList | Where-Object { $_.Name -eq $Name }).Color_Page_Cost.replace(',','.') -PrinterBW_Page_Cost ($PrintList | Where-Object { $_.Name -eq $Name }).BW_Page_Cost.replace(',','.') -TotalPrintedInColor ($PaperCutLog | Measure-Object PrintedInColor -Sum).Sum -TotalPrintedInBW ($PaperCutLog | Measure-Object PrintedInBW -Sum).Sum
        If ($Save_PerMouth_History){
            $GraphMontlyFileName = "$Name`_Chart_PerSector_LastMonth"
            $TitleAxisX = "Sectors"
            $PrinterHistory = ImportPrinterHistory "$DestinationFolder\script\history.csv"
            $PrinterHistory_FirstMonthCheck = $PrinterHistory | Where-Object { $_.Printer_Name -eq $Name -AND $_.FirstMonthCheck -eq "True" }
            $PrinterConsumptionHistory = PrinterConsumptionHistory -List $PrinterHistory_FirstMonthCheck
            CreateGraph -List $PrinterConsumptionHistory -SaveAs "$DestinationFolder\assets\images\$Name`_Chart_PrinterHistory.png" -Width 1500 -Height 500 -MainTitle "$Name - Consumption History" -TitleAxisX "Collected Date" -TitleAxisY "Consumption" -Series1Name "BlackAndWhite" -Series1Color "#000000" -Series1AxisXSource "Checked_Date" -Series1AxisYSource "TotalBWPrinted" -Series2Name "Colorida" -Series2Color "#62B5CC" -Series2AxisXSource "Checked_Date" -Series2AxisYSource "TotalColorPrinted" -ChartType "Column" -WithLegendOn "Right"
        }
        Else 
        {
            $GraphMontlyFileName = "$Name`_Chart_PerSector"
            $TitleAxisX = "The estimated Printer Cost (until now) is - $PrinterMountlyCost"
        }
        CreateGraph -List $PaperCutLog -SaveAs "$DestinationFolder\assets\images\$GraphMontlyFileName.png" -Width 1500 -Height 500 -MainTitle "$Name - Consumption PerSector - $(get-date -Format "dd/MM/yyyy")" -TitleAxisX $TitleAxisX -TitleAxisY "Pages" -Series1Name "BlackAndWhite" -Series1Color "#000000" -Series1AxisXSource "User" -Series1AxisYSource "PrintedInBW" -Series2Name "Color" -Series2Color "#62B5CC" -Series2AxisXSource "User" -Series2AxisYSource "PrintedInColor" -ChartType "Column" -WithLegendOn "Right"
        CreateGraph -List $PaperCutLog -SaveAs "$DestinationFolder\assets\images\History-$Name`_$(get-date -Format "yyyy_MM").png" -Width 1500 -Height 500 -MainTitle "$Name - Consumption PerSector - $(get-date -Format "dd/MM/yyyy")" -TitleAxisX "Sectors" -TitleAxisY "Pages" -Series1Name "BlackAndWhite" -Series1Color "#000000" -Series1AxisXSource "User" -Series1AxisYSource "PrintedInBW" -Series2Name "Color" -Series2Color "#62B5CC" -Series2AxisXSource "User" -Series2AxisYSource "PrintedInColor" -ChartType "Column" -WithLegendOn "Right"
    }
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------
#    SHOW THE GRAPH
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------
#Add-type -AssemblyName System.Windows.Forms
#Add-type -AssemblyName System.Windows.Forms.DataVisualization
#$Form = New-Object System.Windows.Forms.Form
#$Form.Width = 1500
#$Form.Height = 1200
#$Form.Controls.Add($Chart_PerSector)
#$Form.Controls.Add($Chart_PrintCounter)
#$Form.Controls.Add($Chart_PrinterHistory)
#$Form.ShowDialog()