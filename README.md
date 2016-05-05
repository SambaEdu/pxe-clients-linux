# Dispositif de déploiement des clients GNU/Linux du module se3-clonage

Sources du dispositif. Ce dernier est archivé en tar.gz et disponible depuis le serveur wawadeb.

Pour modifier cette partie il faut donc :
* Modifier les sources (dossier sources)
* Au besoin modifier le script de mise en place
* recréer l'archive
* Mettre la date et les bonnes sommes md5 du script de mise en place et de l'archive dans versions.txt

N'hésitez pas à contribuer à ce projet aussi bien au niveau du code que de la documentation.

La documentation se trouve [ici](https://github.com/SambaEdu/se3-docs/blob/master/pxe-clients-linux/README.md).


### Note pour le développeur

Toutes les 5 minutes, s'il y a eu des nouveaux commits,
l'archive est mise à jour à
[cette adresse](http://archive.flaf.fr/pxe-clients-linux/).
Les deux fichiers disponibles sont en fait identiques :

- l'un porte le nom `install_client_linux_archive-tftp.tar.gz`;
- l'autre porte le nom `install_client_linux_archive-tftp_<ID>.tar.gz`
  où `<ID>` correspond aux dix premiers caractères de l'ID
  du commit dans lequel le dépôt se trouvait au moment de la
  construction de l'archive.


