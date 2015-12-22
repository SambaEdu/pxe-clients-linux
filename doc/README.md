# Installation de clients Linux `Debian` et `Ubuntu` via `SE3` + intégration automatique


**Documentation générale du module `pxe-clients-linux`**


## Table des matières

* [Vue d'ensemble](#vue-densemble)
* [Distributions GNU/Linux proposées](#distributions-gnulinux-proposées)
* [Annexes](#annexes)
* [Ressources externes](#ressources-externes)
* [Pour les impatients qui veulent utiliser le dispositif rapidement]()
* [Les listes des applications installées]()


## Annexes

* [Installer et tester en toute sécurité la version du paquet issue de la branche `se3testing`]()


## Vue d'ensemble

Cette documentation concerne l'installation via un amorçage par `pxe` et des fichiers `preseed` suivie d'une intégration au domaine géré par `se3`.

Voici les grandes lignes de l'utilisation du dispositif :

* installer le module pxe-clients-linux
* démarrer une machine en utilisant l'amorçage `pxe` (touche `F12`)
* dans le menu disponible, choisir le système à installer

Une fois le système choisi, l'installation démarre (**phase 1**) puis, après le redémarrage de la machine, il est lancé automatiquement (**phase 2**) la préparation et l'intégration au domaine géré par le `se3`. Après avoir à nouveau démarré, la machine est prête : les utlisateurs peuvent ouvrir une session avec leur compte réseau.


## Distributions `GNU/Linux` proposées

Les distributions GNU/Linux qui sont proposées à l'installation sont :

* Debian Jessie (version 8)
    * Gnome
    * Xfce
    * Ldxe
* Ubuntu Trusty Tahr (version 14.04)
    * Ubuntu
    * Lbuntu

Ces distributions sont proposées pour des machines **32bits** (i386) ou **64bits** (amd64).

L'installation peut aussi bien se faire sur le disque dur entier ou bien en cohabitation avec un autre Système d'exploitation (il faudra alors laisser un espace vide non partitionné). Les deux possibilités sont proposées dans les menus `pxe`.


## Ressources externes

* [la documentation de Sébastien Muller](http://www-annexe.ac-rouen.fr/productions/tice/SE3_install_wheezy_pxe_web_gen_web/co/SE3_install_wheezy_pxe_web.html)
* [la documentation du paquet `se3-clients-linux`]()

