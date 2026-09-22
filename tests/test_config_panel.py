from __future__ import annotations

import tomllib
import unittest
from pathlib import Path
from subprocess import run


ROOT = Path(__file__).parents[1]


class ConfigPanelTest(unittest.TestCase):
    def test_identity_panel_uses_native_portal_options(self) -> None:
        panel = tomllib.loads((ROOT / "config_panel.toml").read_text(encoding="utf-8"))
        portal = panel["identite"]["portail"]
        self.assertNotIn("portal_domain", portal)
        self.assertEqual(portal["portal_logo"]["type"], "file")
        self.assertEqual(
            portal["portal_logo"]["accept"],
            ["image/svg+xml", "image/png", "image/jpeg"],
        )
        self.assertEqual(portal["portal_theme"]["choices"], ["light", "system", "dark"])
        self.assertEqual(portal["portal_layout"]["choices"], ["confortable", "compact"])
        dashboard = panel["identite"]["espace"]
        self.assertEqual(dashboard["dashboard_news_url"]["type"], "url")
        self.assertTrue(dashboard["dashboard_news_url"]["optional"])
        self.assertEqual(panel["identite"]["marque"]["brand_primary"]["ask"]["fr"], "Couleur dominante")
        updates = panel["identite"]["mises_a_jour"]
        self.assertEqual(updates["update_policy"]["choices"], ["automatic", "manual"])
        self.assertEqual(updates["update_manifest_url"]["type"], "url")

    def test_config_script_only_uses_supported_portal_settings(self) -> None:
        script = (ROOT / "scripts" / "_common.sh").read_text(encoding="utf-8")
        self.assertIn('domain config set "$domaine" feature.portal.portal_title', script)
        self.assertIn('domain config set "$domaine" feature.portal.custom_css', script)
        self.assertIn("#app-tiles .app-tile", script)
        self.assertIn("@media (prefers-reduced-motion: reduce)", script)
        self.assertNotIn('domain config set "$domaine" --key', script)
        self.assertNotIn("/etc/ssowat", script)

    def test_portal_identity_is_restored_when_the_app_is_removed(self) -> None:
        common = (ROOT / "scripts" / "_common.sh").read_text(encoding="utf-8")
        remove = (ROOT / "scripts" / "remove").read_text(encoding="utf-8")
        self.assertIn("domain config get \"$domaine\" feature.portal --export", common)
        self.assertIn("domain config set \"$domaine\" feature.portal --args-file", common)
        self.assertIn("arcenal_restaurer_identite_portail", remove)

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

    def test_color_getters_return_a_yaml_scalar(self) -> None:
        command = f'''ynh_app_setting_get() {{ printf '%s' '#842F47'; }}
source "{ROOT / "scripts" / "_common.sh"}"
arcenal_lire_couleur_yaml brand_primary '#202229' '''
        result = run(["bash", "-c", command], check=True, capture_output=True, text=True)
        self.assertEqual(result.stdout, '"#842F47"')

    def test_invalid_saved_color_uses_the_safe_default_in_the_panel(self) -> None:
        command = f'''ynh_app_setting_get() {{ printf '%s' 'not-a-colour'; }}
source "{ROOT / "scripts" / "_common.sh"}"
arcenal_lire_couleur_yaml brand_primary '#202229' '''
        result = run(["bash", "-c", command], check=True, capture_output=True, text=True)
        self.assertEqual(result.stdout, '"#202229"')

    def test_configuration_does_not_need_the_temporary_package_sources(self) -> None:
        script = (ROOT / "scripts" / "config").read_text(encoding="utf-8")
        self.assertIn("arcenal_ecrire_configuration_espace", script)
        self.assertNotIn("arcenal_deployer_espace", script)

    def test_configuration_controls_the_arcenal_update_timer(self) -> None:
        config = (ROOT / "scripts" / "config").read_text(encoding="utf-8")
        self.assertIn("set__update_policy()", config)
        self.assertIn("arcenal_configurer_planification", config)
        self.assertIn("set__update_manifest_url()", config)

    def test_deployment_preserves_assets_for_future_configuration_changes(self) -> None:
        common = (ROOT / "scripts" / "_common.sh").read_text(encoding="utf-8")
        self.assertIn("arcenal_repertoire_sources_espace", common)
        self.assertIn("arcenal_archiver_sources_espace", common)
        self.assertIn("arcenal-assets", common)

    def test_install_domain_must_be_a_root_domain(self) -> None:
        script = (ROOT / "scripts" / "_common.sh").read_text(encoding="utf-8")
        self.assertIn("yunohost domain list --exclude-subdomains --output-as json", script)
        self.assertIn('json.load(sys.stdin)["domains"]', script)
        self.assertIn('arcenal_domaine_portail_est_racine "$domain"', script)


if __name__ == "__main__":
    unittest.main()
