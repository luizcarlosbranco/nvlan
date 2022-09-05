$ErrorActionPreference= 'silentlycontinue'
#Define ESSAS VARIAVEIS
$home_folder = "C:\Temp\logon_hours\Script para gerar solicitação"
$template_file = "template_solicitacao.docx"
Clear-host
#Inicio do Script
$username = $env:USERPROFILE.Split("\")[-1]
$BaseDN = (Get-ADUser $username).DistinguishedName
$BaseDN = $BaseDN.Replace($BaseDN.Split(',')[0]+",","")
Get-ADUser -filter {enabled -eq $true}  -SearchBase $BaseDN -Properties * | ForEach-Object {
    $user = $_
    $manager = (Get-ADUser $user.manager).samaccountname
    IF ($user.DistinguishedName.Replace($user.DistinguishedName.Split(',')[0]+",","") -eq $user.manager.Replace($user.manager.Split(',')[0]+",","") )
    {
        $name = $user.displayname
        Write-Host "Gerando o formulário de $name " -NoNewline
        #https://www.myfaqbase.com/q0001768-Scripting-Powershell-5-0-Working-with-Microsoft-Office-Word-document-Part-1.html
        $Word = New-Object -ComObject Word.Application
        $Word.visible = $False
        $Word.Selection.Find.ClearFormatting();
        $document = $Word.Documents.Open($home_folder+"\"+$template_file)
        $_.GetEnumerator() | ForEach-Object {
            $Key = $_.Key
            $Manager = $user.manager.Split(',')[0].replace("CN=","")
            $Value = $user.$key
            switch ( $Key )
            {
                "thumbnailPhoto"
                {
                        #if contain image
                        [byte[]] $byte_array = $user.thumbnailPhoto
                        $ms = new-object System.IO.MemoryStream(,$byte_array)
                        $img = [system.drawing.Image]::FromStream($ms)
                        $img2 = New-Object System.Drawing.Bitmap(100, 100)
                        $graph = [System.Drawing.Graphics]::FromImage($img2)
                        $graph.DrawImage($img, 0, 0, 100, 100)
                        [System.Windows.Forms.Clipboard]::SetImage($img2)
                        if ($Word.Selection.Find.Execute("[thumbnailphoto]"))
                        {
                            $Word.Selection.Paste()
                        }
                        [System.Windows.Forms.Clipboard]::Clear()
                }
                "Manager"
                {
                    $Document.Content.Find.Execute("["+$Key+"]", $false, $true, $false, $false, $false, $true, "1", $false, $Manager, "2") | Out-Null
                }
                default
                {
                    $Document.Content.Find.Execute("["+$Key+"]", $false, $true, $false, $false, $false, $true, "1", $false, $Value, "2") | Out-Null
                }
            }
            Write-Host "." -NoNewline
        }
        Write-Host "."
        #$document.SaveAs([ref] $home_folder+"\"+$user.SamAccountName+".pdf", [ref]17)
        $file = $user.SamAccountName+".pdf"
        $document.SaveAs([ref] "C:\Temp\logon_hours\Script para gerar solicitação\$file", [ref]17)
        $document.Close(0)
        $Word.Quit()
        Start-Process ((Resolve-Path "C:\Temp\logon_hours\Script para gerar solicitação\$file").Path)
    }
}