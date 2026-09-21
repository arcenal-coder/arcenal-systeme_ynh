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

arcenal_ecrire_portail() {
    local dossier_source
    local dossier_portail="/var/www/${app}"
    dossier_source="$(cd "$(dirname "${BASH_SOURCE[0]}")/../www" && pwd)"
    install -d -m 0755 "$dossier_portail"
    install -m 0644 "$dossier_source/index.html" "$dossier_portail/index.html"
    install -m 0644 "$dossier_source/arcenal.css" "$dossier_portail/arcenal.css"
    install -m 0644 "$dossier_source/logo-arcenal.svg" "$dossier_portail/logo-arcenal.svg"
}

arcenal_ecrire_configuration_nginx() {
    local domaine="$1"
    local dossier_configuration="/etc/nginx/conf.d/${domaine}.d"
    install -d -m 0755 "$dossier_configuration"
    cat > "${dossier_configuration}/${app}.conf" <<'NGINX'
location = /arcenal {
    return 301 /arcenal/;
}

location ^~ /arcenal/ {
    alias /var/www/arcenal-systeme/;
    index index.html;
    try_files $uri $uri/ =404;
}
NGINX
}

arcenal_activer_portail() {
    local domaine="$1"
    arcenal_ecrire_portail
    arcenal_ecrire_configuration_nginx "$domaine"
    nginx -t || ynh_die "La configuration Nginx du portail ARCenal est invalide."
    systemctl reload nginx
}

arcenal_retirer_portail() {
    local domaine="$1"
    rm -f "/etc/nginx/conf.d/${domaine}.d/${app}.conf"
    rm -rf "/var/www/${app}"
    nginx -t || ynh_die "Nginx reste invalide après le retrait du portail ARCenal."
    systemctl reload nginx
}
