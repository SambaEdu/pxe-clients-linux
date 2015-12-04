#!/bin/bash

# $Id: se3_get_install_client_linux.sh 8705 2015-04-10 23:37:10Z keyser $
# Auteur: Stephane Boireau
# Derniere modification: 29/05/2014

# - telecharger le dispositif Client Linux depuis http://wawadeb.crdp.ac-caen.fr/iso/client_linux/

. /usr/share/se3/includes/config.inc.sh -d
. /usr/share/se3/includes/functions.inc.sh

COLTITRE="\033[1;35m"   # Rose
COLPARTIE="\033[1;34m"  # Bleu

COLTXT="\033[0;37m"     # Gris
COLCHOIX="\033[1;33m"   # Jaune
COLDEFAUT="\033[0;33m"  # Brun-jaune
COLSAISIE="\033[1;32m"  # Vert

COLCMD="\033[1;37m"     # Blanc

COLERREUR="\033[1;31m"  # Rouge
COLINFO="\033[0;36m"    # Cyan

# Parametres
timestamp=$(date +%s)
timedate=$(date "+%Y%m%d_%H%M%S")


# Positionnement de l'url de telechargement en bdd
if [ -n "$1" ]; then
	src="$1"
	SETMYSQL SrcPxeClientLin "$src" "url du dispositif installation PXE client Linux" 7
elif [ -n "$SrcPxeClientLin" ]; then
	src="$SrcPxeClientLin"
else
	src="http://wawadeb.crdp.ac-caen.fr/iso/client_linux"
	SETMYSQL SrcPxeClientLin "$src" "url du dispositif installation PXE client Linux" 7
fi



rm -rf "/var/se3/tmp_client_linux_*"
tmp="/var/se3/tmp_client_linux_${timedate}"
mkdir -p "$tmp"
chmod 700 $tmp

# ========================================

# Valeurs des versions en place recuperees de se3db.params:
version_pxe_client_linux_en_place="$pxe_client_linux_version"

# ========================================

dossier_ressource_dispositif_pxe_client_linux=/tftpboot/client_linux
mkdir -p ${dossier_ressource_dispositif_pxe_client_linux}

