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
depot_firmware_debian="cdimage.debian.org/cdimage/unofficial/non-free/firmware"

#####
# variables
#
rep_tftp="/tftpboot"
archive_tftp="install_client_linux_archive-tftp"
ntp_serveur_defaut="ntp.ac-creteil.fr"
mdp_ens_defaut="enseignant"
rep_client_linux="/home/netlogon/clients-linux"
rep_temp="${rep_client_linux}/temp-linux"
rep_temporaire_depot="$rep_tftp/temp-depot"
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
        echo "la version de votre serveur se3 est Debian Squeeze" | tee -a $compte_rendu
        echo "le script peut se poursuivre"
        echo ""
    elif egrep -q "^7." /etc/debian_version
    then
        echo "la version de votre serveur se3 est Debian Wheezy" | tee -a $compte_rendu
        echo "le script peut se poursuivre"
        echo ""
    else
        echo "${rouge}votre serveur se3 n'est pas en version Squeeze ou Wheezy." | tee -a $compte_rendu
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
    
    [ -e "/root/debug" ] && DEBUG="yes"
    
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
    # on supprime le répertoire ${archive_tftp} avant de décompresser l'archive
    [ -e "${archive_tftp}" ] && rm -rf ${archive_tftp}
    echo "extraction de ${archive_tftp}.tar.gz" | tee -a $compte_rendu
    tar -xzf ./${archive_tftp}.tar.gz
    if [ "$?" != "0" ]
    then
        echo "${rouge}erreur lors de l'extraction de l'archive tftp ${archive_tftp}.tar.gz" | tee -a $compte_rendu
        echo "${neutre}" | tee -a $compte_rendu
        # [gestion de cette erreur ? TODO]
        exit 2
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

gerer_repertoires()
{
    echo "mise en place des répertoires $rep_install et $rep_lien" | tee -a $compte_rendu
    # rights fix and directories
    setfacl -m u:www-data:rx ${rep_client_linux}
    setfacl -m d:u:www-data:rx ${rep_client_linux}
    [ ! -e "${rep_temp}" ] && mkdir ${rep_temp}
    # on préserve la liste des applis perso
    if [ -e "$rep_install/mesapplis-debian-perso.txt" ]
    then
        mv $rep_install/mesapplis-debian-perso.txt ${rep_temp}/
    fi
    # on préserve le répertoire des scripts perso
    if [ -e "$rep_install/messcripts_perso" ]
    then
        mv $rep_install/messcripts_perso ${rep_temp}/
    fi
    # on supprime le répertoire install et le lien vers /var/www/
    rm -rf $rep_install
    rm -rf $rep_lien
    # on crée le répertoire install et le lien vers /var/www/
    mkdir -p $rep_install
    chmod 755 $rep_install
    chown root $rep_install
    ln -s $rep_install $rep_lien
    # on remet en place la liste des applis perso
    if [ -e "${rep_temp}/mesapplis-debian-perso.txt" ]
    then
        mv ${rep_temp}/mesapplis-debian-perso.txt $rep_install/
    fi
    # et le répertoire des scripts perso
    if [ -e "${rep_temp}/messcripts_perso" ]
    then
        mv ${rep_temp}/messcripts_perso $rep_install/
    fi
    echo ""
    # on supprime le répertoire temporaire
    find ${rep_temp}/ -delete
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
    [ -e "${rep_tftp}/pxelinux.cfg/inst_wheezy.cfg" ] && rm -f ${rep_tftp}/pxelinux.cfg/inst_wheezy.cfg
    # On vérifie si le menu Install fait référence ou non à debian-installer
    t1=$(grep "Installation Debian" ${rep_tftp}/tftp_modeles_pxelinux.cfg/menu/install.menu)
    if [ -z "$t1" ]
    then
        echo "on rajoute une entrée pour l'installation de Debian via pxe" | tee -a $compte_rendu
        cat >> ${rep_tftp}/tftp_modeles_pxelinux.cfg/menu/install.menu << END

LABEL Installation Debian
    MENU LABEL ^Installation Debian
    KERNEL menu.c32
    APPEND pxelinux.cfg/inst_debian.cfg

END
    fi
    
    t2=$(grep "Installation Ubuntu" ${rep_tftp}/tftp_modeles_pxelinux.cfg/menu/install.menu)
    if [ -z "$t2" ]
    then
        echo "on rajoute une entrée pour l'installation d'Ubuntu via pxe" | tee -a $compte_rendu
        cat >> ${rep_tftp}/tftp_modeles_pxelinux.cfg/menu/install.menu << END

LABEL Installation Ubuntu
    MENU LABEL ^Installation Ubuntu
    KERNEL menu.c32
    APPEND pxelinux.cfg/inst_buntu.cfg

END
    fi
    
    if [ -e "${rep_tftp}/pxelinux.cfg/install.menu" ]
    then
        t1=$(grep "Installation Debian" ${rep_tftp}/pxelinux.cfg/install.menu)
        t2=$(grep "Installation Ubuntu" ${rep_tftp}/pxelinux.cfg/install.menu)
        if [ -z "$t1" -o -z "$t2" ]
        then
            cp ${rep_tftp}/pxelinux.cfg/install.menu ${rep_tftp}/pxelinux.cfg/install.menu.$ladate
            cp ${rep_tftp}/tftp_modeles_pxelinux.cfg/menu/install.menu ${rep_tftp}/pxelinux.cfg/
        fi
    else
        if [ ! -e "${rep_tftp}/pxelinux.cfg/maintenance.menu" ]
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
    cp ${src}/${archive_tftp}/inst_debian.cfg ${src}/${archive_tftp}/inst_buntu.cfg ${rep_tftp}/pxelinux.cfg/
    echo ""
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
    if [ "$?" = "0" ]
    then
        # on récupère la somme de contrôle concernant l'archive netboot.tar.gz
        eval somme_netboot_depot_${version}_$2=$(cat MD5SUMS | grep "./netboot/netboot.tar.gz" | cut -f1 -d" ")
        # on supprime le fichier récupéré
        rm -f MD5SUMS
    else
        echo -e "${rouge}échec de la récupération de MD5SUMS $1 $2${neutre}" | tee -a $compte_rendu
        # [gestion de cette erreur ? TODO]
        eval erreur_md5sums_$1_$2="1"
    fi
}

