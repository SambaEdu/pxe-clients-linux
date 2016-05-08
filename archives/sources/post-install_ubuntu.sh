#!/bin/bash

#####
# Script lancé au redémarrage qui suit l'installation preseed Ubuntu Xenial
# pour finaliser la config  et intégrer au domaine le client linux
#
# 
# version 20160429
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
    # et il a été créé lors de la mise en place du mécanisme pxe
    . /root/bin/params.sh
}

test_se3()
{
    if [ -n "${ip_se3}" ]
    then
        TEST_CLIENT=$(ifconfig | grep ":$ip_se3 ")
        if [ -e "/var/www/se3" ]
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
    echo -e "Post-configuration du client-linux Ubuntu Xenial"
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

permettre_ssh_root()
{
    echo "permettre la connexion en ssh sur root…" | tee -a $compte_rendu
    # on remplace without-password par yes dans le fichier de configuration de ssh
    sed -i "/^PermitRootLogin/ s/without-password/yes/" /etc/ssh/sshd_config
}

configurer_proxy()
{
    if [ -n "$ip_proxy" -a -n "$port_proxy" ]
    then
        echo "configuration du proxy…" | tee -a $compte_rendu
        cat > /etc/proxy.sh <<END

export https_proxy="http://$ip_proxy:$port_proxy"

END
        chmod +x /etc/proxy.sh
        cat >> /etc/profile <<END

if [ -e "/etc/proxy.sh" ]
then
    . /etc/proxy.sh
fi

END
    else
        echo "${rouge}IP proxy ou port_proxy non trouvés…${neutre}" | tee -a $compte_rendu
        # [gestion de cette erreur ? TODO]
    fi
}

configurer_vim()
{
    echo "configuration de vim…" | tee -a $compte_rendu
    cat > /root/.vimrc <<END
filetype plugin indent on
set autoindent
set ruler
if &t_Co > 2 || has("gui_running")
    syntax on
    set hlsearch
endif
END
    cp /root/.vimrc /etc/skel/.vimrc
}

configurer_ldap()
{
    if [ -n "${ip_ldap}" -a -n "${ldap_base_dn}" ]
    then
        echo "configuration de LDAP…" | tee -a $compte_rendu
        cat > /etc/ldap/ldap.conf <<END
HOST $ip_ldap
BASE $ldap_base_dn
# TLS_REQCERT never
# TLS_CACERTDIR /etc/ldap/
# TLS_CACERT /etc/ldap/slapd.pem

END
    else
        echo "${rouge}IP ldap ou ldap_base_dn non trouvés…${neutre}" | tee -a $compte_rendu
        # [gestion de cette erreur ? TODO]
    fi
}

configurer_ssmtp()
{
    echo "configuration de SSMTP…"
    cp /etc/ssmtp/ssmtp.conf /etc/ssmtp/ssmtp.conf.${ladate}
    cat > /etc/ssmtp/ssmtp.conf <<END

root=$email
#mailhub=mail
mailhub=$mailhub
rewriteDomain=$rewriteDomain
hostname=$nom_machine.$nom_domaine

END
    sleep 2
}

configurer_ocs()
{
    if [ "$ocs" = "1" ]
    then
        # L'installation du client ocsinventory nécessite
        # de préconfigurer des réponses sous peine de "casser" dpkg
        debconf-set-selections <<EOF
ocsinventory-agent	ocsinventory-agent/method	select	http
ocsinventory-agent	ocsinventory-agent/server	string	${ip_se3}:$port_ocs
ocsinventory-agent	ocsinventory-agent/tag	string
EOF
        echo "installation et configuration du client OCS…" | tee -a $compte_rendu
        installer_un_paquet ocsinventory-agent
    else
        echo "${rouge}le paramètre ocs n'est pas à 1…${neutre}" | tee -a $compte_rendu
        # [gestion de cette erreur ? TODO]
    fi
}

recuperer_script_integration()
{
    echo "Telechargement de integration_xenial.bash..." | tee -a $compte_rendu
	mkdir -p /root/bin
	cd /root/bin
	wget http://${ip_se3}/install/integration_xenial.bash >/dev/null 2>&1
	if [ "$?" = "0" ]; then
		echo "Telechargement reussi." | tee -a $compte_rendu
		chmod +x integration_xenial.bash
	else
		echo "Echec du telechargement." | tee -a $compte_rendu
		echo "Le poste ne pourra pas être intégré au domaine" | tee -a $compte_rendu 
		ISCRIPT="erreur"
	fi   
    cd - >/dev/null
}

recuperer_nom_client()
{
    # on prend les adresses mac de toutes les cartes
    mac=$(ifconfig | grep HWaddr | awk -- '{ print $5 }')
    # on teste s'il y a ou non des adresses mac qui permettent de joindre l'annuaire
    if [ "$mac" = "" ]
    then
        # cas improbable…
        # il n'y a pas d'adresse mac : pas de carte réseau ?
        # étonnant si on a installé la machine via pxe…
        echo "Pas de carte réseau ?" | tee -a $compte_rendu
        # la machine doit être nommée : on entrera dans la boucle while ci-dessous…
    else
        # il y a au moins une carte réseau
        # on continue en inspectant les différentes addresses mac
        # jusqu'à en trouver une qui permet de joindre l'annuaire Ldap
        # normalement, ce devrait être la 1ère de la liste
        for i in $mac
        do
            lecture_annuaire=$(ldapsearch -xLLL macAddress=$i cn | grep "^cn: " | sed -e "s|^cn: ||" | head -n1)
            if [ -z "$lecture_annuaire" ]
            then
                # nom de la machine non trouvée dans l'annuaire ?
                # ou bien carte non branchée sur le réseau ?
                # ou bien… ?
                # on passe à la suivante
                # il faudra signaler le cas où aucune mention de nom pour le client n'est dans l'annuaire
                adresse=""
            else
                # on a pu joindre l'annuaire à l'aide de la carte réseau analysée
                adresse="1"
                echo "une adresse mac trouvée : $i" | tee -a $compte_rendu
                tab_nom_machine=($(ldapsearch -xLLL macAddress=$i cn | grep "^cn: " | sed -e "s|^cn: ||"))
                if [ "${#tab_nom_machine[*]}" = "1" ]
                then
                    # l'annuaire contient un nom et un seul
                    # on regarde la conformité du nom issu de l'annuaire
                    t=$(echo "${tab_nom_machine[0]}" | sed -e "s|[^A-Za-z0-9_\-]||g")
                    t2=$(echo "${tab_nom_machine[0]}" | sed -e "s|_|-|g")
                    if [ "$t" != "${tab_nom_machine[0]}" ]
                    then
                        echo "${orange}le nom de machine ${tab_nom_machine[0]} contient des caracteres invalides${neutre}" | tee -a $compte_rendu
                        # on va donc regarder l'éventuelle carte suivante de la liste
                        # et s'il n'y en a plus, on entrera dans la boucle while ci-desous
                        # pour choisir un nom de machine
                    elif [ "$t2" != "${tab_nom_machine[0]}" ]
                    then
                        echo "${orange}le nom de machine ${tab_nom_machine[0]} contient des ${jaune}_${orange} qui seront remplaces par des ${jaune}-${neutre}" | tee -a $compte_rendu
                        nom_machine="$t2"
                        echo "nouveau nom : $nom_machine" | tee -a $compte_rendu
                        sleep 2
                        # il faut sortir de la boucle
                        # on ne regarde pas les éventuelles cartes réseau suivantes de la liste
                        # faut-il quand même le faire ? [TODO]
                        continue
                    else
                        # le nom de l'annuaire est conforme : on le prend
                        nom_machine=${tab_nom_machine[0]}
                        echo "nom de machine trouvé dans l'annuaire LDAP : $nom_machine" | tee -a $compte_rendu
                        # il faut sortir de la boucle
                        # on ne regarde pas les éventuelles cartes réseau suivantes de la liste
                        # faut-il quand même le faire ? [TODO]
                        continue
                    fi
                else
                    # l'annuaire contient plusieurs noms pour la carte réseau
                    # on le signale mais on ne retient aucun nom de machine
                    echo "${rouge}Attention : l'adresse MAC ${neutre}${i}${rouge} est associée à plusieurs machines :${neutre}" | tee -a $compte_rendu
                    ldapsearch -xLLL macAddress=$i cn | grep "^cn: " | sed -e "s|^cn: ||"
                    # faut-il sortir de la boucle,
                    # sans regarder les éventuelles cartes réseau de la liste ? [TODO]
                fi
            fi
        done
    fi
    # on signale si aucune carte réseau n'a permis de trouver un nom
    if [ "$adresse" = "" ]
    then
        echo "${rouge}Attention : aucune carte réseau n'a permis de trouver un nom pour la machine${neutre}" | tee -a $compte_rendu
    fi
    # plusieurs cas possibles à envisager :
    #  cas où l'annuaire ne contient pas de nom de machine associé à une des cartes réseau de la machine
    #  cas où l'annuaire contient plusieurs noms de machine associés à une des cartes réseau de la machine
    #  cas où on n'a pu joindre un annuaire
    #  cas où il n'y a pas de carte réseau
    #  autres cas ?
    # dans tous ces cas, $nom_machine sera vide : il faut donner un nom…
    # par contre, si $nom_machine n'est pas vide,
    # on n'entre pas dans la boucle while ci-dessous
    while [ -z "$nom_machine" ]
    do
        echo -e "machine non connue de l'annuaire, Veuillez saisir un nom"
        echo -e "attention : espaces et _ sont interdits et 15 caractères maxi !"
        read nom_machine
        echo "nom de machine: $nom_machine"
        if [ -n "${nom_machine}" ]
        then
            # le nom récupéré commence-t-il par une lettre ?
            t=$(echo "${nom_machine:0:1}" | grep "[A-Za-z]")
            if [ -z "$t" ]
            then
                echo "le nom doit commencer par une lettre"
                nom_machine=""
            else
                # le nom récupéré contient-il des caractères non conformes ?
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
        echo -e "voulez-vous intégrer la machine $nom_machine au domaine SE3 ?"
        echo -e "sinon répondre n (attente de 10s…)"
        read -t 10 rep
        echo ""
    else
        echo -e "${rouge}$script d'intégration non présent…${neutre}$" | tee -a $compte_rendu
    fi
}

lancer_integration()
{
    echo "intégration du client-linux $nom_machine au domaine géré par le se3" | tee -a $compte_rendu
    cd /root/bin/
    ./integration_xenial.bash --nom-client="$nom_machine" --is --ivl | tee -a $compte_rendu 
    cd - >/dev/null
}

renommer_machine()
{
    echo "on n'intègre pas au domaine… mais renommage du poste → $nom_machine" | tee -a $compte_rendu 
    echo "$nom_machine" > "/etc/hostname"
    invoke-rc.d hostname.sh stop >/dev/null 2>&1
    invoke-rc.d hostname.sh start >/dev/null 2>&1
    cat > "/etc/hosts" <<END
    
    127.0.0.1    localhost
    127.0.1.1    $nom_machine
    
    # The following lines are desirable for IPv6 capable hosts
    ::1      ip6-localhost ip6-loopback
    fe00::0  ip6-localnet
    ff00::0  ip6-mcastprefix
    ff02::1  ip6-allnodes
    ff02::2  ip6-allrouters
    
END
    echo "Renommage termine."| tee -a $compte_rendu 
	echo "pour intégrer le poste plus tard : 
	cd /root/bin/
	./integration_xenial.bash --nom-client=\"$nom_machine\" --is --ivl" | tee -a $compte_rendu 
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
        verification_installation=$(aptitude search ^$paquet$ | cut -d" " -f1 | grep ^i)
        # si la variable est vide, le paquet n'est pas installé : il faut donc l'installer
        if [ -z "$verification_installation" ]
        then
            echo -e "${vert}On installe $paquet" | tee -a $compte_rendu
            echo -e "==========${neutre}" | tee -a $compte_rendu
            aptitude install -y "$paquet" >/dev/null #2>&1
            # on vérifie si l'installation s'est bien déroulée
            if [ "$?" != "0" ]
            then
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
        echo -e "installation des paquets définis dans ${bleu}${1}${neutre}" | tee -a $compte_rendu
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
    if [ -e "/etc/proxy.sh" ]
    then
        . /etc/proxy.sh
    fi
    # on recharge la liste des paquets
    echo "on recharge la liste des paquets"
    apt-get -q update
    # traitement des 3 listes de paquets
    test_applis=""
    [ -e "/root/bin/mesapplis-ubuntu.txt" ] && test_applis="1" && gerer_mesapplis mesapplis-ubuntu.txt
    [ -e "/root/bin/mesapplis-ubuntu-eb.txt" ] && test_applis="1" && gerer_mesapplis mesapplis-ubuntu-eb.txt
    [ -e "/root/bin/mesapplis-ubuntu-perso.txt" ] && test_applis="1" && gerer_mesapplis mesapplis-ubuntu-perso.txt
    if [ "$test_applis" = "" ]
    then
        echo -e "${rouge}aucune liste de paquets ?${neutre}" | tee -a $compte_rendu
    fi
    echo ""
}

configurer_grub()
{
    echo "configuration de grub…" | tee -a $compte_rendu
    # Virer l'entrée "mode de dépannage"
    sed -i '/GRUB_DISABLE_RECOVERY/ s/^#//' /etc/default/grub
    # resolution
    sed -i "/^GRUB_GFXMODE/ s/=.*/=1024x768 800x600 640x480/" /etc/default/grub 
    
    # dernier os lancé par défaut
    sed -i "/^GRUB_DEFAULT/ s/=.*/=saved/" /etc/default/grub 
    sed -i "/^GRUB_DEFAULT=saved/a\GRUB_SAVEDEFAULT=true" /etc/default/grub 
    
    sed 's|GRUB_CMDLINE_LINUX_DEFAULT="text"|GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"|' -i /etc/default/grub
    
    # mise en place du mot de passe crypté
    # Le fichier /etc/grub.d/40_custom existe déjà,
    # il faut le rééditer en partant de zéro.
    printf '#!/bin/sh\n'                                   >/etc/grub.d/40_custom
    printf 'exec tail -n +3 $0\n'                         >>/etc/grub.d/40_custom
    printf 'set superusers="admin"\n'                     >>/etc/grub.d/40_custom
    printf 'password_pbkdf2 admin %s\n' "$mdp_grub_crypt" >>/etc/grub.d/40_custom
    
    # Dans le fichier /etc/grub.d/10_linux, il faut chercher une ligne
    # spécifique qui va générer les entrées de boot Grub dite "simples"
    # (typiquement l'entrée de boot par défaut qui va lancer Jessie).
    # Au niveau de cette ligne, il faudra ajouter « --unrestricted ».
    # En effet, sans cela, par défaut avec seulement le compte "admin"
    # créé, aucun boot ne sera possible sans les identifiants du compte
    # admin (par exemple si on laisse le compteur de temps défiler, Grub
    # lancera le boot par défaut mais il demandera des identifiants pour
    # autoriser le boot ce qui n'est franchement pas pratique).
    pattern="'gnulinux-simple-\$boot_device_id'"
    # Si, au niveau de la ligne, l'option est déjà présente
    # alors on ne modifie pas le fichier. Sinon on le modifie.
    if ! grep -- "$pattern" /etc/grub.d/10_linux | grep -q -- '--unrestricted'
    then
        # Ajout de l'option « --unrestricted ».
        sed -i "s/$pattern/& --unrestricted/" /etc/grub.d/10_linux
    fi
    
    # On met à jour la configuration de Grub.
    if ! update-grub >> /dev/null 2>&1
    then
        echo -e "${jaune}Attention : ${neutre}la commande ${bleu}update-grub${neutre} ne s'est pas effectué correctement" | tee -a $compte_rendu
    fi
}

menage_script()
{
    [ "$rep" != "n" ] && mv /root/bin/integration_xenial.bash /root/bin/integration_xenial.bash.$ladate
    mv /root/bin/post-install_ubuntu.sh /root/bin/post-install_ubuntu.sh.$ladate
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
    echo ""
}

lancer_script_perso()
{
    cd /root/bin/
    wget -q http://${ip_se3}/install/messcripts_perso/monscript-perso.sh
    if [ "$?" = "0" ]
    then
        echo "lancement des scripts perso" | tee -a $compte_rendu
        bash monscript-perso.sh | tee -a $compte_rendu
    else
        echo "${rouge}échec du téléchargement des scripts perso${neutre}" | tee -a $compte_rendu
        # [gestion de cette erreur ? TODO]
    fi
    cd - >/dev/null
}

preconfigurer_ttf()
{

debconf-set-selections << 'EOF'
ttf-mscorefonts-installer	msttcorefonts/dldir	string	
#ttf-mscorefonts-installer	msttcorefonts/error-mscorefonts-eula	error	
ttf-mscorefonts-installer	msttcorefonts/dlurl	string	
#ttf-mscorefonts-installer	msttcorefonts/baddldir	error	
ttf-mscorefonts-installer	msttcorefonts/accepted-mscorefonts-eula	boolean	true
ttf-mscorefonts-installer	msttcorefonts/present-mscorefonts-eula	note
EOF

}

# Copie du skel se3 pour le compte local enseignant
maj_skel_compte_enseignant()
{
mkdir -p /home/enseignant/.config/dconf
cp -f /etc/se3/skel/.config/dconf/user /home/enseignant/.config/dconf/
chown -R enseignant:enseignant /home/enseignant/.config
chmod -R 770 /home/enseignant/.config
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
permettre_ssh_root
configurer_proxy
configurer_vim
configurer_ldap
configurer_ssmtp
configurer_ocs
recuperer_script_integration
recuperer_nom_client
integrer_domaine
[ "$rep" != "n" ] && lancer_integration
[ "$rep" = "n" ] && renommer_machine
maj_skel_compte_enseignant
preconfigurer_ttf
installer_liste_paquets
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
