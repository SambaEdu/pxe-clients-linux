#!/bin/bash

#####
# version 20151222
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

#####
# version des systèmes des clients-linux
# les autres seront effacés
#
version_debian="jessie"
version_ubuntu="trusty"

#####
# options des systèmes
# utiles pour récupérer un paramètre de l'interface web du se3
#
option_debian="oui"
option_ubuntu="oui"

#####
# url des dépôts
#
url_debian="ftp.fr.debian.org/debian"
url_ubuntu="archive.ubuntu.com/ubuntu"

#####
# variables
#
rep_tftp="tftpboot"
rep_temporaire="root/temp-linux"
archive_tftp="install_client_linux_archive-tftp"
ntp_serveur_defaut="ntp.ac-creteil.fr"
rep_client_linux="/home/netlogon/clients-linux"
# répertoire install et lien
rep_install="${rep_client_linux}/install"
rep_lien="/var/www/install"
# Chemin source → le répertoire où le script a été lancé
src="$(pwd)"
compte_rendu=/root/compte_rendu_install_client_linux_mise_en_place_${ladate}.txt

#=====
# Les fonctions
#=====

message_debut()
{
    echo -e "Compte-rendu de la mise en place de l'installation via pxe/preseed : $ladate" > $compte_rendu
    echo -e "${bleu}"
    echo -e "---------------"
    echo -e "Mise en place de l'installation via pxe/preseed"
    echo -e "---------------"
    echo -e "${neutre}"
}

verifier_version_serveur()
{
    if egrep -q "^6.0" /etc/debian_version
    then
        echo "la version de votre serveur est Debian Squeeze" | tee -a $compte_rendu
        echo "le script peut se poursuivre"
        echo ""
    elif egrep -q "^7.0" /etc/debian_version
    then
        echo "la version de votre serveur est Debian Wheezy" | tee -a $compte_rendu
        echo "le script peut se poursuivre"
        echo ""
    else
        echo "${rouge}votre serveur n'est pas en version Squeeze ou Wheezy." | tee -a $compte_rendu
        echo "opération annulée !${neutre}" | tee -a $compte_rendu
        echo ""
        exit 1
    fi
}

recuperer_variables_se3()
{
    # [ "$1" = "miroir-local" ] && MIROIR_LOCAL="yes"
    
    . /etc/se3/config_c.cache.sh
    . /etc/se3/config_d.cache.sh
    . /etc/se3/config_m.cache.sh
    . /etc/se3/config_l.cache.sh
    . /etc/se3/config_s.cache.sh
    
    # Pour recuperer la valeur MIROIR_LOCAL,... dans se3db
    . /etc/se3/config_o.cache.sh
    
    . /usr/share/se3/includes/functions.inc.sh 
    
    [ -e /root/debug ] && DEBUG="yes"
    
    # Lire la valeur de MIROIR_LOCAL et MIROIR_IP et CHEMIN_MIROIR dans la base MySQL ?
    MIROIR_LOCAL=$(echo "SELECT value FROM params WHERE name='MiroirAptCliLin';" | mysql -N $dbname -u$dbuser -p$dbpass)
    if [ "$MIROIR_LOCAL" = "yes" ]
    then
        MIROIR_IP=$(echo "SELECT value FROM params WHERE name='MiroirAptCliLinIP';" | mysql -N $dbname -u$dbuser -p$dbpass)
        CHEMIN_MIROIR=$(echo "SELECT value FROM params WHERE name='MiroirAptCliLinChem';" | mysql -N $dbname -u$dbuser -p$dbpass)
    fi
    CliLinNoPreseed=$(echo "SELECT value FROM params WHERE name='CliLinNoPreseed';" | mysql -N $dbname -u$dbuser -p$dbpass)
    CliLinXfce64=$(echo "SELECT value FROM params WHERE name='CliLinXfce64';" | mysql -N $dbname -u$dbuser -p$dbpass)
    CliLinLXDE=$(echo "SELECT value FROM params WHERE name='CliLinLXDE';" | mysql -N $dbname -u$dbuser -p$dbpass)
    CliLinGNOME=$(echo "SELECT value FROM params WHERE name='CliLinGNOME';" | mysql -N $dbname -u$dbuser -p$dbpass)
}

