# Necessário o QRCodeGenerator, execute COMO ADMINISTRADOR o comando "Install-Module -Name QRCodeGenerator -Scope AllUsers -Force" e depois abra um novo PowerShell

# CONFIGURAÇÃO (ALTERE COMO DESEJAR)
# ==========================================
$Caracteres = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
$Controller = "https://seuubiquitiserver.seudominio.com:8443"
$DestinationFolder = "C:\Temp"
$HTMLFile = "wallpaper.html"
$ImageFile = "wallpaper.png"
$NetworkSSID = "NomeDaRede"
$QRFileName = "WiFiQR.png"
$SharedFolder = "\\Nome_servidor\PastaCompartilhada"
$SourceFolder = "C:\Temp"
$TamanhoSenha = 8
$TemplateFile = "template.html"
$UnifiUser = "admin"
$UnifiPass = "Senha_do_admin"

# INICIO DO SCRIPT
# ==========================================
$templatePath = Join-Path $SourceFolder $TemplateFile
if (-not (Test-Path -Path $SourceFolder -PathType Container)) { break }
if (-not (Test-Path $templatePath -PathType Leaf)) { break }
if (-not (Test-Path -Path $SharedFolder -PathType Container)) { break }
$QrPath = Join-Path $DestinationFolder $QRFileName
$HTMLPath = Join-Path $DestinationFolder $HTMLFile
$ImageFullPath = Join-Path $SharedFolder $ImageFile

$NetworkPass = -join (1..$TamanhoSenha | ForEach-Object {
    $Caracteres[(Get-Random -Minimum 0 -Maximum $Caracteres.Length)]
})

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$Session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

$LoginBody = @{
    username = $UnifiUser
    password = $UnifiPass
} | ConvertTo-Json

$Login = Invoke-RestMethod -Uri "$Controller/api/login" -Method POST -Body $LoginBody -ContentType "application/json" -WebSession $Session

if ($Login.meta.rc -ne "ok") {
    Write-Host "Falha no login" -ForegroundColor Yellow
    break
}

$Sites = Invoke-RestMethod -Uri "$Controller/api/self/sites" -Method GET -WebSession $Session

if ($Sites.data.Count -eq 0) {
    Write-Host "Nenhum site encontrado" -ForegroundColor Yellow
    break
}

$Encontrados = @()

foreach ($Site in $Sites.data) {
    try {
        $Wlans = Invoke-RestMethod -Uri "$Controller/api/s/$($Site.name)/rest/wlanconf" -Method GET -WebSession $Session
        foreach ($Wifi in $Wlans.data) {
            if ($Wifi.name -eq $NetworkSSID) {
                $Encontrados += [PSCustomObject]@{
                    SiteNome   = $Site.name
                    SiteID     = $Site._id
                    WifiNome   = $Wifi.name
                    WifiID     = $Wifi._id
                    Security   = $Wifi.security
                    Enabled    = $Wifi.enabled
                }
            }
        }
    }
    catch {
        Write-Host "Erro consultando site $($Site.name): $($_.Exception.Message)" -ForegroundColor Yellow
        break
    }
}

$WifiEncontrado = $Encontrados[0]
if ($WifiEncontrado.Security -ne "wpapsk") {
    Write-Host "ABORTADO - Apenas redes wpapsk podem ter senha compartilhada alterada." -ForegroundColor Yellow
    break
}

$BodyAlteracao = @{
    x_passphrase = $NetworkPass
} | ConvertTo-Json

$Alteracao = Invoke-RestMethod -Uri "$Controller/api/s/$($WifiEncontrado.SiteNome)/rest/wlanconf/$($WifiEncontrado.WifiID)" -Method PUT -Body $BodyAlteracao -ContentType "application/json" -WebSession $Session

if ($Alteracao.meta.rc -eq "ok") {
    New-QRCodeText -Text "WIFI:T:WPA;S:$NetworkSSID;P:$NetworkPass;;" -OutPath $QrPath -Width 10

    (Get-Content $templatePath -Raw) -replace "NomeDaRede", "$NetworkSSID" -replace "SenhaDaRede", "$NetworkPass" -replace "logo.png", "$SourceFolder\logo.png" | Set-Content $HTMLPath

    Remove-Item "$ImageFullPath" -Force -ErrorAction SilentlyContinue

    $Edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    if (-not (Test-Path $Edge)) { $Edge = "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe" }

    $EdgeProfile = "$DestinationFolder\Edge"
    New-Item -ItemType Directory -Path $EdgeProfile -Force | Out-Null
    & $Edge --headless --disable-gpu --hide-scrollbars --no-sandbox --user-data-dir="$EdgeProfile" --screenshot="$ImageFullPath" --window-size=1920,1080 "file:///$($HTMLPath -replace '\\','/')"

    $count = 0
    do { 
        Start-Sleep -Seconds 1
        $count++
    } while (-not (Test-Path -LiteralPath $ImageFullPath) -and $count -lt 30)

    Remove-Item "$EdgeProfile" -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    Remove-Item "$HTMLPath" -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    Remove-Item "$QrPath" -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
}