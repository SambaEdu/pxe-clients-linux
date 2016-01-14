# Utilisation du dispositif d'installation de clients `Gnu/Linux`

* [Vue d'ensemble](#vue-densemble)
* [Démarrage en `pxe`](#démarrage-en-pxe)
* [Menus pxe disponibles](#menus-pxe-disponibles)
* [Installation du système `phase 1`](#installation-du-système-phase-1)
    [Problèmes éventuels lors de la phase 1](#problèmes-éventuels-lors-de-la-phase-1)
    [Les firmwares pour la carte réseau](#les-firmwares-pour-la-carte-réseau)
* [Post-installation `phase 2`](#post-installation-phase-2)


## Vue d'ensemble

Une fois le dispositif en place, son utilisation est relativement simple.

Voici les étapes à suivre :

* démarrer une machine en `pxe` (touche `F12`)
* choisir une des installations proposées

Ensuite, tout se déroulera de façon automatique, sans intervention de votre part :

* installation du système (**phase 1**)
* 1er redémarrage
* post-installation et intégration au domaine `se3` (**phase 2**)
* 2ème redémarrage

On obtient ainsi un client `Gnu/Linux` sur lequel on peut ouvrir une session avec un des comptes disponibles dans l'annuaire du `se3`.


## Démarrage en `pxe`

Pour amorcer une machine via le réseau, avec `pxe`, appuyez sur la touche `F12` lors du démarrage de cet ordinateur.
![menu pxe demmarage](/doc/images/menu_pxe_demarrage.png)

**Remarque :** il faut que le mode `pxe` soit activé dans le `Bios` de l'ordinateur.

Selon les ordinateurs, l'activation de ce mode `pxe` est plus ou moins aisé.

Ainsi sur certains ordinateurs de la marque `Fujitsu`, son activation n'est possible que si auparavant on a activé le mode `Low power`. On se demande bien pourquoi ces constructeurs s'ingénient à cacher ces fonctions, dans le genre "pourquoi faire simple quand on peut faire compliqué…".


## Menus `pxe` disponibles

**Remarque :** la navigation dans les menus `pxe` se fait à l'aide des touches `↑` et `↓` ; pour sélectionner une des entrées du menu, il suffit d'utiliser la touche `Entrée`.

Une 1ère étape est proposée afin de sécuriser ce mode de fonctionnement : après avoir choisi l'entrée `Maintenance`…
![menu pxe entrée](/doc/images/menu_pxe_entree.png)
… un mot de passe est requis.

Ensuite, choisissez l'entrée `Installation`…
![menu pxe maintenance](/doc/images/menu_pxe_maintenance.png)

… et enfin une des entrées `Installation Debian` ou `Installation Ubuntu`.
![menu pxe installation](/doc/images/menu_pxe_installation.png)

Vous pourrez alors choisir `l'environnement de Bureau` à installer, selon les architectures `i386` et `amd64` et selon qu'un système d'exploitation est déjà installé (à condition d'avoir laissé un espace vide non formaté) pour obtenir un `double-boot`.
![menu pxe debian](/doc/images/menu_pxe_debian.png)
→ dans ce menu, `Gnome` est l'environnement de Bureau proposé.


## Installation du système (phase 1)

L'installation du système choisi se fait automatiquement.
![menu pxe preseed](/doc/images/menu_pxe_preseed.png)

### Les firmwares pour la carte réseau

Les micro-programmes (ou `firmwares`) pour la carte réseau ne sont plus à fournir via une clé `usb` : ils ont été incorporés au fichier d'amorçage `initrd.gz`. Cependant, vous pourrez trouver ces `firmwares` sur [le site de Debian dédié à la diffusion des images d'installation](http://cdimage.debian.org/cdimage/unofficial/non-free/firmware/jessie/current/).


### Problèmes éventuels lors de la phase 1

**Problème :** sur certaines machines, au début, après avoir choisi et lancé l'installation, l'installation se fige sur un fond bleu… En passant sur la 4ème console qui donne les `syslog` (avec la combinaison de touches `Ctrl+Alt+F4`) on reste bloqué sur les lignes suivantes :
```ssh
check missing firmware, installing package /firmware/firmare-linux-nonfree_0.43_all.deb
check missing firmware : removing and loading kernel module tg3
```
C'est donc un problème concernant un des firmwares à fournir qui est pourtant bien dans les firmwares incorporés.


**Solution :** En passant sur la fenêtre principale (à l'aide de la combinaison de touches `Ctrl+c`), le script est relancé et ça passe....Ce doit être un bug de l'installeur AMHA, donc pas grand chose à faire…


### Fichiers de log de la phase 1

Des fichiers de log de la phase 1 sont disponibles dans `/var/log/installer/syslog`.


## Post-installation (phase 2)

Une fois le système installé, la machine redémarre et la post-installation est lancée automatiquement.
![menu pxe post-installation](/doc/images/menu_pxe_post_installation.png)

Au redémarrage suivant, le client `GNU∕Linux` est prêt ;-) et son administration se fait via le paquet `se3-clients-linux`.

Un compte-rendu de cette `phase 2` est disponible avec le fichier `/root/compte_rendu_post-install_ladate.txt`.


