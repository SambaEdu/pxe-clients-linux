# Liste des applications à installer


* [Objectifs](#objectifs)
* [Les paquets installés](#les-paquets-installés)
    * [Liste pour la distribution](#liste-pour-la-distribution)
    * [Liste pour l'environnement de Bureau](#liste-pour-lenvironnement-de-bureau)
    * [La liste perso](#la-liste-perso)


# Objectifs

Des applications ont été sélectionnées pour que l'utilisateur ait à sa disposition des applications qui pourront être utiles pour ses diverses activités.

D'autres applications sont installées pour faciliter l'administration des `clients-linux`.

**Remarque :** par la suite, des applications pourront être installés sur les `clients-linux` à l''aide du mécanisme des scripts `unefois` (voir la documentation du paquet `se3-clients-linux`)


# Les paquets installés

Les applications sont installées à plusieurs moments du processus.

Durant la **phase 1** (installation de la distribution), les paquets suivants sont installés :

`distribution Debian` : openssh-server mc tofrodos conky sqlite3 ldap-utils zip unzip tree screen vim vlc ssmtp ntp gnome-tweak-tool geogebra

`distribution Ubuntu` : openssh-server ldap-utils zip unzip tree screen vim vlc ssmtp ntp evince geogebra


Durant la **phase 2** (post-installation et intégration), les paquets installés sont issus de 3 listes :

* liste concernant la distribution (`Debian` ou `Ubuntu`)
* liste concernant `l'environnement de Bureau`
* liste perso à la discrétion de l'administrateur du serveur `se3`


## Liste pour la distribution

Selon la distribution installée, `Debian` ou `Ubuntu`, cette liste se nommera `mesapplis-debian.txt` ou `mesapplis-ubuntu.txt`.


## Liste pour l'environnement de Bureau


Selon l'environnement de Bureau choisi, Gnome, Ldce ou Xfce, cette liste se nommera `mesapplis-debian-gnome.txt`, `mesapplis-debian-ldxe.txt` ou `mesapplis-debian-xfce.txt`.


## La liste perso

Enfin, une liste perso permettra à l'administrateur de rajouter des paquets à sa convenance. Cette liste se nomme `mesapplis-debian-perso.txt`.


