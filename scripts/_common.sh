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
    test -n "$(arcenal_lire_reglage dashboard_news_title)" || arcenal_enregistrer_reglage dashboard_news_title "Bienvenue dans ARCenal"
    test -n "$(arcenal_lire_reglage dashboard_news_content)" || arcenal_enregistrer_reglage dashboard_news_content "Votre espace personnel rassemble les services sélectionnés pour votre activité."
    test -n "$(arcenal_lire_reglage dashboard_news_url)" || arcenal_enregistrer_reglage dashboard_news_url ""
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

arcenal_fichier_identite_precedente() {
    local domaine="$1"
    printf '/etc/yunohost/apps/%s/portal-pre-arcenal-%s.json' "$app" "$domaine"
}

arcenal_sauvegarder_identite_portail() {
    local domaine="$1"
    local fichier
    fichier="$(arcenal_fichier_identite_precedente "$domaine")"
    test -f "$fichier" && return 0
    yunohost domain config get "$domaine" feature.portal --export --output-as json > "$fichier"
}

arcenal_restaurer_identite_portail() {
    local domaine="$1"
    local fichier
    fichier="$(arcenal_fichier_identite_precedente "$domaine")"
    test -f "$fichier" || return 0
    yunohost domain config set "$domaine" feature.portal --args-file "$fichier"
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
    arcenal_sauvegarder_identite_portail "$domaine"
    yunohost domain config set "$domaine" feature.portal.portal_title --value "$titre"
    yunohost domain config set "$domaine" feature.portal.portal_theme --value "$theme"
    yunohost domain config set "$domaine" feature.portal.portal_tile_theme --value "$tuiles"
    yunohost domain config set "$domaine" feature.portal.portal_user_intro --value "$intro_utilisateur"
    yunohost domain config set "$domaine" feature.portal.portal_public_intro --value "$intro_public"
    yunohost domain config set "$domaine" feature.portal.custom_css --value "$(arcenal_css_portail "$primaire" "$accent" "$mise_en_page")"
}

arcenal_repertoire_espace() {
    printf '/var/www/%s' "$app"
}

arcenal_ecrire_configuration_espace() {
    local repertoire fichier titre contenu lien theme
    repertoire="$(arcenal_repertoire_espace)"
    fichier="${repertoire}/configuration.json"
    titre="$(arcenal_lire_reglage dashboard_news_title)"
    contenu="$(arcenal_lire_reglage dashboard_news_content)"
    lien="$(arcenal_lire_reglage dashboard_news_url)"
    theme="$(arcenal_lire_reglage portal_theme)"
    python3 - "$fichier" "$titre" "$contenu" "$lien" "$theme" <<'PY'
import json
import sys

destination, title, content, url, theme = sys.argv[1:]
with open(destination, "w", encoding="utf-8") as output:
    json.dump({"newsTitle": title, "newsContent": content, "newsUrl": url, "theme": theme}, output, ensure_ascii=False)
    output.write("\n")
PY
    chmod 0644 "$fichier"
}

arcenal_copier_espace() {
    local repertoire
    repertoire="$(arcenal_repertoire_espace)"
    install -d -m 0755 -o root -g www-data "$repertoire"
    install -m 0644 "${YNH_APP_BASEDIR}/www/index.html" "$repertoire/index.html"
    install -m 0644 "${YNH_APP_BASEDIR}/www/arcenal.css" "$repertoire/arcenal.css"
    install -m 0644 "${YNH_APP_BASEDIR}/www/app.js" "$repertoire/app.js"
    install -m 0644 "${YNH_APP_BASEDIR}/www/logo-arcenal.svg" "$repertoire/logo-arcenal.svg"
}

arcenal_configurer_permission_espace() {
    local domaine url
    domaine="$(arcenal_lire_reglage portal_domain)"
    url="${domaine}/espace-perso"
    if ynh_permission_exists --permission=main; then
        ynh_permission_url --permission=main --url="$url"
        ynh_permission_update --permission=main --add=all_users
        return 0
    fi
    ynh_permission_create --permission=main --url="$url" --allowed=all_users --show_tile=false
}

arcenal_configurer_nginx_espace() {
    local domain path install_dir
    domain="$(arcenal_lire_reglage portal_domain)"
    path="/espace-perso"
    install_dir="$(arcenal_repertoire_espace)"
    ynh_config_add_nginx
}

arcenal_retirer_nginx_espace() {
    local domain="$1"
    local path="/espace-perso"
    local install_dir
    install_dir="$(arcenal_repertoire_espace)"
    ynh_config_remove_nginx
}

arcenal_deployer_espace() {
    arcenal_copier_espace
    arcenal_ecrire_configuration_espace
    arcenal_configurer_permission_espace
    arcenal_configurer_nginx_espace
}
