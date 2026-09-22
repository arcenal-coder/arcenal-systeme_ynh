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

    def test_config_script_only_uses_supported_portal_settings(self) -> None:
        script = (ROOT / "scripts" / "_common.sh").read_text(encoding="utf-8")
        self.assertIn('domain config set "$domaine" --key feature.portal.portal_title', script)
        self.assertIn('domain config set "$domaine" --key feature.portal.custom_css', script)
        self.assertNotIn('domain config set "$domaine" feature.portal', script)
        self.assertNotIn("/etc/ssowat", script)

    def test_blank_color_values_are_not_persisted(self) -> None:
        script = (ROOT / "scripts" / "config").read_text(encoding="utf-8")
        self.assertIn("arcenal_modifier_couleur brand_primary", script)
        self.assertIn("arcenal_modifier_couleur brand_accent", script)

    def test_main_domain_is_read_from_json(self) -> None:
        script = (ROOT / "scripts" / "_common.sh").read_text(encoding="utf-8")
        self.assertIn("yunohost domain main-domain --output-as json", script)
        self.assertIn('json.load(sys.stdin)["current_main_domain"]', script)
        self.assertIn('"current_main_domain: "*', script)

    def test_bad_legacy_domain_is_repaired(self) -> None:
        command = f'''source "{ROOT / "scripts" / "_common.sh"}"
stored_domain="current_main_domain: mail.onyx-ingenierie.com"
yunohost() {{ printf '%s\n' '{{"current_main_domain":"mail.onyx-ingenierie.com"}}'; }}
ynh_app_setting_get() {{ printf '%s' "$stored_domain"; }}
ynh_app_setting_set() {{ stored_domain="${{2#--value=}}"; }}
arcenal_initialiser_identite
printf '%s' "$stored_domain"'''
        result = run(["bash", "-c", command], check=True, capture_output=True, text=True)
        self.assertEqual(result.stdout, "mail.onyx-ingenierie.com")


if __name__ == "__main__":
    unittest.main()