extraire_archive_tftp()
{
# ces archives comprennent les fichiers nécessaires à l'installation automatique : preseed,…
    echo "extraction de ${archive_tftp}.tar.gz." | tee -a $compte_rendu
    tar -xzf ./${archive_tftp}.tar.gz
    if [ "$?" != "0" ]
    then
        echo "${rouge}erreur lors de l'extraction de l'archive tftp ${archive_tftp}.tar.gz." | tee -a $compte_rendu
        echo "${neutre}" | tee -a $compte_rendu
        exit 1
    fi
    echo ""
}

installation_se3_clonage()
{
    # vérification de la présence du paquet se3-clonage
    if [ ! -e "/usr/share/se3/scripts/se3_pxe_menu_ou_pas.sh" ]
    then
        echo "installation du module Clonage" | tee -a $compte_rendu
        /usr/share/se3/scripts/install_se3-module.sh se3-clonage
        echo ""
    fi
}

installation_se3_clients_linux()
{
    # vérification de la présence du paquet client-linux
    if [ ! -e "${rep_client_linux}" ]
    then
        echo "installation du module client-linux" | tee -a $compte_rendu
        apt-get install se3-clients-linux -y --force-yes
        echo ""
    fi
}

droits_repertoires()
{
    echo "mise en place des répertoires $rep_install et $rep_lien" | tee -a $compte_rendu
    # rights fix and directories
    setfacl -m u:www-data:rx ${rep_client_linux}
    setfacl -m d:u:www-data:rx ${rep_client_linux}
    chmod 777 /tmp  # à supprimer ? [TODO]
    rm -rf $rep_install
    rm -rf $rep_lien
    mkdir -p $rep_install
    chmod 755 $rep_install
    chown root $rep_install
    ln -s $rep_install $rep_lien
    echo ""
}

verifier_presence_mkpasswd()
{
    # vérification de la présence de mkpasswd
    if [ ! -e "/usr/bin/mkpasswd" ]
    then
        apt-get install whois -y
    fi
}

mise_en_place_tftpboot()
{
    echo "vérification du répertoire /tftpboot…"
    # cas des anciennes versions : suppression de inst.wheezy.cfg (est remplacé par inst_debian.cfg)
    [ -e /${rep_tftp}/pxelinux.cfg/inst_wheezy.cfg ] && rm -f /${rep_tftp}/pxelinux.cfg/inst_wheezy.cfg
    # On vérifie si le menu Install fait référence ou non à debian-installer
    t1=$(grep "Installation Debian" /${rep_tftp}/tftp_modeles_pxelinux.cfg/menu/install.menu)
    if [ -z "$t1" ]
    then
        echo "on rajoute une entrée pour l'installation de Debian via pxe" | tee -a $compte_rendu
        cat >> /${rep_tftp}/tftp_modeles_pxelinux.cfg/menu/install.menu << END

LABEL Installation Debian
    MENU LABEL ^Installation Debian
    KERNEL menu.c32
    APPEND pxelinux.cfg/inst_debian.cfg

END
    fi
    
    t2=$(grep "Installation Ubuntu" /${rep_tftp}/tftp_modeles_pxelinux.cfg/menu/install.menu)
    if [ -z "$t2" ]
    then
        echo "on rajoute une entrée pour l'installation d'Ubuntu via pxe" | tee -a $compte_rendu
        cat >> /${rep_tftp}/tftp_modeles_pxelinux.cfg/menu/install.menu << END

LABEL Installation Ubuntu et xubuntu
    MENU LABEL ^Installation Ubuntu
    KERNEL menu.c32
    APPEND pxelinux.cfg/inst_buntu.cfg

END
    fi
    
    if [ -e /${rep_tftp}/pxelinux.cfg/install.menu ]
    then
        t1=$(grep "Installation Debian" /${rep_tftp}/pxelinux.cfg/install.menu)
        t2=$(grep "Installation Ubuntu" /${rep_tftp}/pxelinux.cfg/install.menu)
        if [ -z "$t1" -o -z "$t2" ]
        then
            cp /${rep_tftp}/pxelinux.cfg/install.menu /${rep_tftp}/pxelinux.cfg/install.menu.$ladate
            cp /${rep_tftp}/tftp_modeles_pxelinux.cfg/menu/install.menu /${rep_tftp}/pxelinux.cfg/
        fi
    else
        if [ ! -e "/${rep_tftp}/pxelinux.cfg/maintenance.menu" ]
        then
            echo "le menu d'installation Debian n'est proposée qu'avec le menu tftp semi-graphique." | tee -a $compte_rendu
            echo "configuration du mode semi-graphique"
            echo "mise en place du mot de passe temporaire ci-dessous pour accéder au menu maintenance"
            CHANGEMYSQL "tftp_pass_menu_pxe" "Linux" 
            echo "----> Linux <----- mis en place. À changer au plus vite depuis l'interface de configuration tftp"
            sleep 5
            /usr/share/se3/scripts/set_password_menu_tftp.sh Linux
        fi
    fi
    cp ${src}/${archive_tftp}/inst_debian.cfg ${src}/${archive_tftp}/inst_buntu.cfg /${rep_tftp}/pxelinux.cfg/
    echo ""
}