calculer_somme_controle_se3()
{
    # 2 arguments :
    # $1 → debian ou ubuntu
    # $2 → i386 ou amd64
    #
    eval version='$'version_$1
    if [ -e "${rep_tftp}/${1}-installer/netboot_${version}_${2}.tar.gz" ]
    then
        mise="mise à jour"
        # on calcule la somme de contrôle de l'archive précédemment sauvegardée
        eval somme_netboot_se3_${version}_$2=$(md5sum ${rep_tftp}/${1}-installer/netboot_${version}_${2}.tar.gz | cut -f1 -d" ")
    else
        # il manque l'archive précédente : on remettra $1-installer en place
        mise="mise en place"
        eval somme_netboot_se3_${version}_$2=""
    fi
}

supprimer_fichiers()
{
    # 2 arguments :
    # $1 → debian ou ubuntu
    # $2 → i386 ou amd64
    #
    if [ -e "${rep_tftp}/${1}-installer/$2" ]
    then
        # on supprime le répertoire en place
        find ${rep_tftp}/${1}-installer/$2/ -delete
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
    wget http://$url_dists/dists/$version/main/installer-$2/current/images/netboot/netboot.tar.gz -O netboot_${version}_${2}.tar.gz
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
    # on sauvegarde l'archive pour tester sa somme de contrôle lors d'une prochaine remise en place du dispositif
    mv netboot_${version}_${2}.tar.gz ${rep_tftp}/${1}-installer/netboot_${version}_${2}.tar.gz
}

mise_en_place_pxe()
{
    # 2 arguments :
    # $1 → debian ou ubuntu
    # $2 → i386 ou amd64
    #
    if [ ! -e "${rep_tftp}/${1}-installer" ]
    then
        # le répertoire ${rep_tftp}/$1-installer n'étant pas en place, il faut le créer
        echo -e "on crée le répertoire ${rep_tftp}/${1}-installer" | tee -a $compte_rendu
        mkdir -p ${rep_tftp}/${1}-installer
    fi
    # on déplace le répertoire $2 de $1-installer vers ${rep_tftp}/$1-installer/
    mv ${1}-installer/$2/ ${rep_tftp}/${1}-installer/
}

