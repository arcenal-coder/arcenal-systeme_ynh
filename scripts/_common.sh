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

arcenal_domaine_portail_par_defaut() {
    yunohost domain list --exclude-subdomains --output-as json | python3 -c '
import json
import sys

domains = json.load(sys.stdin)["domains"]
print(domains[0])
'
}

arcenal_domaine_portail_est_racine() {
    local domaine="$1"
    yunohost domain list --exclude-subdomains --output-as json | python3 -c '
import json
import sys

raise SystemExit(0 if sys.argv[1] in json.load(sys.stdin)["domains"] else 1)
' "$domaine"
}

arcenal_initialiser_identite() {
    local domaine_defaut domaine_portail
    domaine_defaut="$(arcenal_domaine_portail_par_defaut)"
    domaine_portail="$(arcenal_lire_reglage portal_domain)"
    arcenal_domaine_portail_est_racine "$domaine_portail" || arcenal_enregistrer_reglage portal_domain "$domaine_defaut"
    test -n "$(arcenal_lire_reglage portal_title)" || arcenal_enregistrer_reglage portal_title "ARCenal OS"
    test -n "$(arcenal_lire_reglage portal_theme)" || arcenal_enregistrer_reglage portal_theme "light"
    test -n "$(arcenal_lire_reglage portal_tile_theme)" || arcenal_enregistrer_reglage portal_tile_theme "descriptive"
    test -n "$(arcenal_lire_reglage portal_layout)" || arcenal_enregistrer_reglage portal_layout "confortable"
    test -n "$(arcenal_lire_reglage brand_primary)" || arcenal_enregistrer_reglage brand_primary "#202229"
    test -n "$(arcenal_lire_reglage brand_accent)" || arcenal_enregistrer_reglage brand_accent "#842F47"
    test -n "$(arcenal_lire_reglage portal_user_intro)" || arcenal_enregistrer_reglage portal_user_intro "Bienvenue dans votre espace ARCenal."
    test -n "$(arcenal_lire_reglage portal_public_intro)" || arcenal_enregistrer_reglage portal_public_intro "Connectez-vous pour accéder à vos services ARCenal."
}

arcenal_css_portail() {
    local primaire="$1"
    local accent="$2"
    local mise_en_page="$3"
    cat <<CSS
:root { --arcenal-primary: ${primaire}; --arcenal-accent: ${accent}; --arcenal-ink: #172b36; --arcenal-surface: #fffdf9; --arcenal-muted: #52636b; --arcenal-border: #d9e0df; }
body { background: #f4f2ed; color: var(--arcenal-ink); }
header { border-bottom: 1px solid var(--arcenal-border); padding-bottom: 1.25rem !important; }
header .profile, header .profile .opacity-50, header p { color: var(--arcenal-ink) !important; opacity: 1; }
header .profile .opacity-50 { color: var(--arcenal-muted) !important; }
main { max-width: 1180px; width: 100%; margin: 0 auto; }
a, .link, .text-primary { color: var(--arcenal-accent); }
a:hover, .link:hover { color: var(--arcenal-primary); }
.btn-primary { background-color: var(--arcenal-primary) !important; border-color: var(--arcenal-primary) !important; color: #fff !important; }
#app-tiles .app-tile { background: var(--arcenal-surface); border: 1px solid var(--arcenal-border); box-shadow: 0 10px 24px rgb(23 43 54 / 8%); border-radius: 1rem; color: var(--arcenal-ink); transition: transform 160ms ease, box-shadow 160ms ease, border-color 160ms ease; }
#app-tiles .app-tile:hover, #app-tiles .app-tile:focus-within { background: #fff; border-color: var(--arcenal-accent); box-shadow: 0 16px 30px rgb(23 43 54 / 14%); transform: translateY(-2px); }
#app-tiles .app-label a, #app-tiles .app-description { color: var(--arcenal-ink); }
#app-tiles .app-description { color: var(--arcenal-muted); line-height: 1.5; }
#app-tiles .app-logo { box-shadow: 0 6px 18px rgb(23 43 54 / 16%); filter: none; }
#app-tiles.periodic .app-tile { background: var(--arcenal-primary); border-color: transparent; }
#app-tiles.periodic .app-tile:nth-child(3n+2) { background: var(--arcenal-accent); }
#app-tiles.periodic .app-tile:nth-child(3n) { background: #147e74; }
footer { border-color: var(--arcenal-border) !important; color: var(--arcenal-muted); padding-top: 1rem; }
footer .link { color: var(--arcenal-muted); font-weight: 600; }
:focus-visible { outline: 3px solid var(--arcenal-accent) !important; outline-offset: 3px; }
@media (prefers-reduced-motion: reduce) { #app-tiles .app-tile { transition: none; } #app-tiles .app-tile:hover { transform: none; } }
CSS
    arcenal_css_mise_en_page "$mise_en_page"
}

arcenal_css_mise_en_page() {
    local mise_en_page="$1"
    if test "$mise_en_page" = "compact"; then
        printf '%s\n' '#app-tiles { gap: .75rem; } #app-tiles .app-tile { padding: 1rem; } #app-tiles .app-logo { width: 4.5rem; height: 4.5rem; min-width: 4.5rem; }'
        return 0
    fi
    printf '%s\n' '#app-tiles { gap: 1.25rem; } #app-tiles .app-tile { padding: 1.5rem; }'
}

arcenal_appliquer_identite() {
    local domaine titre theme tuiles mise_en_page intro_utilisateur intro_public primaire accent
    domaine="$(arcenal_lire_reglage portal_domain)"
    titre="$(arcenal_lire_reglage portal_title)"
    theme="$(arcenal_lire_reglage portal_theme)"
    tuiles="$(arcenal_lire_reglage portal_tile_theme)"
    mise_en_page="$(arcenal_lire_reglage portal_layout)"
    intro_utilisateur="$(arcenal_lire_reglage portal_user_intro)"
    intro_public="$(arcenal_lire_reglage portal_public_intro)"
    primaire="$(arcenal_lire_reglage brand_primary)"
    accent="$(arcenal_lire_reglage brand_accent)"
    yunohost domain config set "$domaine" feature.portal.portal_title --value "$titre"
    yunohost domain config set "$domaine" feature.portal.portal_theme --value "$theme"
    yunohost domain config set "$domaine" feature.portal.portal_tile_theme --value "$tuiles"
    yunohost domain config set "$domaine" feature.portal.portal_user_intro --value "$intro_utilisateur"
    yunohost domain config set "$domaine" feature.portal.portal_public_intro --value "$intro_public"
    yunohost domain config set "$domaine" feature.portal.custom_css --value "$(arcenal_css_portail "$primaire" "$accent" "$mise_en_page")"
}