repertoire_temporaire()
{
    # on se met dans un répertoire temporaire
    echo -e "début de la mise en place ou de la mise à jour des fichiers netboot pour Debian/${version_debian} et/ou Ubuntu/${version_ubuntu}" | tee -a $compte_rendu
    echo -e "    * ce script concerne Debian/${version_debian} et/ou Ubuntu/${version_ubuntu}"
    echo -e "    * les versions précédentes seront supprimées"
    sleep 1s
    [ ! -e /${rep_temporaire} ] && mkdir /${rep_temporaire}
    cd /${rep_temporaire}
}

recuperer_somme_controle_depot()
{
    # 2 arguments :
    # $1 → debian ou ubuntu
    # $2 → i386 ou amd64
    #
    # on télécharge MD5SUMS
    eval url_dists='$'url_$1
    eval version='$'version_$1
    wget -q http://$url_dists/dists/$version/main/installer-$2/current/images/MD5SUMS
    if [ $? = "0" ]
    then
        # on récupère la somme de contrôle concernant les fichiers linux et initrd.gz
        eval somme_initrd_depot_${version}_$2=$(cat MD5SUMS | grep "./netboot/${1}-installer/$2/initrd.gz" | cut -f1 -d" ")
        eval somme_linux_depot_${version}_$2=$(cat MD5SUMS | grep "./netboot/${1}-installer/$2/linux" | cut -f1 -d" ")
        # on supprime le fichier récupéré
        rm -f MD5SUMS
    else
        echo -e "${rouge}échec de la récupération de MD5SUMS $1 $2${neutre}" | tee -a $compte_rendu
        sleep 2s
    fi
}

calculer_somme_controle_se3()
{
    # 2 arguments :
    # $1 → debian ou ubuntu
    # $2 → i386 ou amd64
    #
    eval version='$'version_$1
    if [ -e /${rep_tftp}/${1}-installer/$2/linux ] && [ -e /${rep_tftp}/${1}-installer/$2/initrd.gz ]
    then
        mise="mise à jour"
        # on calcule la somme de contrôle des fichiers linux et initrd.gz en place
        eval somme_initrd_se3_${version}_$2=$(md5sum /${rep_tftp}/${1}-installer/$2/initrd.gz | cut -f1 -d" ")
        eval somme_linux_se3_${version}_$2=$(md5sum /${rep_tftp}/${1}-installer/$2/linux | cut -f1 -d" ")
    else
        # il manque un fichier : on remettra $1-installer en place
        mise="mise en place"
        eval somme_initrd_se3_${version}_$2=""
        eval somme_linux_se3_${version}_$2=""
    fi
}

supprimer_fichiers()
{
    # 2 arguments :
    # $1 → debian ou ubuntu
    # $2 → i386 ou amd64
    #
    if [ -e /${rep_tftp}/${1}-installer/$2 ]
    then
        # on supprime le répertoire en place
        find /${rep_tftp}/${1}-installer/$2/ -delete
    fi
}