placer_se3_archives()
{
    # 2 arguments :
    # $1 → debian ou ubuntu
    # $2 → i386 ou amd64
    #
    # si les 2 sommes sont différentes, on supprime les anciens fichiers et on télécharge la nouvelle archive
    # de même si les répertoires amd64 ou i386 sont absents
    eval version='$'version_$1
    eval a='$'somme_netboot_se3_${version}_$2
    eval b='$'somme_netboot_depot_${version}_$2
    if [ "$a" != "$b" -o ! -e "${rep_tftp}/${1}-installer/$2" ]
    then
        supprimer_fichiers $1 $2
        echo -e "téléchargement de l'archive netboot.tar.gz pour $1 $version $2" | tee -a $compte_rendu
        telecharger_archives $1 $2
        if [ "$?" = "0" ]
        then
            echo -e "extraction des fichiers netboot $1 $version $2" | tee -a $compte_rendu
            extraire_archives_netboot $1 $2
            echo -e "mise en place des fichiers netboot $1 $version $2" | tee -a $compte_rendu
            mise_en_place_pxe $1 $2
            [ "$1" = "debian" ] && [ "$2" = "i386" ] && drapeau_initrd_i386="1"
            [ "$1" = "debian" ] && [ "$2" = "amd64" ] && drapeau_initrd_amd64="1"
        else
            echo -e "${rouge}échec de la récupération de l'archive netboot.tar.gz pour $1 $version $2${neutre}" | tee -a $compte_rendu
            # [gestion de cette erreur ? TODO]
            return 1
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
    [ -e "${rep_temporaire_depot}/debian-installer/" ] && find ${rep_temporaire_depot}/debian-installer/ -delete
    [ -e "${rep_temporaire_depot}/ubuntu-installer/" ] && find ${rep_temporaire_depot}/ubuntu-installer/ -delete
    cd - >/dev/null
    find ${rep_temporaire_depot}/ -delete
    # mise → "mise en place" ou "mise à jour" selon le cas : cf la fonction calculer_somme_controle_se3
    echo -e "fin de la $mise des fichiers netboot pour Debian/${version_debian} et Ubuntu/${version_ubuntu}" | tee -a $compte_rendu
    echo -e ""
}

gestion_netboot()
{
    echo -e "début de la mise en place ou de la mise à jour des fichiers netboot" | tee -a $compte_rendu
    echo -e "→ distributions disponibles : Debian/${version_debian} et/ou Ubuntu/${version_ubuntu}"
    echo -e "→ les versions précédentes seront supprimées"
    sleep 1s
    # on se met dans un répertoire temporaire
    [ ! -e "${rep_temporaire_depot}" ] && mkdir ${rep_temporaire_depot}
    cd ${rep_temporaire_depot}
    # sommes de contrôle des fichiers des dépôts
    # i386 → 32 bits
    # amd64 → 64 bits
    [ $option_debian = "oui" ] && recuperer_somme_controle_depot debian i386
    [ $option_debian = "oui" ] && recuperer_somme_controle_depot debian amd64
    [ $option_ubuntu = "oui" ] && recuperer_somme_controle_depot ubuntu i386
    [ $option_ubuntu = "oui" ] && recuperer_somme_controle_depot ubuntu amd64
    # sommes de contrôle des fichiers en place sur le se3 (vides la première fois)
    [ $option_debian = "oui" ] && calculer_somme_controle_se3 debian i386
    [ $option_debian = "oui" ] && calculer_somme_controle_se3 debian amd64
    [ $option_ubuntu = "oui" ] && calculer_somme_controle_se3 ubuntu i386
    [ $option_ubuntu = "oui" ] && calculer_somme_controle_se3 ubuntu amd64
    # on met à jour si nécessaire (mise en place la première fois) et s'il n'y a pas d'erreur de téléchargement
    [ $option_debian = "oui" ] && [ $erreur_md5sums_debian_i386 = "" ] && placer_se3_archives debian i386
    [ $option_debian = "oui" ] && [ $erreur_md5sums_debian_amd64 = "" ] && placer_se3_archives debian amd64
    [ $option_ubuntu = "oui" ] && [ $erreur_md5sums_ubuntu_i386 = "" ] && placer_se3_archives ubuntu i386
    [ $option_ubuntu = "oui" ] && [ $erreur_md5sums_ubuntu_amd64 = "" ] && placer_se3_archives ubuntu amd64
    # on supprime le répertoire temporaire
    menage_netboot
}

