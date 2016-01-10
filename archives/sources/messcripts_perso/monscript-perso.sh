#!/bin/bash

#####
#
# Ci-dessous, vous pouvez ajouter des commandes
# (à la fin du fichier)
# ces commandes seront prises en compte à la fin de la post-installation.
#
# Des fonctions déjà disponibles vous donnent accès à des variables
# vous pouvez utiliser dans ce script les variables suivantes :
# → Paramètres Proxy :
#               $ip_proxy
#               $port_proxy
# → Paramètres SE3 :
#               $ip_se3
#               $nom_se3
#               $nom_domaine
# → Paramètres LDAP :
#               $ip_ldap
#               $ldap_base_dn
#


ladate=$(date +%Y%m%d%H%M%S)

#####
# quelques couleurs ;-)
#
rouge='\e[0;31m'
rose='\e[1;31m'
orange='\e[0;33m'
jaune='\e[1;33m'
vert='\e[0;32m'
bleu='\e[1;34m'
neutre='\e[0;m'

#----- -----
# les fonctions (début)
#----- -----

recuperer_parametres()
{
    # le fichier des paramètres a été mis en place à la fin de l'installation
    . /root/bin/params.sh
}

test_se3()
{
    if [ -n "${ip_se3}" ]
    then
        TEST_CLIENT=$(ifconfig | grep ":$ip_se3 ")
        if [ -e /var/www/se3 ]
        then
            echo -e "${rouge}Malheureux… Ce script est à exécuter sur les clients Linux, pas sur le serveur !${neutre}"
            echo ""
            exit 1
        fi
    else
        echo -e "${rouge}IP se3 non trouvé…${neutre}"
        echo ""
        exit 1
    fi
}

#----- -----
# les fonctions (fin)
#----- -----

#####
# début du programme
recuperer_parametres
test_se3
# Vos commandes perso :


exit 0
# fin du programme
#####
