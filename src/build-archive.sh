#!/bin/bash

LADATE=$(date +%Y%m%d)
 
echo "---------------------------------------------------------------------"
echo "--------------         creation archive PXE    ----------------"
echo "------------------------------------------------- -------------------"


archive_name="install_client_linux_archive-tftp"
script_name="install_client_linux_mise_en_place.sh"


cp -r ../archives/sources $archive_name

tar -czf $archive_name.tar.gz $archive_name

echo "$LADATE;$(md5sum $archive_name.tar.gz|/usr/bin/cut -f1 -d" ");$archive_name.tar.gz
$LADATE;$(md5sum $script_name|/usr/bin/cut -f1 -d" ");$script_name" > versions.txt

echo "$archive_name.tar.gz et versions.txt créés dans le dossier courant
Reste à télécharger ces deux fichiers et $script_name sur le serveur web 
de votre choix (par ex sur votre se3 de test lui même dans /var/www/) 
Ensuite pour  tester depuis le se3 en console lancer la commande suivante :
/usr/share/se3/scripts/se3_get_install_client_linux.sh http://ip-ou-url
"
rm -fr ./$archive_name

exit 0


