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
  "system_files/usr/lib/systemd/user/meyuroos-glass-theme.service"
)

for file in "${required_files[@]}"; do
  test -s "${file}" || { echo "Missing Meyuro Glass file: ${file}" >&2; exit 1; }
done

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
for prefix in ("decoration", "decoration-inactive"):
    for part in (
        "topleft", "top", "topright", "left", "center", "right",
        "bottomleft", "bottom", "bottomright",
    ):
        expected = f"{prefix}-{part}"
        if expected not in decoration_ids:
            raise SystemExit(f"Missing Aurorae frame element: {expected}")

if "mask" not in decoration_ids:
    raise SystemExit("Missing Aurorae blur element: mask")

for name in ("minimize", "maximize", "restore", "close"):
    button_ids = {
        element.attrib.get("id")
        for element in ET.parse(root / f"{name}.svg").iter()
    }
    for state in ("active-center", "inactive-center", "hover-center", "pressed-center"):
        if state not in button_ids:
            raise SystemExit(f"Missing {name} button state: {state}")
PY

grep -Fq 'translucent_windows=true' \
  "${theme_root}/Kvantum/MeyuroGlass/MeyuroGlass.kvconfig"
grep -Fq 'blurring=true' \
  "${theme_root}/Kvantum/MeyuroGlass/MeyuroGlass.kvconfig"
grep -Fq 'respect_DE=false' \
  "${theme_root}/Kvantum/MeyuroGlass/MeyuroGlass.kvconfig"
grep -Fq 'theme=MeyuroGlass' \
  "${theme_root}/meyuroos/theme-defaults/kvantum.kvconfig"
grep -Fq 'BackgroundNormal=10,120,200' \
  "${theme_root}/color-schemes/MeyuroGlass.colors"
grep -Fq 'background-image: linear-gradient' \
  "${theme_root}/meyuroos/theme-defaults/gtk.css"
grep -Fq 'Exec=/usr/libexec/meyuroos-apply-glass-theme' \
  system_files/etc/xdg/autostart/meyuroos-glass-theme.desktop
grep -Fq 'THEME_VERSION="2"' \
  system_files/usr/libexec/meyuroos-apply-glass-theme
grep -Fq 'kvantummanager --set MeyuroGlass' \
  system_files/usr/libexec/meyuroos-apply-glass-theme
grep -Fq 'WINDOW_RULE_ID="meyuro-glass-windows"' \
  system_files/usr/libexec/meyuroos-apply-glass-theme
grep -Fq -- '--key types 289' \
  system_files/usr/libexec/meyuroos-apply-glass-theme
grep -Fq -- '--key opacityactive 94' \
  system_files/usr/libexec/meyuroos-apply-glass-theme
grep -Fq -- '--key opacityinactive 88' \
  system_files/usr/libexec/meyuroos-apply-glass-theme
grep -Fq 'widgetStyle Breeze' \
  system_files/usr/libexec/meyuroos-apply-glass-theme
grep -Fq 'widgetStyle kvantum' \
  system_files/usr/libexec/meyuroos-apply-glass-theme
grep -Fq 'theme-defaults/gtk.css' \
  system_files/usr/libexec/meyuroos-apply-glass-theme
grep -Fq 'WantedBy=graphical-session.target' \
  system_files/usr/lib/systemd/user/meyuroos-glass-theme.service
grep -Fq 'dnf5 install -y' Containerfile
grep -Fq 'kvantum-qt5' Containerfile
grep -Fq '/usr/share/Kvantum/KvMojave/KvMojave.svg' build_files/build.sh
grep -Fq '/usr/share/Kvantum/MeyuroGlass/MeyuroGlass.colors' build_files/build.sh
grep -Fq '/etc/xdg/Kvantum/kvantum.kvconfig' build_files/build.sh
grep -Fq 'systemctl --global enable meyuroos-glass-theme.service' build_files/build.sh

if grep -Fq 'plasma-apply-lookandfeel' \
    system_files/usr/libexec/meyuroos-apply-glass-theme; then
  echo "Window styling must not apply a Plasma global theme" >&2
  exit 1
fi
if grep -Fq 'plasma-apply-colorscheme' \
    system_files/usr/libexec/meyuroos-apply-glass-theme; then
  echo "Window styling must not apply a global KDE color scheme" >&2
  exit 1
fi
if grep -Fq -- '--group General --key ColorScheme MeyuroGlass' \
    system_files/usr/libexec/meyuroos-apply-glass-theme build_files/build.sh; then
  echo "Window styling must not recolor the Plasma shell" >&2
  exit 1
fi
if grep -Fq 'Effect-blur' \
    system_files/usr/libexec/meyuroos-apply-glass-theme build_files/build.sh; then
  echo "Window styling must not override global panel blur strength" >&2
  exit 1
fi
if grep -Fq -- '--file plasmarc --group Theme --key name MeyuroGlass' \
    system_files/usr/libexec/meyuroos-apply-glass-theme; then
  echo "Window styling must not replace the Plasma shell theme" >&2
  exit 1
fi
if test -e "${theme_root}/plasma/desktoptheme/MeyuroGlass/metadata.json"; then
  echo "Window styling must not ship a replacement Plasma desktop theme" >&2
  exit 1
fi
if test -e "${theme_root}/plasma/look-and-feel/com.meyuroos.glass/manifest.json"; then
  echo "Window styling must not ship a Plasma global theme" >&2
  exit 1
fi

echo "Meyuro Glass theme source validation passed."
