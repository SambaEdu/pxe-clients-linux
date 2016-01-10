#!/bin/bash

#####
# Script lancé au redémarrage qui suit l'installation preseed Debian ###_DEBIAN_###
# pour finaliser la config  et intégrer au domaine le client linux
#
# 
# version 20151222
#
#####

# quelques couleurs ;-)
rouge='\e[0;31m'
rose='\e[1;31m'
orange='\e[0;33m'
jaune='\e[1;33m'
vert='\e[0;32m'
bleu='\e[1;34m'
neutre='\e[0;m'

DEBIAN_PRIORITY="critical"
DEBIAN_FRONTEND="noninteractive"
export  DEBIAN_PRIORITY
export  DEBIAN_FRONTEND

ladate=$(date +%Y%m%d%H%M%S)
gdm="$(cat /etc/X11/default-display-manager | cut -d / -f 4)"
compte_rendu=/root/compte_rendu_post-install_${ladate}.txt

#----- -----
# les fonctions (début)
#----- -----

arret_gdm()
{
    # On arrête le gestionnaire de connexion
    # Actuellement : gdm3 et lightdm
    service $gdm stop
}

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

message_debut()
{
    echo "Compte-rendu de post-installation : $ladate" > $compte_rendu
    # Debug :
    #echo "++++++++" | tee -a $compte_rendu
    #echo "les paramètres :" | tee -a $compte_rendu
    #cat /root/bin/params.sh | tee -a $compte_rendu
    #echo "++++++++" | tee -a $compte_rendu
    
    echo -e "${bleu}"
    echo -e "------------------------------"
    echo -e "Post-configuration du client-linux Debian ###_DEBIAN_###"
    echo -e "------------------------------"
    echo -e "${neutre}"
    echo -e "appuyez sur Entrée pour continuer (sinon, attendre 10s…)"
    read -t 10 dummy
}

cles_publiques_ssh()
{
    echo "mise en place des clés publiques SSH…" | tee -a $compte_rendu
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    cd /root/.ssh
    wget -q http://${ip_se3}/paquet_cles_pub_ssh.tar.gz
    if [ "$?" = "0" ]
    then
        tar -xzf paquet_cles_pub_ssh.tar.gz && \
        cat *.pub > authorized_keys && \
        rm paquet_cles_pub_ssh.tar.gz
    else
        echo "${rouge}échec de la recupération des clés publiques SSH${neutre}" | tee -a $compte_rendu
        # [gestion de cette erreur ? TODO]
        sleep 5
    fi
    cd - >/dev/null
}

configurer_proxy()
{
    if [ -n "$ip_proxy" -a -n "$port_proxy" ]
    then
        echo "configuration du proxy…" | tee -a $compte_rendu
        echo "
export https_proxy=\"http://$ip_proxy:$port_proxy\"
" > /etc/proxy.sh
        chmod +x /etc/proxy.sh
        echo '
if [ -e /etc/proxy.sh ]
then
. /etc/proxy.sh
fi
' >> /etc/profile
    else
        echo "${rouge}IP proxy ou port_proxy non trouvés…${neutre}" | tee -a $compte_rendu
        # [gestion de cette erreur ? TODO]
    fi
}

configurer_vim()
{
    echo "configuration de vim…" | tee -a $compte_rendu
    echo 'filetype plugin indent on
set autoindent
set ruler
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif' > /root/.vimrc
    
    cp /root/.vimrc /etc/skel/.vimrc
}

configurer_ldap()
{
    if [ -n "${ip_ldap}" -a -n "${ldap_base_dn}" ]
    then
        echo "configuration de LDAP…" | tee -a $compte_rendu
        echo "HOST $ip_ldap
BASE $ldap_base_dn
# TLS_REQCERT never
# TLS_CACERTDIR /etc/ldap/
# TLS_CACERT /etc/ldap/slapd.pem
" > /etc/ldap/ldap.conf
    else
        echo "${rouge}IP ldap ou ldap_base_dn non trouvés…${neutre}" | tee -a $compte_rendu
        # [gestion de cette erreur ? TODO]
    fi
}