recuperer_somme_controle_firmware_depot_debian()
{
    wget -q http://$depot_firmware_debian/$version_debian/current/MD5SUMS
    if [ "$?" = "0" ]
    then
        # on récupère la somme de contrôle concernant les firmwares
        eval somme_firmware_depot_${version_debian}=$(cat MD5SUMS | grep "firmware.cpio.gz" | cut -f1 -d" ")
        # on supprime le fichier récupéré
        rm -f MD5SUMS
    else
        echo -e "${rouge}échec de la récupération de MD5SUMS des firmwares Debian ${version_debian}{neutre}" | tee -a $compte_rendu
        # [gestion de cette erreur ? TODO]
        return 1
    fi
}

calculer_somme_controle_firmware_se3_debian()
{
    if [ -e "${rep_tftp}/debian-installer/firmware.cpio.gz" ]
    then
        mise="mise à jour"
        # on calcule la somme de contrôle concernant les firmwares en place
        eval somme_firmware_se3_${version_debian}=$(md5sum ${rep_tftp}/debian-installer/firmware.cpio.gz | cut -f1 -d" ")
    else
        # il manque firmware.cpio.gz : à mettre en place
        mise="mise en place"
        eval somme_firmware_se3_${version_debian}=""
    fi
}

supprimer_firmware_debian()
{
    if [ -e "${rep_tftp}/debian-installer/firmware.cpio.gz" ]
    then
        # on supprime l'archive en place
        find ${rep_tftp}/debian-installer/firmware.cpio.gz -delete
    fi
}

telecharger_firmware_debian()
{
    # on télécharge les firmwares : aussi bien pour i386 que amd64
    wget http://$depot_firmware_debian/$version_debian/current/firmware.cpio.gz -O ${rep_tftp}/debian-installer/firmware.cpio.gz
    if [ "$?" != "0" ]
    then
        echo -e "${rouge}échec du téléchargement des firmwares Debian ${version_debian}{neutre}" | tee -a $compte_rendu
        # [gestion de cette erreur ? TODO]
        return 1
    fi
}

incorporer_firmware_debian()
{
    # 1 argument :
    # $1 → i386 ou amd64
    if [ -e "${rep_tftp}/debian-installer/$1/initrd.gz" ]
    then
        # méthode valable à partir de jessie
        cp -p ${rep_tftp}/debian-installer/$1/initrd.gz ${rep_tftp}/debian-installer/$1/initrd.gz.orig
        cat ${rep_tftp}/debian-installer/$1/initrd.gz.orig ${rep_tftp}/debian-installer/firmware.cpio.gz > ${rep_tftp}/debian-installer/$1/initrd.gz
        rm -f ${rep_tftp}/debian-installer/$1/initrd.gz.orig
        echo -e "firmwares Debian incorporés à initrd.gz $1" | tee -a $compte_rendu
    else
        echo -e "${rouge}il manque le fichier initrd.gz Debian ${version_debian} pour $1 ?{neutre}" | tee -a $compte_rendu
        # [gestion de cette erreur ? TODO]
        return 1
    fi
    
}

gerer_firmware_debian()
{
    eval a='$'somme_firmware_se3_${version_debian}
    eval b='$'somme_firmware_depot_${version_debian}
    if [ "$a" != "$b" ]
    then
        supprimer_firmware_debian
        echo -e "téléchargement des firmwares pour Debian ${version_debian}" | tee -a $compte_rendu
        telecharger_firmware_debian
        if [ "$?" = "0" ]
        then
            # les firmwares ayant changés, on incorpore les firmwares aux fichiers initrd.gz
            incorporer_firmware_debian i386
            incorporer_firmware_debian amd64
        fi
    else
        # les firmwares n'ont pas changés
        # les fichiers initrd.gz ont-ils changé ?
        [ "$drapeau_initrd_i386" != "" ] && incorporer_firmware_debian i386
        [ "$drapeau_initrd_amd64" != "" ] && incorporer_firmware_debian amd64
        [ "$drapeau_initrd_i386" = "" ] && [ "$drapeau_initrd_amd64" = "" ] && echo -e "firmwares déjà en place pour Debian ${version_debian}" | tee -a $compte_rendu
    fi
    echo ""
}

