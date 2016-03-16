# Mise en forme du skel pour Jessie


## favoris (activités)
→ Iceweasel

→ Shutter

→ Fichiers

→ Terminal

→ Afficher les applications


## paramètres
→ confidentialités

→ énergie


## outils de personnalisation
→ affichage du Bureau

→ espaces de travail

→ extension

→ fenêtres : boutons de la barre de titre


## préférences de fichiers
→ vue en liste

→ comportement


## dans le skel : répertoire .local
→ .local/share/gnome-shell/extensions/logoutbutton@mike10004.github.com


## éditeur dconf
→ org/gnome/desktop/screensaver/user-switch-enabled à décocher

→ org/gnome/desktop/lockdown/disabled-user-switching

→ org/gnome/desktop/lockdown/disabled-lock-screensaver

→ org/gnome/gnome-session/logout-prompt (à décocher)


## dans le skel : répertoire .config
→ dconf (qui contient le fichier user, à modifier après tout réglage)

→ user-dirs.dirs :
* répertoires à configurer : Documents, Bureau, Images, Téléchargements, Vidéos, Musique
* répertoires vides dans le skel
* montage du répertoire Docs de l'utilisateur (voir la doc) dans le répertoire Documents : https://github.com/SambaEdu/se3-docs/blob/master/se3-clients-linux/logon_perso.md#la-fonction-creer_lien

→ user-dirs.locale


## profil iceweasel
→ paramètres réseaux

→ page d'accueil (duckduckgo ?)

→ favoris : interface se3 (accès à l'annuaire)


## enregistrer le skel
→ modifier .VERSION

→ lancer reconfigure.bash (clients-linux/bin)