configurer_ssmtp()
{
    echo "configuration de SSMTP…"
    cp /etc/ssmtp/ssmtp.conf /etc/ssmtp/ssmtp.conf.${ladate}
    echo "
root=$email
#mailhub=mail
mailhub=$mailhub
rewriteDomain=$rewriteDomain
hostname=$nom_machine.$nom_domaine
" > /etc/ssmtp/ssmtp.conf
    sleep 2
}

configurer_ocs()
{
    if [ "$ocs" = "1" ]
    then
        echo "installation et configuration du client OCS…" | tee -a $compte_rendu
        installer_un_paquet ocsinventory-agent
        echo "server=$ip_se3:909" > /etc/ocsinventory/ocsinventory-agent.cfg
    else
        echo "${rouge}le paramètre ocs n'est pas à 1…${neutre}" | tee -a $compte_rendu
        # [gestion de cette erreur ? TODO]
    fi
}

recuperer_script_integration()
{
    echo "téléchargement du script integration_###_DEBIAN_###.bash…" | tee -a $compte_rendu
    mkdir -p /root/bin
    cd /root/bin
    wget -q http://${ip_se3}/install/integration_###_DEBIAN_###.bash
    if [ "$?" = "0" ]
    then
        echo "téléchargement réussi" | tee -a $compte_rendu
        chmod +x integration_###_DEBIAN_###.bash
    else
        echo "${rouge}échec du téléchargement${neutre}" | tee -a $compte_rendu
        echo "${orange}le poste ne pourra pas être intégré au domaine…${neutre}" | tee -a $compte_rendu
        ISCRIPT="erreur"
        # [gestion de cette erreur ? TODO]
    fi
    cd - >/dev/null
}

recuperer_nom_client()
{
    # cela ne concerne que le cas où il n'y a qu'une carte réseau
    # eth0 ou HWaddr ? [TODO : gestion du cas où on a plusieurs cartes réseaux]
    t=$(ifconfig | grep eth0 | sed -e "s|.*HWaddr ||" | wc -l)
    if [ "${t}" = "1" ]
    then
        # Il semble qu'on n'entre pas ici en post-inst exécuté en fin d'installation
        mac=$(ifconfig | grep HWaddr | sed -e "s|.*HWaddr ||")
        echo "une adresse mac trouvée : $mac" | tee -a $compte_rendu
        if [ -n "$mac" ]
        then
            #nom_machine=$(ldapsearch -xLLL macAddress=$mac cn|grep "^cn: "|sed -e "s|^cn: ||")
            t=$(ldapsearch -xLLL macAddress=$mac cn | grep "^cn: " | sed -e "s|^cn: ||" | head -n1)
            if [ -z "$t" ]
            then
                echo "nom de machine non trouvé dans l'annuaire LDAP" | tee -a $compte_rendu
            else
                tab_nom_machine=($(ldapsearch -xLLL macAddress=$mac cn | grep "^cn: " | sed -e "s|^cn: ||"))
                if [ "${#tab_nom_machine[*]}" = "1" ]
                then
                    t=$(echo "${tab_nom_machine[0]}" | sed -e "s|[^A-Za-z0-9_\-]||g")
                    t2=$(echo "${tab_nom_machine[0]}" | sed -e "s|_|-|g")
                    if [ "$t" != "${tab_nom_machine[0]}" ]
                    then
                        echo "${orange}le nom de machine ${tab_nom_machine[0]} contient des caracteres invalides${neutre}"
                    elif [ "$t2" != "${tab_nom_machine[0]}" ]
                    then
                        echo "${orange}le nom de machine ${tab_nom_machine[0]} contient des ${jaune}_${orange} qui seront remplaces par des ${jaune}-${neutre}"
                        nom_machine="$t2"
                        echo "nouveau nom : $nom_machine"
                        sleep 2
                    else
                        nom_machine=${tab_nom_machine[0]}
                        echo "nom de machine trouvé dans l'annuaire LDAP : $nom_machine"
                    fi
                else
                    echo "${rouge}attention : l'adresse MAC ${neutre}${mac}${rouge} est associée à plusieurs machines :${neutre}"
                    ldapsearch -xLLL macAddress=$mac cn | grep "^cn: " | sed -e "s|^cn: ||"
                fi
            fi
        else
            echo "Attention : adresse MAC illisible !"
        fi
    fi
    while [ -z "$nom_machine" ]
    do
        echo -e "machine non connue de l'annuaire, Veuillez saisir un nom"
        echo -e "attention : espaces et _ sont interdits et 15 caractères maxi !"
        read nom_machine
        echo "nom de machine: $nom_machine"
        if [ -n "${nom_machine}" ]
        then
            t=$(echo "${nom_machine:0:1}" | grep "[A-Za-z]")
            if [ -z "$t" ]
            then
                echo "le nom doit commencer par une lettre"
                nom_machine=""
            else
                t=$(echo "${nom_machine}" | sed -e "s/[A-Za-z0-9\-]//g")
                if [ -n "$t" ]
                then
                    echo "le nom $nom_machine contient des caractères invalides: '$t'"
                    nom_machine=""
                fi
            fi
        fi
    done
    sleep 2
}

