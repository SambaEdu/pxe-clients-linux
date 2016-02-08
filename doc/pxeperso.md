# Menu pxe `perso.menu`

* [Vue d'ensemble](#vue-densemble)
* [Mise en place](#mise-en-place)
* [Exemples d'utilisation](#exemples-dutilisation)
    * [Gparted](#gparted)
        * [Mise en place des fichiers de `GParted`](#mise-en-place-des-fichiers-de-gparted)
            * [Télécharger l'archive](#télécharger-larchive)
            * [Copier les fichiers d'amorçage](#copier-les-fichiers-damorçage)
            * [Copier le fichier de fonctionnement de `GParted`](#copier-le-fichier-de-fonctionnement-de-gparted)
            * [Gestion du répertoire temporaire](#gestion-du-répertoire-temporaire)
        * [Mise en place du menu pxe](#mise-en-place-du-menu-pxe)
        * [Utilisation](#utilisation)
    * [Installer `Debian Stretch`](#installer-debian-stretch)


## Vue d'ensemble

Le répertoire `/tftpboot/pxelinux.cfg/` du serveur `se3` contient des menus qui permettent d'amorcer des outils ou les installateurs des systèmes d'exploitation `Debian` ou `Ubuntu` :

* default
* maintenance.menu
* peripheriques.menu
* test.menu
* clonage.menu
* linux.menu
* install.menu
* inst_buntu.cfg
* inst_debian.cfg

Ces menus peuvent être modifiés mais ces modifications ne seront pas conservées suite à une mise à jour du paquet `se3-clonage`.

Si vous souhaitez utiliser un menu à votre convenance et qui soit perenne, cela est possible : il suffit d'ajouter un fichier `perso.menu` dans le répertoire `/tftpboot/pxelinux.cfg/`.

Le fichier `perso.menu` contiendra les commandes d'amorçages via le mécanisme `pxe` que vous souhaitez mettre en place. Des exemples sont donnés ci-dessous.



## Mise en place

Dans le répertoire `/tftpboot/pxelinux.cfg/`, créez le fichier `perso.menu` :
```ssh
touch /tftpboot/pxelinux.cfg/perso.menu
```

Remettez à jour le module `se3-clonage` :
```ssh
apt-get install se3-clonage
```

Dans le menu `maintenance.menu`, il apparaîtra maintenant une entrée vers votre menu perso.
![menu pxe maintenance](/doc/images/menu_pxe_maintenance.png)


**Menu de base :**

Au début du fichier `perso.menu`, mettez les commandes qui permettent de revenir au menu précédent qui est le menu `maintenance.menu` :
```ssh
menu title Perso

LABEL Menu_principal
    MENU LABEL ^Retour au menu Maintenance
    KERNEL menu.c32
    APPEND pxelinux.cfg/maintenance.menu

LABEL #####

```

Par la suite, vous compléterez ce fichier `perso.menu` par les entrées nécessaires aux applications que vous souhaitez utiliser. Quelques exemples sont donnés ci-dessous.


## Exemples d'utilisation

### Gparted

`GParted` (GNOME Partition Editor) sert à créer, supprimer, redimensionner, déplacer, vérifier et copier des partitions, et les systèmes de fichiers qui s’y trouvent. Il peut être notamment utilisé pour faire de la place en vue d’installer un nouveau système d’exploitation, réorganiser l’utilisation du disque, copier les données résidentes sur des disques durs et effectuer une copie d’une partition sur un autre disque. [Une documentation](http://gparted.sourceforge.net/display-doc.php?name=help-manual&lang=fr) est disponible pour toutes ces opérations.

Pour utiliser `GParted` via le réseau, il faut mettre en place les commandes d'amorçage dans le fichier `perso.menu` et les fichiers nécessaires lors de cet amorçage et lors de l'utilisation.


#### Mise en place des fichiers de `GParted`

Les indications qui suivent sont issues de [la documentation `GParted live on PXE Server`](http://gparted.sourceforge.net/livepxe.php). Nous vous recommendons de suivre cette documentation si des changements sont nécessaires lors de mises à jour ultérieures de `GParted`.

##### Télécharger l'archive

Téléchargez l'archive (dans la commande, on a pris celle correspondant à l'architecture `amd64` mais on pourra utiliser aussi celle correspondant à `i686` ou à `i686-pae`) contenant le nécessaire dans un répertoire temporaire et décompressez-la :
```ssh
mkdir /tftpboot/tempgparted
wget -P /tftpboot/tempgparted http://sourceforge.net/projects/gparted/files/gparted-live-stable/0.25.0-1/gparted-live-0.25.0-1-amd64.zip
mkdir -p /tftpboot/tempgparted/gparted
unzip /tftpboot/tempgparted/gparted-live-*-amd64.zip -d /tftpboot/tempgparted/gparted/
```

**Remarque :** la version de `GParted` pouvant évoluer, il faudra adapter la commande de téléchargement ci-dessus.


##### Copier les fichiers d'amorçage

Les fichiers pour l'amorçage sont à placer dans un sous-répertoire de `/tftpboot` : *gparted* par exemple.
```ssh
mkdir -p /tftpboot/gparted
cp /tftpboot/tempgparted/gparted/live/{vmlinuz,initrd.img} /tftpboot/gparted/
```

##### Copier le fichier de fonctionnement de `GParted`

Le fichier nécessaire au fonctionnement *live* de `GParted` est à placer dans une partie accessible via le réseau : dans le répertoire `/var/www/` du serveur `se3`.

Vous pourriez créer un répertoire */var/www/gparted* mais lors d'une réinstallation ou d'une migration vers un nouveau serveur `se3`, il faudrait le remettre en place. Le mieux est donc de le placer dans le répertoire `/home/netlogon/clients_linux/install/messcripts_perso/` comme cela il sera sauvegardé et restauré en cas de changement de serveur :
```ssh
mkdir -p /home/netlogon/clients-linux/install/messcripts_perso/gparted
cp /tftpboot/tempgparted/gparted/live/filesystem.squashfs /var/www/install/messcripts_perso/gparted/
```

##### Gestion du répertoire temporaire

Une fois les fichiers en place, on peut supprimer quelques éléments dans le répertoire temporaire `/tftpboot/tempgparted`. On pourrait le supprimer mais il est intéressant de le garder avec l'archive téléchargée pour se souvenir de la version de `Gparted` mise en place.

```ssh

```


#### Mise en place du menu pxe

Dans le fichier `perso.menu`, rajoutez les lignes suivantes (en remplaçant *IP-du-se3* par la valeur correspondant à votre réseau) :
```ssh
LABEL GParted
    MENU LABEL GParted pour la gestion des partitions
    kernel gparted/vmlinuz
    append initrd=gparted/initrd.img boot=live config components union=overlay username=user noswap noeject ip= vga=788 fetch=http://IP-du-se3/install/messcripts_perso/gparted/filesystem.squashfs
    TEXT HELP
    Utilisation de Gparted par le reseau
    ENDTEXT
```

**Remarque :** la version de `GParted` pouvant évoluer, il faudra adapter, si cela est nécessaire, les paramètres de la ligne *append* ci-dessus. Un coup d'œil dans [la documentation `Gparted live`](http://gparted.sourceforge.net/livepxe.php) pourra être utile…


#### Utilisation

Il suffit de démarrer le client via le mode `pxe` (touche `F12`) et ensuite de choisir le menu `perso` et l'entrée `Gparted`.

Lors de la mise en place de `GParted`, il est demandé quelques précisions :

* le clavier

![gparted keymap](/doc/images/gparted_01.png)

Il suffira de taper sur la touche `Entrée`.

* la langue d'usage

![gparted langue](/doc/images/gparted_02.png)

Pour le français, indiquez `08`.

* mode d'utilisation

![gparted mode](/doc/images/gparted_03.png)

Il suffira de taper sur la touche `Entrée`.

Enfin, on obtient l'interface de gestion des partitions du client.

![gparted interface](/doc/images/gparted_04.png)


### Installer `Debian Stretch`

… *à venir* …