telecharger_archives()
{
    # 2 arguments :
    # $1 → debian ou ubuntu
    # $2 → i386 ou amd64
    #
    # téléchargement des archives debian/ubuntu 32 bits/64 bits
    eval url_dists='$'url_$1
    eval version='$'version_$1
    wget -q http://$url_dists/dists/$version/main/installer-$2/current/images/netboot/netboot.tar.gz -O netboot_${version}_${2}.tar.gz
}

extraire_archives_netboot()
{
    # 2 arguments :
    # $1 → debian ou ubuntu
    # $2 → i386 ou amd64
    #
    # extraction des archives
    eval version='$'version_$1
    tar -xzf netboot_${version}_${2}.tar.gz
}

mise_en_place_pxe()
{
    # 2 arguments :
    # $1 → debian ou ubuntu
    # $2 → i386 ou amd64
    #
    if [ ! -e /${rep_tftp}/${1}-installer ]
    then
        # le répertoire /${rep_tftp}/$1-installer n'étant pas en place, il faut le créer
        echo -e "on crée le répertoire /${rep_tftp}/${1}-installer" | tee -a $compte_rendu
        mkdir -p /${rep_tftp}/${1}-installer
    fi
    # on déplace le répertoire $2 de $1-installer vers /${rep_tftp}/$1-installer/
    mv ${1}-installer/$2/ /${rep_tftp}/${1}-installer/
}

mettre_se3_archives()
{
    # 2 arguments :
    # $1 → debian ou ubuntu
    # $2 → i386 ou amd64
    #
    # si les 2 sommes sont différentes, on supprime les anciens fichiers et on télécharge la nouvelle archive
    eval version='$'version_$1
    eval a='$'somme_initrd_se3_${version}_$2
    eval b='$'somme_initrd_depot_${version}_$2
    eval c='$'somme_linux_se3_${version}_$2
    eval d='$'somme_linux_depot_${version}_$2
    if [ "$a" != "$b" -o "$c" != "$d" ]
    then
        supprimer_fichiers $1 $2
        echo -e "téléchargement de l'archive netboot.tar.gz pour $1 $version $2" | tee -a $compte_rendu
        telecharger_archives $1 $2
        if [ $? = "0" ]
        then
            echo -e "extraction des fichiers netboot $1 $version $2" | tee -a $compte_rendu
            extraire_archives_netboot $1 $2
            echo -e "mise en place des fichiers netboot $1 $version $2" | tee -a $compte_rendu
            mise_en_place_pxe $1 $2
        else
            echo -e "${rouge}échec de la récupération de l'archive netboot.tar.gz pour $1 $version $2${neutre}" | tee -a $compte_rendu
            sleep 2s
        fi
    else
        echo -e "fichiers linux et initrd.gz en place pour $1 $version $2" | tee -a $compte_rendu
    fi
}

menage_netboot()
{
    # on revient dans le répertoire précédent
    # puis on supprime le répertoire temporaire
    rm -f pxe* ldl* ver*
    [ -e /${rep_temporaire}/debian-installer/ ] && find /${rep_temporaire}/debian-installer/ -delete
    [ -e /${rep_temporaire}/ubuntu-installer/ ] && find /${rep_temporaire}/ubuntu-installer/ -delete
    cd - >/dev/null
    find /${rep_temporaire}/ -delete
    # mise → "mise en place" ou "mise à jour" selon le cas : cf la fonction calculer_somme_controle_se3
    echo -e "fin de la $mise des fichiers netboot pour Debian/${version_debian} et Ubuntu/${version_ubuntu}" | tee -a $compte_rendu
    echo -e ""
}

transfert_repertoire_install()
{
    cp ${src}/${archive_tftp}/post-install* ${src}/${archive_tftp}/preseed*.cfg ${src}/${archive_tftp}/mesapplis*.txt ${src}/${archive_tftp}/bashrc ${src}/${archive_tftp}/autologin_debian.conf ${src}/${archive_tftp}/tty1.conf /var/remote_adm/.ssh/id_rsa.pub $rep_lien/
    # les fichiers gdm3 et lightdm serviront lors de la post-installation
    printf '#!/bin/sh\nwhile true\ndo\n    sleep 10\ndone\n' >$rep_lien/gdm3
    cp $rep_lien/gdm3 $rep_lien/lightdm
    chmod 755 $rep_lien/preseed* $rep_lien/post-install_debian.sh $rep_lien/gdm3 $rep_lien/lightdm
}

