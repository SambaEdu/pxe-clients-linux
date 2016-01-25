# Liste de propositions d'évolution du module pxe-clients-linux

* rendre indépendant le module pxe-clients-linux du module se3-clonage.
* Reste à transposer pour les SE3 wheezy. Pour toute la partie PXE et client linux c'est exactement la même chose donc pas de pb. En revanche pour la partie se3-clonage, il y a des histoires d'encodages différents donc le paquet est à refaire en tenant compte de ces quelques modifs. Je regarderai ça et je pourrai tester car serveur d'établissement est en wheezy.
* modifier le fichier install.menu pour qu'il ne comporte plus de référence à jessie ou trusty afin d'être indépendant du futur paquet pxe-clients-linux.
* compléter la doc pour le choix du nom du client (partie post-installation).
* mettre en fonctions les scripts mise en place et post-installation pour Ubuntu.
* mettre en place une liste perso d'applis pour ubuntu
* permettre la possibilité d'installer des paquets une fois l'installation effectuée. Par ex avec /home/netlogon/clients-linux/lanceparc. A voir si cela doit être mis en place par ce dispositif ou bien se3-clients-linux
* gestion des erreurs dans les scripts mise en place et post-installation
* gestion du cas où on a plusieurs cartes réseaux (script post-installation)
* mettre au point l'interface web du paquet pxe-clients-linux en reprenant la partie actuelle
* dans l'interface web, pouvoir notifier le mot de passe du compte local enseignant


# liste de évolutions réalisées

* permettre des commentaires dans les fichiers "mesapplis" pour debian
* mise en place d'une liste perso des applis pour debian
* incorporation des firmwares debian dans le fichier initrd.gz
* mise en place d'un répertoire contenant des scripts perso préservé des mises à jour du paquet pxe-clients-linux
* possibilité de lancer des scripts perso à la fin de la post-installation


# Quelques remarques

- Le mot de passe root est forcément celui de adminse3. La page php proposait bien de le modifier mais le preseed lui ne l'était pas en conséquence.
- Idem concernant le compte local enseignant. On ne peut plus changer le nom ni le pass pour la même raison que précédemment.
- Les accents sont bourrinés car le fichier install est en utf8 et s'affiche en iso dans la page php.
