# Liste de propositions d'évolution du module pxe-clients-linux

* rendre indépendant le module pxe-clients-linux du module se3-clonage.
* modifier le fichier install.menu pour qu'il ne comporte plus de référence à jessie ou trusty afin d'être indépendant du futur paquet pxe-clients-linux.
* mettre en place une liste perso d'applis pour ubuntu
* gestion des erreurs dans les scripts mise en place et post-installation
* gestion du cas où on a plusieurs cartes réseaux (script post-installation)
* mettre au point l'interface web du paquet pxe-clients-linux en reprenant la partie actuelle
* dans l'interface web, pouvoir notifier le mot de passe du compte local enseignant
* unifier les scripts et fichiers pour Debian/Ubuntu
* installer le paquet ocs après avoir lancé l'intégration : appel à la fonction à déplacer
* cas où la machine n'a pas d'entrée dans l'annuaire : le script doit demander le nom ; relance-t-on alors la boucle de lecture de l'annuaire pour savoir si la machine a été réservé entre-temps
* utiliser httpredir à la place de ftp.fr pour les dépôts Debian



# liste de évolutions réalisées

* permettre des commentaires dans les fichiers "mesapplis" pour debian
* mise en place d'une liste perso des applis pour debian
* incorporation des firmwares debian dans le fichier initrd.gz
* mise en place d'un répertoire contenant des scripts perso préservé des mises à jour du paquet pxe-clients-linux
* possibilité de lancer des scripts perso à la fin de la post-installation
* mise en fonctions les scripts mise en place et post-installation pour Ubuntu.
* mise en place de la possibilité d'installer des paquets une fois l'installation effectuée à l'aide du script installer_applis_perso_20160430.unefois
* ajout dans la doc pour le choix du nom du client (partie post-installation).
* passer le se3 à la version 0.9 d' apt-cacher-ng (via le dépôt backports-wheezy-sloppy) car c'est la version d'apt-cacher-ng conçue et adaptée pour des clients Ubuntu Xenial et aussi pour la future version de Debian Stretch…


# Quelques remarques

- Le mot de passe root est forcément celui de adminse3. La page php proposait bien de le modifier mais le preseed lui ne l'était pas en conséquence.
- Idem concernant le compte local enseignant. On ne peut plus changer le nom ni le pass pour la même raison que précédemment.
- Les accents sont bourrinés car le fichier install est en utf8 et s'affiche en iso dans la page php.