gestion_script_integration()
{
    if [ -e "${rep_client_linux}/distribs/${version_debian}/integration/integration_${version_debian}.bash" ]
    then
        rm -f $rep_lien/integration_${version_debian}.bash
        ln ${rep_client_linux}/distribs/${version_debian}/integration/integration_${version_debian}.bash $rep_lien/
        chmod 755 $rep_lien/integration_${version_debian}.bash
    fi
}

gestion_cles_publiques()
{
    rm -f /var/www/paquet_cles_pub_ssh.tar.gz
    if [ ! -e "/var/www/paquet_cles_pub_ssh.tar.gz" ]
    then
        echo "Génération d'un paquet de clés pub ssh d'aprés vos authorized_keys" | tee -a $compte_rendu
        cd /root/.ssh
        for fich_authorized_keys in authorized_keys authorized_keys2 $rep_lien/id_rsa.pub
        do
            if [ -e "$fich_authorized_keys" ]
            then
                while read A
                do
                    comment=$(echo "$A" | cut -d" " -f3)
                    if [ -n "$comment" -a ! -e "$comment.pub" ]; then
                        echo "$A" > $comment.pub
                    fi
                done < $fich_authorized_keys
            fi
        done
        tar -czf /var/www/paquet_cles_pub_ssh.tar.gz *.pub
        echo ""
    fi
}

gestion_fichiers_tftp()
{
    CRYPTPASS="$(echo "$xppass" | mkpasswd -s -m md5)"
    [ -z "$ntpserv" ] && ntpserv="$ntp_serveur_defaut"
    
    echo "correction des fichiers TFTP inst_buntu.cfg et inst_debian.cfg pour ajout IP du Se3" | tee -a $compte_rendu
    sed -i "s|###_IP_SE3_###|$se3ip|g" /${rep_tftp}/pxelinux.cfg/inst_debian.cfg
    sed -i "s|###_IP_SE3_###|$se3ip|g" /${rep_tftp}/pxelinux.cfg/inst_buntu.cfg
    
    echo "correction des fichiers TFTP inst_debian.cfg pour ajout version debian" | tee -a $compte_rendu
    sed -i "s|###_DEBIAN_###|${version_debian}|g" /${rep_tftp}/pxelinux.cfg/inst_debian.cfg
    
    echo "correction des fichiers TFTP inst_debian.cfg pour ajout domaine" | tee -a $compte_rendu
    sed -i "s|###_DOMAINE_###|$dhcp_domain_name|g" /${rep_tftp}/pxelinux.cfg/inst_debian.cfg
    
    [ "$CliLinNoPreseed" = "yes" ] && sed -i "s|^#INSTALL_LIBRE_SANS_PRESEED||" /${rep_tftp}/pxelinux.cfg/inst_debian.cfg
    [ "$CliLinNoPreseed" = "yes" ] && sed -i "s|^#INSTALL_LIBRE_SANS_PRESEED||" /${rep_tftp}/pxelinux.cfg/inst_buntu.cfg
    
    [ "$CliLinXfce64" = "yes" ] && sed -i "s|^#XFCE64||" /${rep_tftp}/pxelinux.cfg/inst_debian.cfg
    [ "$CliLinXfce64" = "yes" ] && sed -i "s|^#XFCE64||" /${rep_tftp}/pxelinux.cfg/inst_buntu.cfg
    
    [ "$CliLinLXDE" = "yes" ] && sed -i "s|^#LXDE||" /${rep_tftp}/pxelinux.cfg/inst_debian.cfg
    [ "$CliLinLXDE" = "yes" ] && sed -i "s|^#LXDE||" /${rep_tftp}/pxelinux.cfg/inst_buntu.cfg
    
    [ "$CliLinGNOME" = "yes" ] && sed -i "s|^#GNOME||" /${rep_tftp}/pxelinux.cfg/inst_debian.cfg
    [ "$CliLinGNOME" = "yes" ] && sed -i "s|^#GNOME||" /${rep_tftp}/pxelinux.cfg/inst_buntu.cfg
    echo ""
}

