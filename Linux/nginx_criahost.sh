#!/bin/bash
FQDN=$1
IPADDRESS=$2
bold=$(tput bold)
underline=$(tput smul)
normal=$(tput sgr0)
if [[ $FQDN == *".org.br" ]] && [[ $IPADDRESS == "10."* ]] && [[ $IPADDRESS =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        NOMEHOST=`echo $FQDN |awk -F. '{ print $1 }'`
        DOMAIN=`echo $FQDN | sed "s/$NOMEHOST\.//1"`
        TEMPLATEFILE="/etc/nginx/conf.d/nginx.template"
        NEWFILE="/etc/nginx/conf.d/$FQDN.conf"
        if [ ! -f $TEMPLATEFILE ]; then
            echo "Template File $TEMPLATEFILE not found, please check!"
            exit 0
        fi
        if [ -f $NEWFILE ]; then
            echo "Template File $NEWFILE already exists, please check!"
            exit 0
        fi
        cp $TEMPLATEFILE $NEWFILE
        sed -i "s/NOMEHOST/$NOMEHOST/g" $NEWFILE
        sed -i "s/IPADDRESS/$IPADDRESS/g" $NEWFILE
        sed -i "s/DOMAIN/$DOMAIN/g" $NEWFILE
        /etc/nginx/conf.d/nginx_check.sh
        echo ""
        echo "Feito - MAS ATENÇÃO - Lembre-se de:"
        echo "-----------------------------------"
        echo "";echo""
        echo " 1 - Cadastrar no DNS INTERNO (Windows)"
        echo "     Expandir FOWARD ZONES, abrir o dominio ${bold}$DOMAIN${normal} e esperar carregar"
        echo "     Clicar com o botão DIREITO neste dominio e criar um novo ${bold}CNAME${normal}"
        echo "     Criar o ${bold}CNAME${normal} ${underline}$NOMEHOST${normal} apontando para ${underline}esse servidor proxy${normal}"
        echo ""
        echo ""
        echo " 2 - Cadastrar no DNS EXTERNO"
        echo "     Edite o arquivo ${bold}$DOMAIN.dns${normal} incluindo o ${underline}$NOMEHOST${normal} seguindo a ordem alfabética"
        echo "     Adicione o texto ${bold}CNAME${normal} na segunda coluna e ${bold}prx${normal} na terceira coluna"
        echo "     Ainda no arquivo encontre no inicio do arquivo o ${bold}serial${normal} e substitua o valor seguindo o padrão ${underline}AAAAMMDDID${normal} (ano mes dia id)"
        echo "     Salve e saia do arquivo"
        echo "     Execute o script ${bold}named_check.sh${normal}"
        echo "";echo""
        echo " 3 - Teste nas redes que foi liberado (${bold}INTERNAMENTE${normal}, ${bold}WIFI${normal}, ${bold}EXTERNAMENTE${normal}, ect.)"
        echo "";echo""
else
        echo "ERRO - USE: comando ${bold}HOST.DOMINIO IPADDRESS${normal}"
fi