integrer_domaine()
{
    if [ "$ISCRIPT" != "erreur" ]
    then
        echo -e "${jaune}"
        echo -e "====="
        echo -e "Intégration au domaine SE3"
        echo -e "=====${neutre}"
        echo -e "voulez-vous intégrer la machine au domaine SE3 ?"
        echo -e "sinon répondre n (attente de 10s…)"
        read -t 10 rep
        [ "$rep" != "n" ] && echo "la machine sera mise au domaine dans quelques temps…" && sleep 1 | tee -a $compte_rendu
    else
        echo "script d'intégration non présent…" | tee -a $compte_rendu
    fi
}

installer_un_paquet()
{
    # $1 → le nom du paquet à installer
    paquet="$1"
    # on vérifie si le paquet est disponible dans les dépôts
    verification_depot=$(aptitude search ^$paquet$)
    # si la variable est vide, le paquet n'est pas dans les dépôts
    if [ "$verification_depot" = "" ]
    then
        echo -e "${rouge}$paquet n'est pas dans les dépôts…" | tee -a $compte_rendu
        echo -e "==========${neutre}" | tee -a $compte_rendu
    else
        # on vérifie si le paquet est déjà installé
        verification_installation=$(aptitude search ^$paquet$ | cut -d" " -f1)
        # si la variable ne contient pas i, le paquet n'est pas installé : il faut donc l'installer
        if [ "$verification_installation" != "i" ]
        then
            echo -e "${vert}On installe $paquet" | tee -a $compte_rendu
            echo -e "==========${neutre}" | tee -a $compte_rendu
            aptitude install -y "$paquet" >/dev/null #2>&1
            # on vérifie si l'installation s'est bien déroulée
            if [ $? != "0" ]; then
                echo -e "${rouge}"
                echo -e "Un problème a eu lieu lors de l'installation de $paquet" | tee -a $compte_rendu
                echo -e "==========${neutre}" | tee -a $compte_rendu
            fi
        else
            echo -e "${orange}$paquet est déjà installé…" | tee -a $compte_rendu
            echo -e "==========${neutre}" | tee -a $compte_rendu
        fi
    fi
}