gestion_firmware_debian()
{
    # pour debian uniquement
    recuperer_somme_controle_firmware_depot_debian
    if [ "$?" = "0" ]
    then
        calculer_somme_controle_firmware_se3_debian
        gerer_firmware_debian
    fi
}

transfert_repertoire_install()
{
    # on met en place les fichiers dans le répertoire install sans écraser ni la liste des applis perso, ni le répertoire des scripts perso
    cp -n -r ${src}/${archive_tftp}/post-install* ${src}/${archive_tftp}/preseed*.cfg ${src}/${archive_tftp}/mesapplis*.txt ${src}/${archive_tftp}/messcripts_perso ${src}/${archive_tftp}/bashrc ${src}/${archive_tftp}/autologin_debian.conf ${src}/${archive_tftp}/tty1.conf /var/remote_adm/.ssh/id_rsa.pub $rep_lien/
    # les fichiers gdm3 et lightdm serviront lors de la post-installation
    printf '#!/bin/sh\nwhile true\ndo\n    sleep 10\ndone\n' >$rep_lien/gdm3
    cp $rep_lien/gdm3 $rep_lien/lightdm
    chmod 755 $rep_lien/preseed* $rep_lien/post-install_debian.sh $rep_lien/gdm3 $rep_lien/lightdm
    # et le script mise_en_place_win_on_linux_se3.sh
    cp ${src}/${archive_tftp}/mise_en_place_win_on_linux_se3.sh $rep_tftp/client_linux/
}

gestion_script_integration()
{
    # la version pour debian
    if [ -e "${rep_client_linux}/distribs/${version_debian}/integration/integration_${version_debian}.bash" ]
    then
        rm -f $rep_lien/integration_${version_debian}.bash
        ln ${rep_client_linux}/distribs/${version_debian}/integration/integration_${version_debian}.bash $rep_lien/
        chmod 755 $rep_lien/integration_${version_debian}.bash
    fi
    # la version pour ubuntu
    if [ -e "${rep_client_linux}/distribs/${version_ubuntu}/integration/integration_${version_ubuntu}.bash" ]
    then
        rm -f $rep_lien/integration_${version_ubuntu}.bash
        ln ${rep_client_linux}/distribs/${version_ubuntu}/integration/integration_${version_ubuntu}.bash $rep_lien/
        chmod 755 $rep_lien/integration_${version_ubuntu}.bash
    fi
}

gestion_cles_publiques()
{
    rm -f /var/www/paquet_cles_pub_ssh.tar.gz
    if [ ! -e "/var/www/paquet_cles_pub_ssh.tar.gz" ]
    then
        echo "génération d'un paquet de clés pub ssh d'aprés vos authorized_keys" | tee -a $compte_rendu
        cd /root/.ssh
        for fich_authorized_keys in authorized_keys authorized_keys2 $rep_lien/id_rsa.pub
        do
            if [ -e "$fich_authorized_keys" ]
            then
                while read A
                do
                    comment=$(echo "$A" | cut -d" " -f3)
                    if [ -n "$comment" -a ! -e "$comment.pub" ]
                    then
                        echo "$A" > $comment.pub
                    fi
                done < $fich_authorized_keys
            fi
        done
        tar -czf /var/www/paquet_cles_pub_ssh.tar.gz *.pub
        cd - >/dev/null
        echo ""
    fi
}

