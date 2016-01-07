# Liste de propositions d'évolution du module pxe-clients-linux

* rendre indépendant le module pxe-clients-linux du module se3-clonage.
* Reste à transposer pour les SE3 wheezy. Pour toute la partie PXE et client linux c'est exactement la même chose donc pas de pb. En revanche pour la partie se3-clonage, il y a des histoires d'encodages différents donc le paquet est à refaire en tenant compte de ces quelques modifs. Je regarderai ça et je pourrai tester car serveur d'établissement est en wheezy.
* modifier le fichier install.menu pour qu'il ne comporte plus de référence à jessie ou trusty afin d'être indépendant du futur paquet pxe-clients-linux.
* compléter la doc pour la partie mise en place.
* compléter la doc pour le choix du nom du client (partie post-installation).
* mettre en fonctions les scripts pour Ubuntu.
* permettre des commentaires dans les fichiers "mesapplis".
* permettre la possibilité d'installer des paquets une fois l'installation effectuée. Par ex avec /home/netlogon/clients-linux/lanceparc. A voir si cela doit être mis en place par ce dispositif ou bien se3-clients-linux 


# Quelques remarques

- Le mot de passe root est forcément celui de adminse3. La page php proposait bien de le modifier mais le preseed lui ne l'était pas en conséquence.
- Idem concernant le compte local enseignant. On ne peut plus changer le nom ni le pass pour la même raison que précédemment.
- Les accents sont bourrinés car le fichier install est en utf8 et s'affiche en iso dans la page php.