gerer_mesapplis()
{
    # 1 argument
    # $1 → le fichier contenant les paquets à installer
    
    # le paquet tofrodos pour convertir les formats DOS au format UNIX
    # est déjà installé via le preseed
    fromdos /root/bin/$1
    # on élimine les espaces en début de ligne et les commentaires
    liste_paquet=$(grep -Ev '^[[:space:]]*(#|$)' /root/bin/$1 | cut -d# -f 1)
    test_liste=$(echo "$liste_paquet")
    if [ ! -z "$test_liste" ]
    then
        echo "installation des paquets définis dans $1" | tee -a $compte_rendu
        for i in $liste_paquet
        do
            installer_un_paquet $i
        done
     else
        echo -e "${rouge}pas de liste $1 ?${neutre}" | tee -a $compte_rendu
     fi
    
}

installer_liste_paquets()
{
    echo -e "${jaune}"
    echo -e "=========="
    echo -e "début de l'installation des paquets de base" | tee -a $compte_rendu
    echo -e "==========${neutre}" | tee -a $compte_rendu
    sleep 2
    # on s'assure de l'utilisation du proxy
    if [ -e /etc/proxy.sh ]
    then
        . /etc/proxy.sh
    fi
    # on recharge la liste des paquets
    echo "on recharge la liste des paquets"
    aptitude -q2 update
    # traitement des 3 listes de paquets
    test_applis=""
    [ -e /root/bin/mesapplis-debian.txt ] && test_applis="1" && gerer_mesapplis mesapplis-debian.txt
    [ -e /root/bin/mesapplis-debian-eb.txt ] && test_applis="1" && gerer_mesapplis mesapplis-debian-eb.txt
    [ -e /root/bin/mesapplis-debian-perso.txt ] && test_applis="1" && gerer_mesapplis mesapplis-debian-perso.txt
    if [ "$test_applis" = "" ]
    then
        echo -e "${rouge}aucune liste de paquets ?${neutre}" | tee -a $compte_rendu
    fi
    echo ""
}

lancer_integration()
{
    echo "intégration du client-linux $nom_machine au domaine géré par le se3" | tee -a $compte_rendu
    ./integration_###_DEBIAN_###.bash --nom-client="$nom_machine" --is --ivl | tee -a $compte_rendu
}

renommer_machine()
{
    echo "on n'intègre pas au domaine… mais renommage du poste pour $nom_machine" | tee -a $compte_rendu 
    echo "$nom_machine" > "/etc/hostname"
    invoke-rc.d hostname.sh stop >/dev/null 2>&1
    invoke-rc.d hostname.sh start >/dev/null 2>&1
    echo "
    127.0.0.1    localhost
    127.0.1.1    $nom_machine
    
    # The following lines are desirable for IPv6 capable hosts
    ::1      ip6-localhost ip6-loopback
    fe00::0  ip6-localnet
    ff00::0  ip6-mcastprefix
    ff02::1  ip6-allnodes
    ff02::2  ip6-allrouters
    " > "/etc/hosts"
    echo "renommage terminé" | tee -a $compte_rendu
    echo "pour intégrer le poste plus tard :
    cd /root/bin/
    ./integration_###_DEBIAN_###.bash --nom-client=\"$nom_machine\" --is --ivl" | tee -a $compte_rendu
}

configurer_grub()
{
    echo "configuration de grub…" | tee -a $compte_rendu
    # Virer l'entrée "mode de dépannage"
    sed -i '/GRUB_DISABLE_RECOVERY/ s/^#//' /etc/default/grub
    update-grub
}

menage_script()
{
    mv /root/bin/post-install_debian.sh /root/bin/post-install_debian.sh.$ladate
}

activer_gdm()
{
    # On remet en place le gestionnaire de connexion
    # il sera activer lors du redémarrage
    # Actuellement : gdm3 et lightdm
    #
    echo "annulation de la désactivation de ${gdm}…" | tee -a $compte_rendu
    rm -f /usr/sbin/$gdm
    mv /usr/sbin/$gdm.save /usr/sbin/$gdm
}

annuler_autologin()
{
    echo "annulation de l'autologin…" | tee -a $compte_rendu
    rm -rf /etc/systemd/system/getty@tty1.service.d
}

lancer_script_perso()
{
    wget -q http://${ip_se3}/install/messcripts_perso/monscript-perso.sh
    if [ "$?" = "0" ]
    then
        echo "lancement des scripts perso" | tee -a $compte_rendu
        bash monscript-perso.sh | tee -a $compte_rendu
        cd - >/dev/null
    else
        echo "${rouge}échec du téléchargement des scripts perso${neutre}" | tee -a $compte_rendu
        # [gestion de cette erreur ? TODO]
    fi
}

message_fin()
{
    echo -e "${bleu}"
    echo "------------------------------"
    echo "redémarrage dans 10s pour finaliser la post-installation" | tee -a $compte_rendu
    echo "------------------------------"
    echo -e "${neutre}" | tee -a $compte_rendu
    read -t 10 dummy
}

#----- -----
# les fonctions (fin)
#----- -----

#####
# début du programme
arret_gdm
recuperer_parametres
test_se3
message_debut
cles_publiques_ssh
configurer_proxy
configurer_vim
configurer_ldap
configurer_ssmtp
configurer_ocs
recuperer_script_integration
recuperer_nom_client
integrer_domaine
installer_liste_paquets
[ "$rep" != "n" ] && lancer_integration
[ "$rep" = "n" ] && renommer_machine
configurer_grub
menage_script
activer_gdm
annuler_autologin
lancer_script_perso
message_fin
reboot
exit 0
# fin du programme
#####
