# ARCenal Système pour YunoHost

Ce paquet unique configure un YunoHost pour consommer le catalogue ARCenal
stable et fournit l'espace personnel `/espace-perso`.

L'espace s'appuie sur l'authentification native YunoHost : il ne stocke aucun
mot de passe ni aucune liste d'accès propre. Après connexion, il affiche le
prénom, les applications autorisées pour l'utilisateur, une dernière nouvelle
configurable et l'entrée Administration uniquement aux membres du groupe
`admins`.

Le paquet ne modifie ni le cœur de YunoHost ni sa WebAdmin. Il installe son
propre fragment Nginx avec le helper officiel YunoHost afin de servir
`/espace-perso` sur le domaine racine choisi dans le panneau ARCenal.

## Installation

```sh
sudo yunohost app install https://github.com/arcenal-coder/arcenal-systeme_ynh
```

L'installateur vérifie l'accessibilité HTTPS du catalogue, sauvegarde la
configuration précédente, active le catalogue ARCenal puis actualise le cache.
La désinstallation restaure la configuration de catalogue sauvegardée.

## Utilisation

Après installation ou mise à jour, ouvrez :

```text
https://votre-domaine/espace-perso/
```

Les réglages « Identité ARCenal » dans la WebAdmin permettent notamment de
modifier l'identité du portail natif et le contenu de la dernière nouvelle.
Le point d'entrée technique `/yunohost/sso/` reste nécessaire à la connexion
native et ne doit pas être supprimé.

### Migration depuis une version antérieure à 0.5

Les installations déjà rebrandées par une version antérieure ne possèdent pas
d'instantané de leur identité visuelle d'origine. À partir de la version 0.5,
ARCenal Système sauvegarde l'identité du portail avant toute modification et la
restaure lors de sa désinstallation. Pour une ancienne installation, effectuez
une sauvegarde YunoHost avant la première mise à jour 0.5 si ce retour à l'état
antérieur peut être nécessaire.
