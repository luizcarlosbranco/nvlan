$NOME_COMPLETO = Read-Host -Prompt 'Informe o nome completo da pessoa (ex: Fulanos da Silva Sauro)'
$NameRAW = $NOME_COMPLETO.ToLower().Replace("."," ").Replace("-"," ").Replace(","," ").Replace("  "," ").Trim(" ")
$NameRAW = [regex]::Replace($NameRAW,"\s+"," ").Trim()
$Array_Nome = $NameRAW.Split(" ")
$NOME_COMPLETO = $null
$espaco = $null
$name = $null
$ligacao = 'e','de','da','das','do','dos'
$i=0
while($i -lt $Array_Nome.Count)
{
    $name = $Array_Nome[$i]
    if ($ligacao.Contains($name))
    {
        $NOME_COMPLETO = $NOME_COMPLETO+" "+$name
    }
    else
    {
        $NOME_COMPLETO = $NOME_COMPLETO+""+$espaco+""+$name.substring(0,1).toupper()+$name.substring(1).tolower()
    }
    $espaco = " "
    $i = $i+1
}
echo "$NOME_COMPLETO"