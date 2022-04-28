Clear-host
#About excel https://docs.microsoft.com/pt-br/office/vba/api/excel.range(object)
$FONT_FILENAME = "CCode39"
#Pre-req Check
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
$installed_fonts = (New-Object System.Drawing.Text.InstalledFontCollection).Families
if ($installed_fonts -notcontains $FONT_FILENAME)
{
    [System.Windows.MessageBox]::Show('TTF font not found, install from https://www.dafont.com/ccode39.font','ERRO','OK','Error') | Out-Null
    Exit
}
$date = (Get-Date -Format "yyyMMdd-hhmmss")
$File = (Get-Location).Path+"\File-$date.pdf"

#START HERE
$totalitens=0
$line=1
$excel = New-Object -ComObject excel.application
$excel.visible = $False
$excel.DisplayAlerts = $false

Write-Host "Creating a PDF file (using Ms. Excel)"

$workbook = $excel.Workbooks.Add()
$uregwksht = $workbook.Worksheets.Item(1)
$uregwksht.Name = "Filial 123"
$uregwksht.PageSetup.Orientation = 2

$uregwksht.Cells.Item($line,1) = "Filial"
$uregwksht.Cells.Item($line,2) = "DESC_Prod"
$uregwksht.Cells.Item($line,3) = "Und_Med"
$uregwksht.Cells.Item($line,4) = "COD_Prod"
$uregwksht.Cells.Item($line,5) = "Codigo de barras"

$uregwksht.Cells.EntireRow($line).Font.Size = 14
$uregwksht.Cells.EntireRow($line).Font.Bold = $True
$uregwksht.Cells.EntireRow($line).Font.Name = "Cambria"
$uregwksht.Cells.EntireRow($line).Font.ThemeFont = 1
$uregwksht.Cells.EntireRow($line).Font.ThemeColor = 4
$uregwksht.Cells.EntireRow($line).Font.ColorIndex = 55
$uregwksht.Cells.EntireRow($line).Font.Color = 8210719
$uregwksht.Cells.EntireRow($line).HorizontalAlignment = 3

#Could be a Loop (incremeting lines) here
$line++
$uregwksht.Cells.Item($line,1).NumberFormat = "000000"
$uregwksht.Cells.Item($line,1).VerticalAlignment = -4108
$uregwksht.Cells.Item($line,1).HorizontalAlignment = 3
$uregwksht.Cells.Item($line,1) = "Filial"
$uregwksht.Cells.Item($line,2).VerticalAlignment = -4108
$uregwksht.Cells.Item($line,2) = "DESC_Prod"
$uregwksht.Cells.Item($line,3).VerticalAlignment = -4108
$uregwksht.Cells.Item($line,3).HorizontalAlignment = 3
$uregwksht.Cells.Item($line,3) = "Und_Med"
$uregwksht.Cells.Item($line,4).VerticalAlignment = -4108
$uregwksht.Cells.Item($line,4).HorizontalAlignment = 3
$uregwksht.Cells.Item($line,4).NumberFormat = "000000000000"
$uregwksht.Cells.Item($line,4) = "COD_Prod"
$uregwksht.Cells.Item($line,5) = "*123-321*"
$uregwksht.Cells.Item($line,5).Font.Size = 24
#$uregwksht.Cells.Item($line,5).Font.Name = "$FONT_NAME"
$uregwksht.Cells.Item($line,5).Font.Name = "$FONT_FILENAME"
$uregwksht.Cells.Item($line,5).VerticalAlignment = -4108
#End of (the possible) loop

#Auto fit everything so it looks better
$usedRange = $uregwksht.UsedRange
$usedRange.EntireColumn.AutoFit() | Out-Null

#Page Settings
$uregwksht.PageSetup.Zoom = $false
$uregwksht.PageSetup.FitToPagesTall = 9999
$uregwksht.PageSetup.FitToPagesWide = 1
$uregwksht.PageSetup.LeftMargin = $excel.InchesToPoints(0.25)
$uregwksht.PageSetup.RightMargin = $excel.InchesToPoints(0.25)
$uregwksht.PageSetup.TopMargin = $excel.InchesToPoints(0.5)
$uregwksht.PageSetup.BottomMargin = $excel.InchesToPoints(0.5)
$uregwksht.PageSetup.HeaderMargin = $excel.InchesToPoints(0.25)
$uregwksht.PageSetup.FooterMargin = $excel.InchesToPoints(0.25)
#saving as PDF 
$workbook.ExportAsFixedFormat([Microsoft.Office.Interop.Excel.XlFixedFormatType]::xlTypePDF, "$File")
$workbook.Close()
# Closing the file
$excel.Quit()

Write-Host "File $File created!"