# ARCenal Système pour YunoHost

Ce paquet configure un YunoHost pour consommer le catalogue ARCenal stable.
Il ne modifie ni le cœur de YunoHost, ni sa WebAdmin, ni Nginx directement.

## Installation

```sh
sudo yunohost app install https://github.com/arcenal-coder/arcenal-systeme_ynh
```

L'installateur vérifie l'accessibilité HTTPS du catalogue, sauvegarde la
configuration précédente, active le catalogue ARCenal puis actualise le cache.
La désinstallation restaure la configuration de catalogue sauvegardée.
