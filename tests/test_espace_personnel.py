from __future__ import annotations

import json
import unittest
from pathlib import Path
from subprocess import run
from tempfile import TemporaryDirectory


ROOT = Path(__file__).parents[1]


class EspacePersonnelTest(unittest.TestCase):
    def test_dashboard_uses_the_native_portal_api(self) -> None:
        script = (ROOT / "www" / "app.js").read_text(encoding="utf-8")
        self.assertIn('const apiBase = "/yunohost/portalapi"', script)
        self.assertIn("loadJson(`${apiBase}/me`)", script)
        self.assertIn("user.apps", script)
        self.assertIn('user.groups.includes("admins")', script)

    def test_dashboard_does_not_inject_user_content_as_html(self) -> None:
        script = (ROOT / "www" / "app.js").read_text(encoding="utf-8")
        self.assertNotIn("innerHTML", script)
        self.assertIn("textContent", script)

    def test_dashboard_has_the_requested_navigation(self) -> None:
        page = (ROOT / "www" / "index.html").read_text(encoding="utf-8")
        style = (ROOT / "www" / "arcenal.css").read_text(encoding="utf-8")
        script = (ROOT / "www" / "app.js").read_text(encoding="utf-8")
        self.assertIn("Mes applications", page)
        self.assertIn("Administration", page)
        self.assertIn("DERNIÈRE NOUVELLE", page)
        self.assertIn("@media (max-width: 760px)", style)
        self.assertIn(".liens-navigation { display: flex;", style)
        self.assertIn('html[data-theme="dark"]', style)
        self.assertIn("prefers-color-scheme: dark", style)
        self.assertIn("applyTheme(configuration)", script)

    def test_dashboard_uses_the_soft_blue_floating_card_design(self) -> None:
        style = (ROOT / "www" / "arcenal.css").read_text(encoding="utf-8")
        self.assertIn("--bleu", style)
        self.assertIn("linear-gradient", style)
        self.assertIn("border-radius: 28px", style)
        self.assertIn("backdrop-filter: blur", style)

    def test_nginx_uses_the_private_dashboard_path(self) -> None:
        nginx = (ROOT / "conf" / "nginx.conf").read_text(encoding="utf-8")
        self.assertIn("location __PATH__/", nginx)
        self.assertIn("alias __INSTALL_DIR__/;", nginx)
        self.assertIn("location = /yunohost/sso/", nginx)
        self.assertIn('if ($arg_r = "")', nginx)
        self.assertIn("alias /usr/share/yunohost/portal/;", nginx)
        self.assertIn("Content-Security-Policy", nginx)
        self.assertNotIn("location /yunohost", nginx)

    def test_manifest_declares_the_dashboard_as_a_native_web_application(self) -> None:
        manifest = (ROOT / "manifest.toml").read_text(encoding="utf-8")
        self.assertIn("[install.domain]", manifest)
        self.assertIn('default = "/espace-perso"', manifest)
        self.assertIn("[resources.permissions]", manifest)
        self.assertIn("main.url = \"/\"", manifest)

    def test_system_requires_the_store_without_overriding_its_permission(self) -> None:
        common = (ROOT / "scripts" / "_common.sh").read_text(encoding="utf-8")
        install = (ROOT / "scripts" / "install").read_text(encoding="utf-8")
        self.assertIn("test -d /etc/yunohost/apps/arcenal-store", common)
        self.assertIn("arcenal_exiger_store", install)
        self.assertNotIn("ynh_permission_url", common)

    def test_scripts_deploy_the_dashboard_without_touching_yunohost_core(self) -> None:
        common = (ROOT / "scripts" / "_common.sh").read_text(encoding="utf-8")
        self.assertIn("arcenal_deployer_espace", common)
        self.assertIn("ynh_config_add_nginx", common)
        self.assertNotIn("/usr/share/yunohost/portal", common)

    def test_dashboard_normalizes_native_urls_and_closes_the_session(self) -> None:
        script = (ROOT / "www" / "app.js").read_text(encoding="utf-8")
        self.assertIn("function applicationUrl", script)
        self.assertIn("function localizedDescription", script)
        self.assertNotIn('method: "POST"', script)
        self.assertIn('fetch(`${apiBase}/logout`', script)
        self.assertIn("response.ok", script)
        self.assertIn("response.status !== 401", script)
        self.assertIn("La déconnexion n'a pas abouti", script)
        self.assertIn('localStorage.setItem("isLoggedIn", "false")', script)
        self.assertIn('window.btoa(`${window.location.origin}/espace-perso/`)', script)
        self.assertIn('window.location.assign(`/yunohost/sso/?r=${encodeURIComponent(destination)}`)', script)

    def test_upgrade_backup_skips_resources_that_do_not_exist_yet(self) -> None:
        backup = (ROOT / "scripts" / "backup").read_text(encoding="utf-8")
        self.assertIn('test ! -e "$repertoire" || ynh_backup "$repertoire"', backup)
        self.assertIn('test ! -e "$nginx" || ynh_backup "$nginx"', backup)

    def test_lifecycle_scripts_load_their_common_file_from_any_directory(self) -> None:
        scripts = ("install", "upgrade", "remove", "backup", "restore", "config")
        for script_name in scripts:
            script = (ROOT / "scripts" / script_name).read_text(encoding="utf-8")
            self.assertIn('source "$(dirname "$0")/_common.sh"', script)

    def test_dashboard_configuration_escapes_administrator_content(self) -> None:
        with TemporaryDirectory() as temporary:
            command = f'''source "{ROOT / "scripts" / "_common.sh"}"
arcenal_repertoire_espace() {{ printf '%s' "{temporary}"; }}
ynh_app_setting_get() {{
  case "$1" in
    *=dashboard_news_title) printf '%s' 'Nouvelle "prioritaire"' ;;
    *=dashboard_news_content) printf '%s' 'Texte avec <balise>' ;;
    *=portal_theme) printf '%s' 'system' ;;
    *) printf '%s' 'https://example.test/actualite' ;;
  esac
}}
arcenal_ecrire_configuration_espace'''
            run(["bash", "-c", command], check=True, capture_output=True, text=True)
            path = Path(temporary) / "configuration.json"
            configuration = json.loads(path.read_text(encoding="utf-8"))
        self.assertEqual(configuration["newsTitle"], 'Nouvelle "prioritaire"')
        self.assertEqual(configuration["newsContent"], "Texte avec <balise>")
        self.assertEqual(configuration["theme"], "system")


if __name__ == "__main__":
    unittest.main()