gestion_miroir()
{
    if [ "$MIROIR_LOCAL" != "yes" ]
    then
        if [ ! -e /etc/apt-cacher-ng ]
        then
            echo "installation et configuration de apt-cacher-ng pour se3" | tee -a $compte_rendu
            echo "Le cache sera dans /var/se3/apt-cacher-ng"
            apt-get install apt-cacher-ng -y
            rm -f /etc/apt-cacher-ng/acng.conf.*
            mv /etc/apt-cacher-ng/acng.conf /etc/apt-cacher-ng/acng.conf.$ladate
            cat > /etc/apt-cacher-ng/acng.conf <<END
CacheDir: /var/se3/apt-cacher-ng
LogDir: /var/log/apt-cacher-ng
Port:9999
Remap-debrep: file:deb_mirror*.gz /debian ; file:backends_debian
Remap-uburep: file:ubuntu_mirrors /ubuntu ; file:backends_ubuntu
Remap-debvol: file:debvol_mirror*.gz /debian-volatile ; file:backends_debvol
Remap-cygwin: file:cygwin_mirrors /cygwin # ; file:backends_cygwin # incomplete, please create this file
ReportPage: acng-report.html
VerboseLog: 1
ExTreshold: 4
END
            # sécurisation accés admin pass adminse3
            echo "AdminAuth: admin:$xppass" > /etc/apt-cacher-ng/security.conf
            chown apt-cacher-ng:apt-cacher-ng /etc/apt-cacher-ng/security.conf
            chmod 600 /etc/apt-cacher-ng/security.conf
            
            # config propre ubuntu
            echo "http://fr.archive.ubuntu.com/ubuntu/" > /etc/apt-cacher-ng/backends_ubuntu
            
            if [ ! -e /var/se3/apt-cacher-ng ]
            then 
                mv /var/cache/apt-cacher-ng /var/se3/
            fi
            service apt-cacher-ng restart
            echo ""
        fi
        echo "correction des fichiers de preseed ${version_debian}" | tee -a $compte_rendu
        for i in $(ls $rep_lien/preseed*.cfg)
        do
            sed -i "s|###_IP_SE3_###|$se3ip|g" $i
            sed -i "s|###_PASS_ROOT_###|$CRYPTPASS|g" $i
            sed -i "s|###_NTP_SERV_###|$ntpserv|g" $i
            sed -i "s|###_DEBIAN_###|$version_debian|g" $i
            sed -i "s|###_DOMAINE_###|$dhcp_domain_name|g" $i
        done
    else
        if [ -z "$MIROIR_IP" -o -z "$CHEMIN_MIROIR" ]
        then
            echo "--- Adresse du miroir ?"
            read MIROIR_IP
            echo "--- Chemin dans le miroir ?"
            read CHEMIN_MIROIR
        fi
        echo ""
        echo "correction des fichiers de preseed debian ${version_debian}" | tee -a $compte_rendu
        
        for i in $(ls $rep_lien/preseed*.cfg)
        do
            sed -i "s|###_IP_SE3_###:9999|$MIROIR_IP|g" $i
            sed -i "s|###_IP_SE3_###|$se3ip|g" $i
            sed -i "s|/debian|$CHEMIN_MIROIR|g" $i
            sed -i "s|###_PASS_ROOT_###|$CRYPTPASS|g" $i
            sed -i "s|###_NTP_SERV_###|$ntpserv|g" $i
            sed -i "s|###_DEBIAN_###|$version_debian|g" $i
            sed -i "s|###_DOMAINE_###|$dhcp_domain_name|g" $i
        done
    fi
    echo "correction des fichiers post-install $version_debian" | tee -a $compte_rendu
    for i in $(ls $rep_lien/post-install*)
    do
        sed -i "s|###_DEBIAN_###|$version_debian|g" $i
    done
    echo "correction du fichier bashrc" | tee -a $compte_rendu
    sed -i "s|###_DEBIAN_###|$version_debian|g" $rep_lien/bashrc
}

