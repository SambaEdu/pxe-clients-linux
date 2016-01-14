# Mise en place du dispositif d'installation de clients `Gnu/Linux`

…documentation en cours d'écriture…

* [Prérequis](#prérequis)
    * [Côté serveur `se3`](#côté-serveur-se3)
        * [Serveur `se3` à jour](#serveur-se3-à-jour)
        * [Module `TFTP` installé](#module-TFTP-installé)
        * [Module `se3-clients-linux` installé](#module-se3-clients-linux-installé)
    * [Côté `client linux`](#côté-client-linux)
        * [Mode `PXE`](#mode-pxe)
        * [Présence éventuelle d'autres systèmes d'exploitation](#présence-éventuelle-d-autres-systèmes-dexploitation)
* [Configuration du serveur `TFTP`](#configuration-du-serveur-tftp)


## Prérequis

### Côté serveur `se3`

#### Serveur `se3` à jour

Mettre à jour le Se3. Ce dernier doit impérativement être en version Squeeze.


#### Module `TFTP` installé

Il faut que le module Clonage des stations (Se3-clonage) dit TFTP soit installé. Si c'est le cas vérifiez qu'il est bien dans la dernière version : 0.66 au minimum. Sinon installez le module puis activez le mode graphique et mettez un mot de passe. Voir cette documentation, .


#### Module `se3-clients-linux` installé

Si vous souhaitez intégrer vos clients Debian Linux au domaine SE3, il vous faut aussi installer le module `se3-clients-linux`. Voir cette documentation . S'il est déjà installé, vérifiez qu'il est bien dans la dernière version.


### Côté `client linux`

#### Mode `PXE`

Le client doit pouvoir démarrer en mode `PXE`. Ce mode est lancé au démarrage en utilisant la touche `F12`.

Il faut que le mode `PXE` soit activé dans le `Bios` de l'ordinateur. Selon les ordinateurs, l'activation de ce mode `PXE` est plus ou moins aisé.

Ainsi sur certains ordinateurs de la marque `Fujitsu`, son activation n'est possible que si auparavant on a activé le mode `Low power`. On se demande bien pourquoi ces constructeurs s'ingénient à cacher ces fonctions, dans le genre "pourquoi faire simple quand on peut faire compliqué…".

Sur d'autres ordinateurs, ce mode peut être nommé à l'aide d''une expression contenant l'abréviation `NIC`.


#### Présence éventuelle d'autres systèmes d'exploitation

La machine sur laquelle vous désirez installer un client-linux contient la plupart du temps un ou plusieurs systèmes d'exploitation.

Deux options s'offrent à vous : soit vous ne voulez plus utiliser ces systèmes d'exploitation, soit vous désirez les garder.

Dans le premier cas, il suffira de lancer une installation en `simple-boot`.

Dans le second cas, il faudra laisser un espace libre à côté des partitions contenant les systèmes d'exploitation déjà présent et lancer une installation en `double-boot`. Au besoin, pour cela, vous réinstallez ces systèmes d'exploitation.


## Configuration du serveur TFTP




