# Mise en place du dispositif d'installation de clients `Gnu/Linux`

…documentation en cours d'écriture…

* [Prérequis](#prérequis)
    * [Côté serveur `se3`](#côté-serveur-se3)
        * [Serveur `se3` à jour](#serveur-se3-à-jour)
        * [Module `TFTP` installé](#module-TFTP-installé)
        * [Module `se3-clients-linux` installé](#module-se3-clients-linux-installé)
    * [Côté `client linux`](#côté-client-linux)
        * [Mode `PXE`](#mode-pxe)
        * [Présence éventuelle d'autres systèmes d'exploitation](#présence-éventuelle-dautres-systèmes-dexploitation)
* [Configuration du serveur `TFTP`](#configuration-du-serveur-tftp)
    * [Le mot de passe](#le-mot-de-passe)
    * [Les environnements de Bureau](#les-environnements-de-bureau)
    * [Le miroir local](#le-miroir-local)


## Prérequis

### Côté serveur `se3`

#### Serveur `se3` à jour

Mettre à jour le serveur `se3`. Ce dernier doit impérativement être en version `Squeeze` ou `Wheezy`.


#### Module `TFTP` installé

Il faut que le module `se3-clonage`, dit `TFTP`, soit installé.

Si c'est le cas vérifiez qu'il est bien dans la dernière version : 0.66 au minimum (le mettre à jour si nécessaire).

Sinon installez le module puis activez le mode graphique via l'interface web du serveur `se3`.

Mettez **un mot de passe** : cela évitera l'utilisation intempestive du mode `PXE` des ordinateurs de votre réseau par les utilisateurs.


#### Module `se3-clients-linux` installé

Si vous souhaitez intégrer vos clients Linux au domaine `se3`, il vous faut aussi installer le module `se3-clients-linux`.

S'il est déjà installé, vérifiez qu'il est bien dans la dernière version : 2.0 au minimum (le mettre à jour si nécessaire).

Sinon installez le module puis activez le mode graphique via l'interface web du serveur `se3`.


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

Dans le second cas, il faudra laisser **un espace libre** à côté des partitions contenant les systèmes d'exploitation déjà présents et lancer une installation en `double-boot`. Au besoin, pour cela, vous réinstallez ces systèmes d'exploitation.


## Configuration du serveur TFTP

### Le mot de passe

Nous en avons déjà parlé dans les prérequis : indispensable !


### Les environnements de Bureau

Choisissez votre environnement de Bureau parmi ceux proposés dans l'interface web du `se3` :

* `Gnome`
* `Lxde`
* `Xfce`

Vous pouvez en choisir plusieurs mais nous vous conseillons de n'en choisir qu'un seul. La plus utilisée est `Gnome`, les autres étant plus légères : votre choix tiendra compte du matériel sur lequel vous faite l'installation et de votre familiarité avec l'un ou l'autre de ces environnements de Bureau. Vous pourrez bien entendu revenir sur ce choix.

Vous pouvez aussi choisir **une installation manuelle** : il faudra alors répondre aux questions posées lors de l'installation du système d'exploitation.

**Remarque :** le choix de la distribution, `Debian` ou `Ubuntu`, sera fait lors de l'utilisation du dispositif, devant le `client-linux` à installer, via le mode `PXE`.

La validation du ou des choix effectués déclenchera la mise en place du dispositif.


### Le miroir local

Le serveur `se3`, s'il est à jour, propose un miroir local par le biais du paquet `apt-cacher-ng`.

Ce système permet une gestion souple et efficace des paquets.

Cependant, si vous désirez gérer votre propre miroir local sur un autre serveur, cela est possible en cochant la case correspondante, en indiquant son adresse `IP` et le chemin du miroir sur ce serveur distant. Dans ce cas là, il faudra redéclencher la mise en place du dispositif comme cela est indiqué ci-dessus.