fichier_parametres()
{
    email=$(grep "^root=" /etc/ssmtp/ssmtp.conf | cut -d"=" -f2)
    if [ -z "$email" ]
    then
        email=root
    fi
    
    mailhub=$(grep "^mailhub=" /etc/ssmtp/ssmtp.conf | cut -d"=" -f2)
    if [ -z "$mailhub" ]
    then
        mailhub=mail
    fi
    
    rewriteDomain=$(grep "^rewriteDomain=" /etc/ssmtp/ssmtp.conf | cut -d"=" -f2)
    if [ -z "$rewriteDomain" ]
    then
        rewriteDomain=$dhcp_domain_name
    fi
    
    tmp_proxy=$(cat /etc/profile | grep http_proxy= | cut -d= -f2 | sed -e 's|"||g' | sed -e "s|.*//||")
    ip_proxy=$(echo "$tmp_proxy" | cut -d":" -f1)
    port_proxy=$(echo "$tmp_proxy" | cut -d":" -f2)
    
    echo "génération du fichier de paramètres $rep_lien/params.sh" | tee -a $compte_rendu
    cat > $rep_lien/params.sh << END
email="$email"
mailhub="$mailhub"
rewriteDomain="$rewriteDomain"

# Parametres Proxy :
ip_proxy="$ip_proxy"
port_proxy="$port_proxy"

# Parametres SE3 :
ip_se3="$se3ip"
nom_se3="$(hostname)"
nom_domaine="$dhcp_domain_name"
ocs="$inventaire"

# Parametres LDAP :
ip_ldap="$ldap_server"
ldap_base_dn="$ldap_base_dn"
END
    chmod 755 $rep_lien/params.sh
    echo ""
}

gestion_scripts_unefois()
{
    # voir la doc du paquet se3-clients-linux pour le rôle du fichier PAUSE
    [ -e ${rep_client_linux}/unefois/PAUSE ] && mv ${rep_client_linux}/unefois/PAUSE ${rep_client_linux}/unefois/NO-PAUSE
    
    # l'archive contient des scripts unefois à mettre en place pour tous les clients
    # sont-ils nécessaires ? Voir les fonctions cles_publiques_ssh et configurer_ocs du script de post-installation
    cp -r ${src}/${archive_tftp}/unefois/* ${rep_client_linux}/unefois/
    
    # [TODO → en attente de modification ou de suppression des 2 lignes suivantes]
    #cp ${rep_client_linux}/bin/logon_perso ${rep_client_linux}/bin/logon_perso-$ladate
    #sed -i -r '/initialisation_perso[[:space:]]*\(\)/,/^\}/s/^([[:space:]]*)true/\1activer_pave_numerique/' ${rep_client_linux}/bin/logon_perso
    
    # gestion du répertoire ^.
    if [ ! -e ${rep_client_linux}/unefois/\^\. ]
    then
        # ^. n'existe pas : on renomme all en ^.
        mv ${rep_client_linux}/unefois/all ${rep_client_linux}/unefois/\^\.
    else
        # ^. existe : on copie le contenu de all dans ^. puis on supprime all
        cp ${rep_client_linux}/unefois/all/* ${rep_client_linux}/unefois/\^\./
        rm -rf ${rep_client_linux}/unefois/all
    fi 
    # gestion du répertoire ^* : remplacé par ^.
    [ -e ${rep_client_linux}/unefois/\^\* ] && mv ${rep_client_linux}/unefois/\^\*/*  ${rep_client_linux}/unefois/\^\./
    rm -rf ${rep_client_linux}/unefois/\^\*
}

