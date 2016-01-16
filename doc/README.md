# Installation de clients Linux `Debian` et `Ubuntu` via `SE3` + intégration automatique


**Documentation générale du module `pxe-clients-linux`**


## Table des matières

* [Vue d'ensemble du dispositif](#vue-densemble)
* [Distributions GNU/Linux proposées](#distributions-gnulinux-proposées)
* [Mise en place du dispositif](misenplace.md)
* [Utilisation du dispositif](utilisation.md)
* [Les listes des applications installées](listeapplis.md)
* [Utilisation du script perso](messcripts.md)
* [Annexes](#annexes)
* [Ressources externes](#ressources-externes)


## Vue d'ensemble

Cette documentation concerne l'installation via un amorçage par `pxe` (Pre-boot eXecution Environment) et des fichiers `preseed` suivie d'une intégration au domaine géré par `se3`.

Voici les grandes lignes de l'utilisation du dispositif :

* installer le module pxe-clients-linux
* démarrer une machine en utilisant l'amorçage `pxe` (touche `F12`)
* dans le menu disponible, choisir le système à installer

Une fois le système choisi, l'installation démarre (**phase 1**) puis, après le redémarrage de la machine, il est lancé automatiquement (**phase 2**) la préparation et l'intégration au domaine géré par le `se3`. Après avoir à nouveau démarré, la machine est prête : les utlisateurs peuvent ouvrir une session avec leur compte réseau.

L'installation peut aussi bien se faire sur le disque dur entier ou bien en cohabitation (ou `double-boot`) avec un autre Système d'exploitation (il faudra alors qu'il y ait un espace libre non partitionné). Les deux possibilités sont proposées dans les menus `pxe`.

**Remarque :** une fois une machine installée et intégrée, la gestion est prise en charge par le module `se3-clients-linux` dont la documentation est mise en lien ci-dessous.


## Distributions `GNU/Linux` proposées

Les distributions `GNU/Linux` qui sont proposées à l'installation sont :

* Debian `Jessie` (version 8)
    * Gnome
    * Xfce
    * Ldxe
* Ubuntu `Trusty Tahr` (version 14.04)
    * Ubuntu
    * Xbuntu
    * Lbuntu

Ces distributions sont proposées pour des machines **32bits** (i386) ou **64bits** (amd64).


## Annexes

* [Installer et tester en toute sécurité la version du paquet issue de la branche `se3testing`](testing.md)


## Ressources externes

* [la documentation de Sébastien Muller](http://www-annexe.ac-rouen.fr/productions/tice/SE3_install_wheezy_pxe_web_gen_web/co/SE3_install_wheezy_pxe_web.html)
* [la documentation du module `se3-clients-linux`](https://github.com/flaf/se3-clients-linux/blob/master/doc/README.md)
* [amorçage via `pxe`](https://fr.wikipedia.org/wiki/Preboot_Execution_Environment)
* [installation de `Debian` par préconfiguration](https://www.debian.org/releases/jessie/amd64/apb.html.fr)

