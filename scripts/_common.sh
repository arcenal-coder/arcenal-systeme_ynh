#!/bin/bash

arcenal_exiger_url_catalogue() {
    [[ "$catalogue_url" =~ ^https://[^[:space:]]+$ ]] || ynh_die "Le catalogue ARCenal doit utiliser une URL HTTPS."
}

arcenal_verifier_catalogue() {
    curl --fail --silent --show-error "${catalogue_url}/v3/apps.json" > /dev/null || ynh_die "Le catalogue ARCenal est indisponible ou invalide."
}

arcenal_ecrire_catalogue() {
    cat > /etc/yunohost/apps_catalog.yml <<YAML
- id: arcenal
  url: ${catalogue_url}
YAML
}

arcenal_actualiser_catalogue() {
    yunohost tools update apps
}
