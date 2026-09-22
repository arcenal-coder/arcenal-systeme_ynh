# ARCenal Système pour YunoHost

Ce paquet fournit l'espace personnel ARCenal `/espace-perso`. Le catalogue est
installé séparément par le paquet ARCenal Store afin de garder le parcours
administrateur simple et fiable.

L'espace s'appuie sur l'authentification native YunoHost : il ne stocke aucun
mot de passe ni aucune liste d'accès propre. Après connexion, il affiche le
prénom, les applications autorisées pour l'utilisateur, une dernière nouvelle
configurable et l'entrée Administration uniquement aux membres du groupe
`admins`.

Le paquet ne modifie ni le cœur de YunoHost ni sa WebAdmin. Il installe son
propre fragment Nginx avec le helper officiel YunoHost afin de servir
`/espace-perso` sur le domaine racine choisi dans le panneau ARCenal.

## Installation

Après avoir installé ARCenal Store, recherchez « ARCenal Système » dans
**Applications → Installer une app**, choisissez le domaine racine et laissez
le chemin proposé `/espace-perso`.

## Utilisation

Après installation ou mise à jour, ouvrez :

```text
https://votre-domaine/espace-perso/
```

Les réglages « Identité ARCenal » dans la WebAdmin permettent notamment de
modifier l'identité du portail natif et le contenu de la dernière nouvelle.
Le point d'entrée technique `/yunohost/sso/` reste nécessaire à la connexion
native et ne doit pas être supprimé.

## Diffusion et mises à jour ARCenal

ARCenal Système vérifie quotidiennement la diffusion `stable` validée par
ARCenal. Il met à jour uniquement ARCenal Store puis ARCenal Système, avec les
sauvegardes pré-mise à jour natives de YunoHost. Il ne met jamais à jour le
cœur YunoHost ni les applications métier.

Dans le panneau « Mises à jour ARCenal », l'administrateur peut désactiver ce
comportement (`manual`) ou remplacer l'URL HTTPS de diffusion. Les détails et
les éventuelles erreurs sont disponibles dans le journal système
`arcenal-systeme-update.service`.

### Migration depuis une version antérieure à 0.6

Avant de mettre à jour une ancienne installation, installez d'abord ARCenal
Store. La version 0.6 et les suivantes vérifient volontairement sa présence,
afin que le catalogue et l'espace personnel ne puissent plus être séparés par
erreur.

Les installations déjà rebrandées par une version antérieure ne possèdent pas
d'instantané de leur identité visuelle d'origine. À partir de la version 0.5,
ARCenal Système sauvegarde l'identité du portail avant toute modification et la
restaure lors de sa désinstallation. Pour une ancienne installation, effectuez
une sauvegarde YunoHost avant la première mise à jour 0.5 si ce retour à l'état
antérieur peut être nécessaire.
