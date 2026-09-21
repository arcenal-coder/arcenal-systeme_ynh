# ARCenal Système pour YunoHost

Ce paquet configure un YunoHost pour consommer le catalogue ARCenal stable et
installe un portail d'accueil ARCenal à l'adresse `https://domaine/arcenal/`.
Il ne modifie ni le cœur de YunoHost ni sa WebAdmin : le portail oriente vers
l'administration native, qui conserve son fonctionnement et ses mises à jour.

## Installation

```sh
sudo yunohost app install https://github.com/arcenal-coder/arcenal-systeme_ynh
```

L'installateur vérifie l'accessibilité HTTPS du catalogue, sauvegarde la
configuration précédente, active le catalogue ARCenal, installe le portail et
actualise le cache. La désinstallation retire uniquement les fichiers du
portail ARCenal et restaure la configuration de catalogue sauvegardée.