gestion_profil_skel()
{
# pourquoi ce test concernant update-mozilla-profile ? [TODO]
    if [ -e ${src}/update-mozilla-profile ]
    then
        echo "gestion du profil skel de la distribution"
        rm -rf ${rep_client_linux}/distribs/${version_debian}/skel/.mozilla
        echo  "modif install_client_linux_archive - $ladate" > ${rep_client_linux}/distribs/${version_debian}/skel/.VERSION | tee -a $compte_rendu
    fi
    # normalement, si le paquet se3-clients-linux est installé, on devrait avoir .config dans le skel
    if [ ! -e ${rep_client_linux}/distribs/${version_debian}/skel/.config ]
    then
        echo "skel : mise en place de .config"
        cp -r ${src}/.config ${rep_client_linux}/distribs/${version_debian}/skel/
    fi
    # même remarque que ci-dessus… sauf si présence de update-mozilla-profile
    if [ ! -e ${rep_client_linux}/distribs/${version_debian}/skel/.mozilla ]
    then
        echo "skel : mise en place de .mozilla"
        cp -r ${src}/.mozilla ${rep_client_linux}/distribs/${version_debian}/skel/
        prefsjs="/etc/skel/user/profil/appdata/Mozilla/Firefox/Profiles/default/prefs.js"
        if [ -e $prefsjs ]
        then
            echo "skel : utilisation de $prefsjs"
            rm -f ${rep_client_linux}/distribs/${version_debian}/skel/.mozilla/firefox/default/prefs.js-save*
            mv ${rep_client_linux}/distribs/${version_debian}/skel/.mozilla/firefox/default/prefs.js ${rep_client_linux}/distribs/${version_debian}/skel/.mozilla/firefox/default/prefs.js-save-$ladate
            cp $prefsjs ${rep_client_linux}/distribs/${version_debian}/skel/.mozilla/firefox/default/
        fi
    fi
}

reconfigurer_module()
{
    echo "on lance la reconfiguration du module clients-linux" | tee -a $compte_rendu
    bash ${rep_client_linux}/.defaut/reconfigure.bash
}

message_fin()
{
    echo -e "${bleu}"
    echo "---------------"
    echo -e "L'installation via pxe/preseed est en place" | tee -a $compte_rendu
    echo -e "---------------${neutre}"
    echo "" | tee -a $compte_rendu
}

#=====
# Fin des fonctions
#=====

#####
# début du programme
#
message_debut
verifier_version_serveur
recuperer_variables_se3
extraire_archive_tftp
installation_se3_clonage
installation_se3_clients_linux
droits_repertoires
verifier_presence_mkpasswd
mise_en_place_tftpboot
# on crée un répertoire temporaire
repertoire_temporaire
# sommes de contrôle des fichiers des dépôts
# i386 → 32 bits
# amd64 → 64 bits
[ $option_debian = "oui" ] && recuperer_somme_controle_depot debian i386
[ $option_debian = "oui" ] && recuperer_somme_controle_depot debian amd64
[ $option_ubuntu = "oui" ] && recuperer_somme_controle_depot ubuntu i386
# il y a un probleme sur la somme de controle disponible sur le dépôt amd64: à confirmer [TODO]
[ $option_ubuntu = "oui" ] && recuperer_somme_controle_depot ubuntu amd64
# sommes de contrôle des fichiers en place sur le se3 (vides la première fois)
[ $option_debian = "oui" ] && calculer_somme_controle_se3 debian i386
[ $option_debian = "oui" ] && calculer_somme_controle_se3 debian amd64
[ $option_ubuntu = "oui" ] && calculer_somme_controle_se3 ubuntu i386
[ $option_ubuntu = "oui" ] && calculer_somme_controle_se3 ubuntu amd64
# on met à jour si nécessaire (mise en place la première fois)
[ $option_debian = "oui" ] && mettre_se3_archives debian i386
[ $option_debian = "oui" ] && mettre_se3_archives debian amd64
[ $option_ubuntu = "oui" ] && mettre_se3_archives ubuntu i386
[ $option_ubuntu = "oui" ] && mettre_se3_archives ubuntu amd64
# on supprime le répertoire temporaire
menage_netboot
transfert_repertoire_install
gestion_script_integration
gestion_cles_publiques
gestion_fichiers_tftp
gestion_miroir
fichier_parametres
gestion_scripts_unefois
gestion_profil_skel
reconfigurer_module
message_fin
#
# fin du programme
#####
