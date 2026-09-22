from __future__ import annotations

import tomllib
import unittest
from pathlib import Path


ROOT = Path(__file__).parents[1]


class ConfigPanelTest(unittest.TestCase):
    def test_identity_panel_uses_native_domain_options(self) -> None:
        panel = tomllib.loads((ROOT / "config_panel.toml").read_text(encoding="utf-8"))
        portal = panel["identite"]["portail"]
        self.assertEqual(portal["portal_domain"]["type"], "domain")
        self.assertEqual(portal["portal_logo"]["type"], "file")
        self.assertEqual(portal["portal_theme"]["choices"], ["light", "system", "dark"])

    def test_config_script_only_uses_supported_portal_settings(self) -> None:
        script = (ROOT / "scripts" / "_common.sh").read_text(encoding="utf-8")
        self.assertIn("feature.portal.portal_title", script)
        self.assertIn("feature.portal.custom_css", script)
        self.assertNotIn("/etc/ssowat", script)


if __name__ == "__main__":
    unittest.main()
