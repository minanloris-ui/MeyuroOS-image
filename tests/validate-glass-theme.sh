#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

theme_root="system_files/usr/share"
aurorae_root="${theme_root}/aurorae/themes/MeyuroGlass"

bash -n build_files/build.sh
bash -n system_files/usr/libexec/meyuroos-apply-glass-theme

required_files=(
  "${theme_root}/color-schemes/MeyuroGlass.colors"
  "${theme_root}/Kvantum/MeyuroGlass/MeyuroGlass.kvconfig"
  "${theme_root}/plasma/desktoptheme/MeyuroGlass/metadata.json"
  "${theme_root}/plasma/desktoptheme/MeyuroGlass/plasmarc"
  "${theme_root}/plasma/look-and-feel/com.meyuroos.glass/manifest.json"
  "${theme_root}/plasma/look-and-feel/com.meyuroos.glass/contents/defaults"
  "${theme_root}/meyuroos/theme-defaults/kvantum.kvconfig"
  "${theme_root}/meyuroos/theme-defaults/gtk-settings.ini"
  "${theme_root}/meyuroos/theme-defaults/gtk.css"
  "${aurorae_root}/metadata.desktop"
  "${aurorae_root}/MeyuroGlassrc"
  "${aurorae_root}/decoration.svg"
  "${aurorae_root}/minimize.svg"
  "${aurorae_root}/maximize.svg"
  "${aurorae_root}/restore.svg"
  "${aurorae_root}/close.svg"
  "system_files/etc/xdg/autostart/meyuroos-glass-theme.desktop"
  "system_files/usr/libexec/meyuroos-apply-glass-theme"
)

for file in "${required_files[@]}"; do
  test -s "${file}" || { echo "Missing Meyuro Glass file: ${file}" >&2; exit 1; }
done

python3 -m json.tool \
  "${theme_root}/plasma/desktoptheme/MeyuroGlass/metadata.json" >/dev/null
python3 -m json.tool \
  "${theme_root}/plasma/look-and-feel/com.meyuroos.glass/manifest.json" >/dev/null

python3 - "${aurorae_root}" <<'PY'
import pathlib
import sys
import xml.etree.ElementTree as ET

root = pathlib.Path(sys.argv[1])
for svg in root.glob("*.svg"):
    ET.parse(svg)

decoration_ids = {
    element.attrib.get("id")
    for element in ET.parse(root / "decoration.svg").iter()
}
for prefix in ("decoration", "decoration-inactive", "mask"):
    for part in (
        "topleft", "top", "topright", "left", "center", "right",
        "bottomleft", "bottom", "bottomright",
    ):
        expected = f"{prefix}-{part}"
        if expected not in decoration_ids:
            raise SystemExit(f"Missing Aurorae frame element: {expected}")

for name in ("minimize", "maximize", "restore", "close"):
    button_ids = {
        element.attrib.get("id")
        for element in ET.parse(root / f"{name}.svg").iter()
    }
    for state in ("active-center", "inactive-center", "hover-center", "pressed-center"):
        if state not in button_ids:
            raise SystemExit(f"Missing {name} button state: {state}")
PY

grep -Fq '"KPackageStructure": "Plasma/LookAndFeel"' \
  "${theme_root}/plasma/look-and-feel/com.meyuroos.glass/manifest.json"
grep -Fq 'ColorScheme=MeyuroGlass' \
  "${theme_root}/plasma/look-and-feel/com.meyuroos.glass/contents/defaults"
grep -Fq 'theme=__aurorae__svg__MeyuroGlass' \
  "${theme_root}/plasma/look-and-feel/com.meyuroos.glass/contents/defaults"
grep -Fq 'translucent_windows=true' \
  "${theme_root}/Kvantum/MeyuroGlass/MeyuroGlass.kvconfig"
grep -Fq 'blurring=true' \
  "${theme_root}/Kvantum/MeyuroGlass/MeyuroGlass.kvconfig"
grep -Fq 'theme=MeyuroGlass' \
  "${theme_root}/meyuroos/theme-defaults/kvantum.kvconfig"
grep -Fq 'BackgroundNormal=10,120,200' \
  "${theme_root}/color-schemes/MeyuroGlass.colors"
grep -Fq 'background-image: linear-gradient' \
  "${theme_root}/meyuroos/theme-defaults/gtk.css"
grep -Fq 'Exec=/usr/libexec/meyuroos-apply-glass-theme' \
  system_files/etc/xdg/autostart/meyuroos-glass-theme.desktop
grep -Fq 'plasma-apply-lookandfeel --apply com.meyuroos.glass' \
  system_files/usr/libexec/meyuroos-apply-glass-theme
grep -Fq 'theme-defaults/gtk.css' \
  system_files/usr/libexec/meyuroos-apply-glass-theme
grep -Fq 'dnf5 install -y' build_files/build.sh
grep -Fq 'kvantum-qt5' build_files/build.sh
grep -Fq '/usr/share/Kvantum/KvMojave/KvMojave.svg' build_files/build.sh

if test -e system_files/etc/xdg/kwinrulesrc; then
  echo "Do not force global window opacity through KWin rules" >&2
  exit 1
fi

echo "Meyuro Glass theme source validation passed."
