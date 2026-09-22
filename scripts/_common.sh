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

arcenal_lire_reglage() {
    local cle="$1"
    local valeur
    valeur="$(ynh_app_setting_get --key="$cle")"
    printf '%s' "$valeur"
}

arcenal_enregistrer_reglage() {
    local cle="$1"
    local valeur="$2"
    ynh_app_setting_set --key="$cle" --value="$valeur"
}

arcenal_domaine_principal() {
    yunohost domain main-domain --output-as json | python3 -c '
import json
import sys

print(json.load(sys.stdin)["current_main_domain"])
'
}

arcenal_initialiser_identite() {
    local domaine_principal domaine_portail
    domaine_principal="$(arcenal_domaine_principal)"
    domaine_portail="$(arcenal_lire_reglage portal_domain)"
    if [[ "$domaine_portail" == "current_main_domain: "* ]]; then
        arcenal_enregistrer_reglage portal_domain "$domaine_principal"
    fi
    test -n "$domaine_portail" || arcenal_enregistrer_reglage portal_domain "$domaine_principal"
    test -n "$(arcenal_lire_reglage portal_title)" || arcenal_enregistrer_reglage portal_title "ARCenal OS"
    test -n "$(arcenal_lire_reglage portal_theme)" || arcenal_enregistrer_reglage portal_theme "light"
    test -n "$(arcenal_lire_reglage portal_tile_theme)" || arcenal_enregistrer_reglage portal_tile_theme "descriptive"
    test -n "$(arcenal_lire_reglage brand_primary)" || arcenal_enregistrer_reglage brand_primary "#202229"
    test -n "$(arcenal_lire_reglage brand_accent)" || arcenal_enregistrer_reglage brand_accent "#842F47"
    test -n "$(arcenal_lire_reglage portal_user_intro)" || arcenal_enregistrer_reglage portal_user_intro "Bienvenue dans votre espace ARCenal."
    test -n "$(arcenal_lire_reglage portal_public_intro)" || arcenal_enregistrer_reglage portal_public_intro "Connectez-vous pour accéder à vos services ARCenal."
}

arcenal_css_portail() {
    local primaire="$1"
    local accent="$2"
    cat <<CSS
:root { --arcenal-primary: ${primaire}; --arcenal-accent: ${accent}; }
body { background: #f7f5f0; }
a, .text-primary { color: var(--arcenal-accent); }
.bg-primary, .btn-primary { background-color: var(--arcenal-primary) !important; border-color: var(--arcenal-primary) !important; }
CSS
}

arcenal_appliquer_identite() {
    local domaine titre theme tuiles intro_utilisateur intro_public primaire accent
    domaine="$(arcenal_lire_reglage portal_domain)"
    titre="$(arcenal_lire_reglage portal_title)"
    theme="$(arcenal_lire_reglage portal_theme)"
    tuiles="$(arcenal_lire_reglage portal_tile_theme)"
    intro_utilisateur="$(arcenal_lire_reglage portal_user_intro)"
    intro_public="$(arcenal_lire_reglage portal_public_intro)"
    primaire="$(arcenal_lire_reglage brand_primary)"
    accent="$(arcenal_lire_reglage brand_accent)"
    yunohost domain config set "$domaine" --key feature.portal.portal_title --value "$titre"
    yunohost domain config set "$domaine" --key feature.portal.portal_theme --value "$theme"
    yunohost domain config set "$domaine" --key feature.portal.portal_tile_theme --value "$tuiles"
    yunohost domain config set "$domaine" --key feature.portal.portal_user_intro --value "$intro_utilisateur"
    yunohost domain config set "$domaine" --key feature.portal.portal_public_intro --value "$intro_public"
    yunohost domain config set "$domaine" --key feature.portal.custom_css --value "$(arcenal_css_portail "$primaire" "$accent")"
}