t=$(echo "$*" | grep "check_version")
if [ -n "$t" ]; then
	cd $tmp
	wget -O versions.txt $src/versions.txt? > /dev/null 2>&1
	if [ "$?" = 0 -a -e versions.txt ]; then
		VarchPxeClientLin_en_ligne=$(grep ";install_client_linux_archive-tftp.tar.gz$" $tmp/versions.txt | cut -d";" -f1)

		# Pour le premier lancement: mise en place du nouveau dispositif
		if [ -z "$VarchPxeClientLin_en_place" ]; then
			md5_en_ligne=$(grep ";install_client_linux_archive-tftp.tar.gz$" $tmp/versions.txt | cut -d";" -f2)
			if [ -e "${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_archive-tftp.tar.gz" ]; then
				md5_en_place=$(md5sum ${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_archive-tftp.tar.gz|cut -d" " -f1)
				if [ "$md5_en_place" = "$md5_en_ligne" ]; then
					VarchPxeClientLin=$VarchPxeClientLin_en_ligne
					SETMYSQL VarchPxeClientLin "$VarchPxeClientLin" "version actuelle archive du dispositif installation PXE client Linux" 7
					VarchPxeClientLin_en_place=$VarchPxeClientLin_en_ligne
				fi
			fi
		fi

		VscriptPxeClientLin_en_ligne=$(grep ";install_client_linux_mise_en_place.sh$" $tmp/versions.txt | cut -d";" -f1)

		if [ -z "$VscriptPxeClientLin_en_place" ]; then
			md5_en_ligne=$(grep ";install_client_linux_mise_en_place.sh$" $tmp/versions.txt | cut -d";" -f2)
			if [ -e "${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_mise_en_place.sh" ]; then
				md5_en_place=$(md5sum ${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_mise_en_place.sh|cut -d" " -f1)
				if [ "$md5_en_place" = "$md5_en_ligne" ]; then
					VscriptPxeClientLin=$VscriptPxeClientLin_en_ligne
					SETMYSQL VscriptPxeClientLin "$VscriptPxeClientLin" "version actuelle script de mise en place du dispositif installation PXE client Linux" 7
					VscriptPxeClientLin_en_place=$VscriptPxeClientLin_en_ligne
				fi
			fi
		fi

		temoin_erreur="n"
		temoin_fichier_manquant="n"
		if [ ! -e "${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_archive-tftp.tar.gz" ]; then
			temoin_fichier_manquant="y"
			VarchPxeClientLin_en_place="<span style='color:red'>Absent</span>"
		else
			md5_en_place=$(md5sum ${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_archive-tftp.tar.gz|cut -d" " -f1)
			md5_en_ligne=$(grep ";install_client_linux_archive-tftp.tar.gz$" $tmp/versions.txt | cut -d";" -f2)
	
			if [ "$md5_en_ligne" != "$md5_en_place" ]; then
				VarchPxeClientLin_en_place="<span style='color:red'>Somme MD5 incorrecte</span>"
				temoin_erreur="y"
			fi
		fi

		if [ ! -e "${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_mise_en_place.sh" ]; then
			temoin_fichier_manquant="y"
			VscriptPxeClientLin_en_place="<span style='color:red'>Absent</span>"
		else
			md5_en_place=$(md5sum ${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_archive-tftp.tar.gz|cut -d" " -f1)
			md5_en_ligne=$(grep ";install_client_linux_archive-tftp.tar.gz$" $tmp/versions.txt | cut -d";" -f2)
	
			if [ "$md5_en_ligne" != "$md5_en_place" ]; then
				VscriptPxeClientLin_en_place="<span style='color:red'>Somme MD5 incorrecte</span>"
				temoin_erreur="y"
			fi
		fi

		if [ "$temoin_erreur" != "y" -a "$temoin_fichier_manquant" != "y" -a "$VarchPxeClientLin_en_ligne" = "$VarchPxeClientLin_en_place" -a "$VscriptPxeClientLin_en_ligne" = "$VscriptPxeClientLin_en_place" ]; then
			echo "<p><span style='color:green'>Dispositif &agrave; jour</span></p>";
		else
			echo "<p><span style='color:red'>Mise &agrave; jour disponible</span></p>";
		fi

		echo "<table class='crob'>
<tr>
	<th>&nbsp;</th>
	<th>Sur votre SE3</th>
	<th>En ligne</th>
</tr>
<tr>
	<th>Archive</th>
	<td>$VarchPxeClientLin_en_place</td>
	<td>$VarchPxeClientLin_en_ligne</td>
</tr>
<tr>
	<th>Script</th>
	<td>$VscriptPxeClientLin_en_place</td>
	<td>$VscriptPxeClientLin_en_ligne</td>
</tr>
</table>";

	else
		echo "<p><span style='color:red'>ECHEC du telechargement du fichier des versions.</span></p>"
	fi

	exit
fi

# ========================================

t=$(echo "$*" | grep "mode=html")
if [ -z "$t" ]; then
	mode="cmdline"
else
	mode="html"
fi

if [ "$mode" = "cmdline" ]; then
	echo -e "$COLTXT"
else
	echo "<pre>"
	echo "<h3>"
fi
echo "Mise en place des fichiers utiles pour l'installation de client Linux en boot PXE."
if [ "$mode" = "cmdline" ]; then
	echo -e "$COLCMD"
else
	echo "</h3>"
fi

# Telecharger
cd $tmp
wget -O versions.txt $src/versions.txt? 
if [ "$?" != "0" ]; then
	if [ "$mode" = "cmdline" ]; then
		echo -e "$COLERREUR"
	else
		echo "<span style='color:red'>"
	fi
	echo "ERREUR lors du telechargement de $src/versions.txt"
	echo "ABANDON."
	if [ "$mode" = "cmdline" ]; then
		echo -e "$COLTXT"
	else
		echo "</span>"
		echo "</pre>"
	fi
	exit
else
	if [ "$mode" = "cmdline" ]; then
		echo -e "$COLINFO"
	else
		echo "<span style='color:green'>"
	fi
	echo "SUCCES du telechargement de $src/versions.txt"
	if [ "$mode" = "cmdline" ]; then
		echo -e "$COLTXT"
	else
		echo "</span>"
	fi
fi

VarchPxeClientLin_en_ligne=$(grep ";install_client_linux_archive-tftp.tar.gz$" $tmp/versions.txt | cut -d";" -f1)
VscriptPxeClientLin_en_ligne=$(grep ";install_client_linux_mise_en_place.sh$" $tmp/versions.txt | cut -d";" -f1)

t=$(echo "$*" | grep "suppr_dispositif_precedent")
if [ -n "$t" ]; then
	if [ "$mode" = "cmdline" ]; then
		echo -e "$COLINFO"
	else
		echo "<span style='color:green'>"
	fi

	echo "Menage prealable au telechargement..."

	fich_tmp=${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_archive-tftp.tar.gz
	if [ -e "${fich_tmp}" ]; then
		echo "Suppression de ${fich_tmp}"
		rm -f ${fich_tmp}
	else
		echo "Pas de ${fich_tmp} present."
	fi

	fich_tmp=${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_mise_en_place.sh
	if [ -e "${fich_tmp}" ]; then
		echo "Suppression de ${fich_tmp}"
		rm -f ${fich_tmp}
	else
		echo "Pas de ${fich_tmp} present."
	fi

	if [ "$mode" = "cmdline" ]; then
		echo -e "$COLTXT"
	else
		echo "</span>"
	fi
fi

# On controle si des fichiers install PXE client Linux sont deja en place
if [ -e "${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_archive-tftp.tar.gz" -a -e "${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_mise_en_place.sh" ]; then

	if [ -z "$VarchPxeClientLin_en_place" ]; then
		md5_en_ligne=$(grep ";install_client_linux_archive-tftp.tar.gz$" $tmp/versions.txt | cut -d";" -f2)
		if [ -e "${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_archive-tftp.tar.gz" ]; then
			md5_en_place=$(md5sum ${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_archive-tftp.tar.gz|cut -d" " -f1)
			if [ "$md5_en_place" = "$md5_en_ligne" ]; then
				VarchPxeClientLin=$VarchPxeClientLin_en_ligne
				SETMYSQL VarchPxeClientLin "$VarchPxeClientLin" "version actuelle archive du dispositif installation PXE client Linux" 7
				VarchPxeClientLin_en_place=$VarchPxeClientLin_en_ligne
			fi
		fi
	fi

	VscriptPxeClientLin_en_ligne=$(grep ";install_client_linux_mise_en_place.sh$" $tmp/versions.txt | cut -d";" -f1)

	if [ -z "$VscriptPxeClientLin_en_place" ]; then
		md5_en_ligne=$(grep ";install_client_linux_mise_en_place.sh$" $tmp/versions.txt | cut -d";" -f2)
		if [ -e "${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_mise_en_place.sh" ]; then
			md5_en_place=$(md5sum ${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_mise_en_place.sh|cut -d" " -f1)
			if [ "$md5_en_place" = "$md5_en_ligne" ]; then
				VscriptPxeClientLin=$VscriptPxeClientLin_en_ligne
				SETMYSQL VscriptPxeClientLin "$VscriptPxeClientLin" "version actuelle script de mise en place du dispositif installation PXE client Linux" 7
				VscriptPxeClientLin_en_place=$VscriptPxeClientLin_en_ligne
			fi
		fi
	fi

	if [ -e "${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_archive-tftp.tar.gz" ]; then
		md5_en_place=$(md5sum ${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_archive-tftp.tar.gz|cut -d" " -f1)
		md5_en_ligne=$(grep ";install_client_linux_archive-tftp.tar.gz$" $tmp/versions.txt | cut -d";" -f2)

		if [ "$md5_en_ligne" != "$md5_en_place" ]; then
			VarchPxeClientLin_en_place=""
		fi
	fi

	if [ -e "${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_mise_en_place.sh" ]; then
		md5_en_place=$(md5sum ${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_archive-tftp.tar.gz|cut -d" " -f1)
		md5_en_ligne=$(grep ";install_client_linux_archive-tftp.tar.gz$" $tmp/versions.txt | cut -d";" -f2)

		if [ "$md5_en_ligne" != "$md5_en_place" ]; then
			VscriptPxeClientLin_en_place=""
		fi
	fi

	# On controle la version des fichiers
	if [ "$VarchPxeClientLin_en_ligne" = "$VarchPxeClientLin_en_place" -a "$VscriptPxeClientLin_en_ligne" = "$VscriptPxeClientLin_en_place" ]; then

		if [ "$mode" = "cmdline" ]; then
			echo -e "$COLINFO"
		else
			echo "<span style='color:green'>"
		fi
		echo "Les fichiers archive et script sont deja les plus recents; On ne les re-telecharge pas."
		if [ "$mode" = "cmdline" ]; then
			echo -e "$COLTXT"
		else
			echo "</span>"
		fi
		temoin_telech_requis="n"
	else
		# La version a change.
		temoin_telech_requis="y"
	fi
else
	# Il manque au moins un fichier, on telecharge pour mettre a jour
	temoin_telech_requis="y"
fi

if [ "$temoin_telech_requis" = "y" ]; then

	md5_en_place=""
	md5_en_ligne=""
	if [ -e "${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_archive-tftp.tar.gz" ]; then
		md5_en_place=$(md5sum ${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_archive-tftp.tar.gz|cut -d" " -f1)
		md5_en_ligne=$(grep ";install_client_linux_archive-tftp.tar.gz$" $tmp/versions.txt | cut -d";" -f2)
	fi

	if [ ! -e "${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_archive-tftp.tar.gz" -o "$md5_en_ligne" != "$md5_en_place" -o "$VarchPxeClientLin_en_ligne" != "$VarchPxeClientLin_en_place" ]; then
		wget -O install_client_linux_archive-tftp.tar.gz $src/install_client_linux_archive-tftp.tar.gz?
		if [ "$?" != "0" ]; then
			if [ "$mode" = "cmdline" ]; then
				echo -e "$COLERREUR"
			else
				echo "<span style='color:red'>"
			fi
			echo "ERREUR lors du telechargement de $src/install_client_linux_archive-tftp.tar.gz"
			echo "ABANDON."
			if [ "$mode" = "cmdline" ]; then
				echo -e "$COLTXT"
			else
				echo "</span>"
				echo "</pre>"
			fi
			exit
		else
			if [ "$mode" = "cmdline" ]; then
				echo -e "$COLINFO"
			else
				echo "<span style='color:green'>"
			fi
			echo "SUCCES du telechargement de $src/install_client_linux_archive-tftp.tar.gz"
			if [ "$mode" = "cmdline" ]; then
				echo -e "$COLTXT"
			else
				echo "</span>"
			fi
	
			md5_telech=$(md5sum install_client_linux_archive-tftp.tar.gz|cut -d" " -f1)
			md5_en_ligne=$(grep ";install_client_linux_archive-tftp.tar.gz$" $tmp/versions.txt | cut -d";" -f2)
			if [ "$md5_telech" != "$md5_en_ligne" ]; then
				if [ "$mode" = "cmdline" ]; then
					echo -e "$COLERREUR"
				else
					echo "<span style='color:red'>"
				fi
				echo "ANOMALIE: La somme MD5 ne coincide pas: $md5_en_ligne en ligne et $md5_telech telecharge."
				if [ "$mode" = "cmdline" ]; then
					echo -e "$COLTXT"
				else
					echo "</span>"
					echo "</pre>"
				fi
				exit
			fi
		fi

		liste_fichiers_a_copier="$liste_fichiers_a_copier install_client_linux_archive-tftp.tar.gz"
	fi

	md5_en_place=""
	md5_en_ligne=""
	if [ -e "${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_mise_en_place.sh" ]; then
		md5_en_place=$(md5sum ${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_mise_en_place.sh|cut -d" " -f1)
		md5_en_ligne=$(grep ";install_client_linux_mise_en_place.sh$" $tmp/versions.txt | cut -d";" -f2)
	fi

	if [ ! -e "${dossier_ressource_dispositif_pxe_client_linux}/install_client_linux_mise_en_place.sh" -o "$md5_en_ligne" != "$md5_en_place" -o "$VscriptPxeClientLin_en_ligne" != "$VscriptPxeClientLin_en_place" ]; then
		wget -O install_client_linux_mise_en_place.sh $src/install_client_linux_mise_en_place.sh?
		if [ "$?" != "0" ]; then
			if [ "$mode" = "cmdline" ]; then
				echo -e "$COLERREUR"
			else
				echo "<span style='color:red'>"
			fi
			echo "ERREUR lors du telechargement de $src/install_client_linux_mise_en_place.sh"
			echo "ABANDON."
			if [ "$mode" = "cmdline" ]; then
				echo -e "$COLTXT"
			else
				echo "</span>"
				echo "</pre>"
			fi
			exit
		else
			if [ "$mode" = "cmdline" ]; then
				echo -e "$COLINFO"
			else
				echo "<span style='color:green'>"
			fi
			echo "SUCCES du telechargement de $src/install_client_linux_mise_en_place.sh"
			if [ "$mode" = "cmdline" ]; then
				echo -e "$COLTXT"
			else
				echo "</span>"
			fi
	
			md5_telech=$(md5sum install_client_linux_mise_en_place.sh|cut -d" " -f1)
			md5_en_ligne=$(grep ";install_client_linux_mise_en_place.sh$" $tmp/versions.txt | cut -d";" -f2)
			if [ "$md5_telech" != "$md5_en_ligne" ]; then
				if [ "$mode" = "cmdline" ]; then
					echo -e "$COLERREUR"
				else
					echo "<span style='color:red'>"
				fi
				echo "ANOMALIE: La somme MD5 ne coincide pas: $md5_en_ligne en ligne et $md5_telech telecharge."
				if [ "$mode" = "cmdline" ]; then
					echo -e "$COLTXT"
				else
					echo "</span>"
					echo "</pre>"
				fi
				exit
			fi
		fi

		liste_fichiers_a_copier="$liste_fichiers_a_copier install_client_linux_mise_en_place.sh"
	fi

	if [ "$mode" = "cmdline" ]; then
		echo -e "$COLTXT"
	else
		echo "<b>"
	fi
	echo "Copie des fichiers vers leur emplacement..."
	if [ "$mode" = "cmdline" ]; then
		echo -e "$COLCMD"
	else
		echo "</b>"
	fi
	cp -fv $liste_fichiers_a_copier ${dossier_ressource_dispositif_pxe_client_linux}/

	if [ "$?" != "0"  ]; then
		if [ "$mode" = "cmdline" ]; then
			echo -e "$COLERREUR"
		else
			echo "<span style='color:red'>"
		fi

		echo "ERREUR lors de la copie"

		if [ "$mode" = "cmdline" ]; then
			echo -e "$COLTXT"
		else
			echo "</span>"
			echo "</pre>"
		fi
	else
		cd ${dossier_ressource_dispositif_pxe_client_linux}

		if [ "$mode" = "cmdline" ]; then
			echo -e "$COLTXT"
		else
			echo "<b>"
		fi
		echo "Execution de la mise en place..."
		if [ "$mode" = "cmdline" ]; then
			echo -e "$COLCMD"
		else
			echo "</b>"
		fi

		chmod +x install_client_linux_mise_en_place.sh
		./install_client_linux_mise_en_place.sh

		if [ "$?" != "0"  ]; then

			# ########################
			#        A FAIRE
			# Il faudrait effectuer un retour succes/erreur dans le install_client_linux_mise_en_place.sh
			# ########################

			if [ "$mode" = "cmdline" ]; then
				echo -e "$COLERREUR"
			else
				echo "<span style='color:red'>"
			fi

			echo "ERREUR lors de l execution de la mise en place."

			if [ "$mode" = "cmdline" ]; then
				echo -e "$COLTXT"
			else
				echo "</span>"
				echo "</pre>"
			fi
		else

			SETMYSQL VarchPxeClientLin "$VarchPxeClientLin_en_ligne" "version actuelle archive du dispositif installation PXE client Linux" 7
			SETMYSQL VscriptPxeClientLin "$VscriptPxeClientLin_en_ligne" "version actuelle script de mise en place du dispositif installation PXE client Linux" 7

		fi
	fi
fi

rm -fr $tmp


if [ "${tftp_aff_menu_pxe}" != "y" ]; then
	/usr/share/se3/scripts/se3_pxe_menu_ou_pas.sh 'standard'
else
	/usr/share/se3/scripts/se3_pxe_menu_ou_pas.sh 'menu'
fi

if [ "$mode" = "cmdline" ]; then
	echo -e "$COLTITRE"
else
	echo "<b>"
fi
echo "Termine."
if [ "$mode" = "cmdline" ]; then
	echo -e "$COLTXT"
else
	echo "</b>"
	echo "</pre>"
fi
/usr/share/se3/includes/functions.inc.sh -fd
exit 0