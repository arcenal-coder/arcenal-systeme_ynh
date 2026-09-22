from __future__ import annotations

import tomllib
import unittest
from pathlib import Path
from subprocess import run


ROOT = Path(__file__).parents[1]


class ConfigPanelTest(unittest.TestCase):
    def test_identity_panel_uses_native_domain_options(self) -> None:
        panel = tomllib.loads((ROOT / "config_panel.toml").read_text(encoding="utf-8"))
        portal = panel["identite"]["portail"]
        self.assertEqual(portal["portal_domain"]["type"], "domain")
        self.assertEqual(portal["portal_logo"]["type"], "file")
        self.assertEqual(
            portal["portal_logo"]["accept"],
            ["image/svg+xml", "image/png", "image/jpeg"],
        )
        self.assertEqual(portal["portal_theme"]["choices"], ["light", "system", "dark"])
        self.assertEqual(portal["portal_layout"]["choices"], ["confortable", "compact"])

    def test_config_script_only_uses_supported_portal_settings(self) -> None:
        script = (ROOT / "scripts" / "_common.sh").read_text(encoding="utf-8")
        self.assertIn('domain config set "$domaine" feature.portal.portal_title', script)
        self.assertIn('domain config set "$domaine" feature.portal.custom_css', script)
        self.assertIn("#app-tiles .app-tile", script)
        self.assertIn("@media (prefers-reduced-motion: reduce)", script)
        self.assertNotIn('domain config set "$domaine" --key', script)
        self.assertNotIn("/etc/ssowat", script)

    def test_portal_layout_is_persisted_and_applied(self) -> None:
        script = (ROOT / "scripts" / "_common.sh").read_text(encoding="utf-8")
        config = (ROOT / "scripts" / "config").read_text(encoding="utf-8")
        self.assertIn('portal_layout "confortable"', script)
        self.assertIn('arcenal_css_portail "$primaire" "$accent" "$mise_en_page"', script)
        self.assertIn('get__portal_layout()', config)
        self.assertIn('set__portal_layout()', config)

    def test_blank_color_values_are_not_persisted(self) -> None:
        script = (ROOT / "scripts" / "config").read_text(encoding="utf-8")
        self.assertIn("arcenal_modifier_couleur brand_primary", script)
        self.assertIn("arcenal_modifier_couleur brand_accent", script)
        self.assertIn('test -n "$valeur" || return 0', script)

    def test_portal_domain_uses_root_domains(self) -> None:
        script = (ROOT / "scripts" / "_common.sh").read_text(encoding="utf-8")
        self.assertIn("yunohost domain list --exclude-subdomains --output-as json", script)
        self.assertIn('json.load(sys.stdin)["domains"]', script)

    def test_subdomain_is_repaired_to_a_root_domain(self) -> None:
        command = f'''source "{ROOT / "scripts" / "_common.sh"}"
stored_domain="mail.onyx-ingenierie.com"
yunohost() {{ printf '%s\n' '{{"domains":["onyx-ingenierie.com"]}}'; }}
ynh_app_setting_get() {{ printf '%s' "$stored_domain"; }}
ynh_app_setting_set() {{ stored_domain="$(printf '%s' "$2" | cut -d= -f2)"; }}
arcenal_initialiser_identite
printf '%s' "$stored_domain"'''
        result = run(["bash", "-c", command], check=True, capture_output=True, text=True)
        self.assertEqual(result.stdout, "onyx-ingenierie.com")


if __name__ == "__main__":
    unittest.main()
