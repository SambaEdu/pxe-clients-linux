# Utilisation du dispositif d'installation de clients `Gnu/Linux`

* [Vue d'ensemble](#vue-densemble)
* [Démarrage en `pxe`](#démarrage-en-pxe)
* [Menus pxe disponibles](#menus-pxe-disponibles)


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

Pour amorcer une machine via le réseau, avec `pxe`, il faut que ce mode soit activé dans le `Bios` de l'ordinateur.

Selon les ordinateurs, l'activation de ce mode `pxe` est plus ou moins aisé.

Ainsi sur certains ordinateurs de la marque `Fujitsu`, son activation n'est possible que si auparavant on a activé le mode `Low power`. On se demande bien pourquoi ces constructeurs s'ingénient à cacher ces fonctions, dans le genre "pourquoi faire simple quand on peut faire compliqué…".


## Menus pxe disponibles

Une 1ère étape est proposée afin de sécuriser ce mode de fonctionnement : après avoir choisi l'entrée `Maintenance`, un mot de passe est requis.

Ensuite, il faudra choisir l'entrée `Installation` et enfin une des entrées `Installation Debian` ou `Installation Ubuntu`.

Enfin, vous pourrez choisir `l'environnement de Bureau` à installer, selon les architectures `i386` et `amd64` et selon qu'un système d'exploitation est déjà installé (à condition d'avoir laissé un espace vide non formaté) pour obtenir un `double-boot`.

