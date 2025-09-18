#https://www.sharepointdiary.com/2018/01/migrate-file-share-to-sharepoint-online-using-powershell.html
#https://www.youtube.com/watch?v=WceeMca_vwY
#https://www.youtube.com/watch?v=xwKTFfhQWLY
#---------------------------------------------------------------------------------------------------------------------------------
#Install-Module SharePointPnPPowerShellOnline
#Install-Module -Name Microsoft.Online.SharePoint.PowerShell
#---------------------------------------------------------------------------------------------------------------------------------
$Counter = 0
$env:PNPLEGACYMESSAGE='false'
Clear-Host

#Get Sharepoint URL
Write-Host "https://" -NoNewline
Write-Host "YOUR_TENANT" -ForegroundColor Yellow -NoNewline
Write-Host ".sharepoint.com/sites/" -NoNewline
Write-Host "YOUR_SITE" -ForegroundColor Red
Write-Host "Inform what is "-NoNewline
Write-Host "YOUR_TENANT" -ForegroundColor Yellow -NoNewline
$tenant = Read-Host " "
Write-Host "Inform what is "-NoNewline
Write-Host "YOUR_SITE" -ForegroundColor Red -NoNewline
$SharePointSite = Read-Host " "

#Get local folder
$folderDialog = New-Object -ComObject Shell.Application
$folder = $folderDialog.BrowseForFolder(0, "Informe a pasta que deseja migrar", 0, 0)
$SourceFolder = $folder.Self.Path

#Conecting to SharePoint
Write-Host "----- Conecting into SharePoint https://" -NoNewline
Write-Host "$tenant" -ForegroundColor Yellow -NoNewline
Write-Host ".sharepoint.com/sites/" -NoNewline
Write-Host "$SharePointSite" -ForegroundColor Red

$SiteURL = "https://$tenant.sharepoint.com/sites/$SharePointSite"
Connect-PnPOnline -Url "$SiteURL" -UseWebLogin

#Listing local content
Write-Host "----- Listando o conteúdo existente"
$items = Get-ChildItem $SourceFolder -Recurse -File

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

#Copying files
Write-Host "----- Copying files"
$items | ForEach-Object {
    $item = $_
    $FullName = ($item).FullName
    $FolderSource = ($item).DirectoryName
    $FileName = ($item).Name
    $TargetFolderURL = "Documentos"+$FolderSource.Replace($SourceFolder,"").Replace("\","/")
    $FileExists = Get-PnPFile -Url "$TargetFolderURL\$FileName" -ErrorAction SilentlyContinue
    If(!$FileExists)
    {
        try {
            #Resolve-PnPFolder -SiteRelativePath $TargetFolderURL | out-null
            Add-PnPFile -Path $FullName -Folder $TargetFolderURL -ErrorAction Stop | out-null
            #Write-Host "Copied $FullName" -ForegroundColor Green
            $Counter++
        }
        catch {
            Write-Host "Not copied $FullName" -ForegroundColor Red
        }
    }
}
Write-Host "$Counter++ files copied"