gestion_fichiers_tftp()
{
    # les mots de passe des comptes locaux des clients-linux
    CRYPTPASS_root="$(echo "$xppass" | mkpasswd -s -m md5)"
    # [en attendant d'avoir la variable venant de l'interface du se3 TODO]
    [ -z "$enspass" ] && enspass="$mdp_ens_defaut"
    CRYPTPASS_enseignant="$(echo "$enspass" | mkpasswd -s -m md5)"
    
    # le serveur de temps
    [ -z "$ntpserv" ] && ntpserv="$ntp_serveur_defaut"
    
    echo "correction des fichiers tftp inst_buntu.cfg et inst_debian.cfg → IP du Se3" | tee -a $compte_rendu
    sed -i "s|###_IP_SE3_###|$se3ip|g" ${rep_tftp}/pxelinux.cfg/inst_debian.cfg
    sed -i "s|###_IP_SE3_###|$se3ip|g" ${rep_tftp}/pxelinux.cfg/inst_buntu.cfg
    
    echo "correction des fichiers tftp inst_debian.cfg → version Debian ${version_debian}" | tee -a $compte_rendu
    sed -i "s|###_DEBIAN_###|${version_debian}|g" ${rep_tftp}/pxelinux.cfg/inst_debian.cfg
    # [en prévision d'une évolution TODO : il faudra décommenter]
    #echo "correction des fichiers tftp inst_buntu.cfg → version Ubuntu ${version_ubuntu}" | tee -a $compte_rendu
    sed -i "s|###_UBUNTU_###|${version_ubuntu}|g" ${rep_tftp}/pxelinux.cfg/inst_buntu.cfg
    
    echo "correction des fichiers tftp inst_debian.cfg → nom du domaine" | tee -a $compte_rendu
    sed -i "s|###_DOMAINE_###|$dhcp_domain_name|g" ${rep_tftp}/pxelinux.cfg/inst_debian.cfg
    # [en prévision d'une évolution TODO : il faudra décommenter]
    #echo "correction des fichiers tftp inst_buntu.cfg → nom du domaine" | tee -a $compte_rendu
    sed -i "s|###_DOMAINE_###|$dhcp_domain_name|g" ${rep_tftp}/pxelinux.cfg/inst_buntu.cfg
    
    [ "$CliLinNoPreseed" = "yes" ] && sed -i "s|^#INSTALL_LIBRE_SANS_PRESEED||" ${rep_tftp}/pxelinux.cfg/inst_debian.cfg
    [ "$CliLinNoPreseed" = "yes" ] && sed -i "s|^#INSTALL_LIBRE_SANS_PRESEED||" ${rep_tftp}/pxelinux.cfg/inst_buntu.cfg
    
    [ "$CliLinXfce64" = "yes" ] && sed -i "s|^#XFCE64||" ${rep_tftp}/pxelinux.cfg/inst_debian.cfg
    [ "$CliLinXfce64" = "yes" ] && sed -i "s|^#XFCE64||" ${rep_tftp}/pxelinux.cfg/inst_buntu.cfg
    
    [ "$CliLinLXDE" = "yes" ] && sed -i "s|^#LXDE||" ${rep_tftp}/pxelinux.cfg/inst_debian.cfg
    [ "$CliLinLXDE" = "yes" ] && sed -i "s|^#LXDE||" ${rep_tftp}/pxelinux.cfg/inst_buntu.cfg
    
    [ "$CliLinGNOME" = "yes" ] && sed -i "s|^#GNOME||" ${rep_tftp}/pxelinux.cfg/inst_debian.cfg
    [ "$CliLinGNOME" = "yes" ] && sed -i "s|^#GNOME||" ${rep_tftp}/pxelinux.cfg/inst_buntu.cfg
    echo ""
}

