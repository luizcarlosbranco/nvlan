$ExportReportTo = "C:\Temp\"
$Folders = "E:\deptos\Folder1","E:\deptos\Folder2","F:\Projects\Project1","X:\Temp"
$ExtensionsWhiteList = "bmp","bpm","crt","csr","csv","doc","docx","gif","jpg","jpeg","key","pbix","pdf","png","ppt","pptx","pps","psd","txt","vsd","xls","xlsx"
$WordsWhiteList = "template"
$Extensions = "7z","backup","bak","bkp","cab","dll","exe","iso","jar","js","lnk","mbd","mp3","msi","otf","rar","tar","tmp","ttf","zip"
$Words = "antig","apagar","backup","bak","bkp","checar","deletar","excluir","instalador","lixeira","software","suporte","temp","tmp"
#Colocar acentuação em Portugues
chcp 1252
$ErrorActionPreference= 'silentlycontinue'
Clear-host
$Folders | ForEach-Object {
    $FolderPath = $_
    If (Test-Path "$FolderPath") {
        $FolderName = (get-item $FolderPath).Name
        Write-host "------------------------------"
        Write-host "- Folder $FolderName - $(date)"
    #Listar os fullpaths maiores do que 250
        Write-host "- Getting Long Folders " -NoNewline
        cd "$FolderPath"
        Out-File C:\Temp\$FolderName-longfilepath.txt ; cmd /c "dir /b /s /a" | ForEach-Object { if ($_.length -gt 250) {$_ | Out-File -append C:\Temp\$FolderName-longfilepath.txt}}
        Write-host "FINISHED" -ForegroundColor Green

    #Obtendo informação da pasta
        Write-host "- Getting Folder Content " -NoNewline
        $FullList = Get-ChildItem -File -Recurse -Path "$FolderPath" | Select-Object DirectoryCounted,Directory,Name,Extension,Filter,ObjectFound,CreationTime,LastAccessTime,LastWriteTime,Length | Where-Object Directory -ne $Null
        Write-host "FINISHED" -ForegroundColor Green

    #Retirando o que for WHITELIST
        Write-host "- WordWhiteList: " -NoNewline
        $WordsWhiteList | ForEach-Object {
            $WordWhiteList = "$_"
            Write-host "$WordWhiteList " -NoNewline -ForegroundColor Yellow
            $FullList = $FullList | Where-Object Directory -NotLike "*$WordWhiteList*"
        }
        Write-host "FINISHED" -ForegroundColor Green

        Write-host "- ExtensionWhiteList: " -NoNewline
        $ExtensionsWhiteList | ForEach-Object {
            $ExtensionWhiteList = ".$_"
            Write-host "$ExtensionWhiteList " -NoNewline -ForegroundColor Yellow
            $FullList = $FullList | Where-Object Extension -ne "$ExtensionWhiteList"
        }
        Write-host "FINISHED" -ForegroundColor Green

    #Criando um Loop para CADA extensão da lista (pegar o que existe)
        Write-host "- Extension: " -NoNewline
        $Extensions | ForEach-Object { 
            $Extension = ".$_"
            Write-host "$Extension " -NoNewline -ForegroundColor Yellow
            $FullList | Where-Object {($_.Filter -eq $Null) -AND ($_.Extension -eq "$Extension")} | ForEach-Object {
                $_.Filter = "FileExtension"
                $_.ObjectFound = $Extension
            }
        }
        Write-host "FINISHED" -ForegroundColor Green

    #Criando um Loop para CADA palavra da lista do ARQUIVO (pegar o que existe)
        Write-host "- Word in FILE: " -NoNewline
        $Words | ForEach-Object {
            $Word = $_
            Write-host "$Word " -NoNewline -ForegroundColor Yellow
            $FullList | Where-Object {($_.Filter -eq $Null) -AND ($_.Name -like "*$Word*")} | ForEach-Object {
                $_.Filter = "Arquivo Contem Nome"
                $_.ObjectFound = $Word
            }
        }
    Write-host "FINISHED" -ForegroundColor Green

    #Criando um Loop para CADA palavra da lista da PASTA (pegar o que existe)
        Write-host "- Word in PATH: " -NoNewline
        $Words | ForEach-Object {
            $Word = $_
            Write-host "$Word " -NoNewline -ForegroundColor Yellow
            $FullList | Where-Object {($_.Filter -eq $Null) -AND ($_.Directory -like "*$Word*")} | ForEach-Object {
                $_.Filter = "Pasta Contem Nome"
                $_.ObjectFound = $Word
            }
        }
        Write-host "FINISHED" -ForegroundColor Green

    #Carrego a lista APENAS do que foi capturado por algum filtro
        $FullList = $FullList | Where-Object Filter -ne $Null | Sort-Object -property DirectoryCounted –Descending

    #Organizar por COUNT
        Write-host "- Counting how many each folder is in the list: " -NoNewline
        $FullPathsList = $FullList.Directory.FullName | Get-Unique
        $FullPathsList | ForEach-Object {
            $FullPath = $_
            $count = @($FullList | Where-Object Directory -like "$FullPath").count
            $FullList | Where-Object Directory -like "$FullPath" | ForEach-Object {
                $_.DirectoryCounted = $count
            }
        }

    #Exportando para CSV
        Write-host "Saving " -NoNewline
        $FullList | Export-Csv -NoTypeInformation -Encoding UTF8 -Delimiter ';' "$ExportReportTo\$FolderName-Report.csv"
        Write-host "- FINISHED " -ForegroundColor Green

    }
}
