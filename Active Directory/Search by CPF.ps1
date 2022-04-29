Clear-Host
[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
$title = 'Consulta no AD'
$msg   = 'Informe o CPF que deseja pesquisar:'
$CPF = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)

$CPF_CRU = $CPF.Replace(" ","").Trim(" ")
$CPF = $CPF.Replace(".","").Replace("-","").Replace(" ","").Trim(" ")
$CPF = $CPF.SubString(0,3)+"."+$CPF.SubString(3,3)+"."+$CPF.SubString(6,3)+"-"+$CPF.SubString(9,2)
If ($CPF) {
    try{
        Get-Aduser -filter 'Employeeid -eq $CPF'
    }
    catch{
        Write-Host "Nenhum usuario encontrado"
        break
    }
    Write-Host -NoNewLine '';
    Write-Host -NoNewLine 'Press ENTER para sair...';
    Read-host
}