gestion_miroir()
{
    if [ "$MIROIR_LOCAL" != "yes" ]
    then
        if [ ! -e "/etc/apt-cacher-ng" ]
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
            
            if [ ! -e "/var/se3/apt-cacher-ng" ]
            then 
                mv /var/cache/apt-cacher-ng /var/se3/
            fi
            echo ""
        fi
        # restart apt-cacher-ng
        # pour être certain que le service est disponible suite à une éventuelle mise à jour de se3-clonage
        echo "on redémarre le service apt-cacher-ng" | tee -a $compte_rendu
        service apt-cacher-ng restart
        echo ""
        echo "correction des fichiers de preseed Debian ${version_debian}" | tee -a $compte_rendu
        # [en prévision d'une évolution TODO : il faudra décommenter]
        #echo "correction des fichiers de preseed Debian ${version_debian}" | tee -a $compte_rendu
        for i in $(ls $rep_lien/preseed*.cfg)
        do
            sed -i "s|###_IP_SE3_###|$se3ip|g" $i
            sed -i "s|###_PASS_ROOT_###|$CRYPTPASS_root|g" $i
            sed -i "s|###_PASS_ENS_###|$CRYPTPASS_enseignant|g" $i
            sed -i "s|###_NTP_SERV_###|$ntpserv|g" $i
            sed -i "s|###_DEBIAN_###|$version_debian|g" $i
            sed -i "s|###_UBUNTU_###|$version_ubuntu|g" $i
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
        echo "correction des fichiers de preseed Debian ${version_debian}" | tee -a $compte_rendu
        
        for i in $(ls $rep_lien/preseed*.cfg)
        do
            sed -i "s|###_IP_SE3_###:9999|$MIROIR_IP|g" $i
            sed -i "s|###_IP_SE3_###|$se3ip|g" $i
            sed -i "s|/debian|$CHEMIN_MIROIR|g" $i
            sed -i "s|###_PASS_ROOT_###|$CRYPTPASS_root|g" $i
            sed -i "s|###_PASS_ENS_###|$CRYPTPASS_enseignant|g" $i
            sed -i "s|###_NTP_SERV_###|$ntpserv|g" $i
            sed -i "s|###_DEBIAN_###|$version_debian|g" $i
            sed -i "s|###_UBUNTU_###|$version_ubuntu|g" $i
            sed -i "s|###_DOMAINE_###|$dhcp_domain_name|g" $i
        done
    fi
    echo "correction des fichiers post-install Debian $version_debian" | tee -a $compte_rendu
    # [en prévision d'une évolution TODO : il faudra décommenter]
    #echo "correction des fichiers post-install Ubuntu $version_ubuntu" | tee -a $compte_rendu
    for i in $(ls $rep_lien/post-install*)
    do
        sed -i "s|###_DEBIAN_###|$version_debian|g" $i
        sed -i "s|###_UBUNTU_###|$version_ubuntu|g" $i
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
    [ -e "${rep_client_linux}/unefois/PAUSE" ] && mv ${rep_client_linux}/unefois/PAUSE ${rep_client_linux}/unefois/NO-PAUSE
    
    # l'archive contient des scripts unefois à mettre en place pour tous les clients
    # sont-ils nécessaires ? Voir les fonctions cles_publiques_ssh et configurer_ocs du script de post-installation
    cp -r ${src}/${archive_tftp}/unefois/* ${rep_client_linux}/unefois/
    
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
    # [ faut-il adapter à Ubuntu cette fonction ? TODO]
    
    # [ pourquoi ce test concernant update-mozilla-profile ? TODO]
    # d'où vient la présence éventuelle de ce fichier ?
    if [ -e "${src}/update-mozilla-profile" ]
    then
        echo "gestion du profil skel de la distribution Debian ${version_debian}"
        rm -rf ${rep_client_linux}/distribs/${version_debian}/skel/.mozilla
        echo  "modif install_client_linux_archive - $ladate" > ${rep_client_linux}/distribs/${version_debian}/skel/.VERSION | tee -a $compte_rendu
    fi
    # normalement, si le paquet se3-clients-linux est installé, on devrait avoir .config dans le skel
    if [ ! -e "${rep_client_linux}/distribs/${version_debian}/skel/.config" ]
    then
        echo "skel : mise en place de .config pour Debian ${version_debian}"
        cp -r ${src}/${archive_tftp}/.config ${rep_client_linux}/distribs/${version_debian}/skel/
    fi
    # même remarque que ci-dessus… sauf si présence de update-mozilla-profile
    if [ ! -e "${rep_client_linux}/distribs/${version_debian}/skel/.mozilla" ]
    then
        echo "skel : mise en place de .mozilla Debian ${version_debian}"
        cp -r ${src}/${archive_tftp}/.mozilla ${rep_client_linux}/distribs/${version_debian}/skel/
        prefsjs="/etc/skel/user/profil/appdata/Mozilla/Firefox/Profiles/default/prefs.js"
        if [ -e "$prefsjs" ]
        then
            echo "skel : utilisation du $prefsjs du skel se3 pour Debian ${version_debian}"
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
gerer_repertoires
verifier_presence_mkpasswd
mise_en_place_tftpboot
gestion_netboot
gestion_firmware_debian
transfert_repertoire_install
gestion_script_integration
gestion_cles_publiques
gestion_fichiers_tftp
gestion_miroir
fichier_parametres
gestion_scripts_unefois
#gestion_profil_skel
reconfigurer_module
message_fin
#
# fin du programme
#####
