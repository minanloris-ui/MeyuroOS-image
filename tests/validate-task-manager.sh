#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

plugin_root="apps/meyuro-task-manager-menu"
launcher="system_files/usr/share/applications/meyuro-task-manager.desktop"
integration="system_files/usr/libexec/meyuroos-apply-task-manager-integration"
shell_update="system_files/usr/share/meyuroos/shell-updates/meyuro-task-manager-context-menu.js"

required_files=(
  "${plugin_root}/CMakeLists.txt"
  "${plugin_root}/src/taskbarcontextmenu.cpp"
  "${plugin_root}/src/taskbarcontextmenu.h"
  "${plugin_root}/src/meyuro-task-manager-contextmenu.json"
  "${launcher}"
  "${integration}"
  "${shell_update}"
  "system_files/etc/xdg/autostart/meyuroos-task-manager-integration.desktop"
)

for file in "${required_files[@]}"; do
  test -s "${file}" || { echo "Missing task-manager file: ${file}" >&2; exit 1; }
done

bash -n "${integration}"
python3 -m json.tool \
  "${plugin_root}/src/meyuro-task-manager-contextmenu.json" >/dev/null

grep -Fq 'OUTPUT_NAME org.meyuroos.contextmenu' "${plugin_root}/CMakeLists.txt"
grep -Fq 'K_PLUGIN_CLASS_WITH_JSON(TaskbarContextMenu' \
  "${plugin_root}/src/taskbarcontextmenu.cpp"
grep -Fq 'Open Task Manager' "${plugin_root}/src/taskbarcontextmenu.cpp"
grep -Fq 'Открыть диспетчер задач' "${plugin_root}/src/taskbarcontextmenu.cpp"
grep -Fq 'Відкрити диспетчер завдань' "${plugin_root}/src/taskbarcontextmenu.cpp"
grep -Fq 'overview.page' "${plugin_root}/src/taskbarcontextmenu.cpp"
grep -Fq 'panel->internalAction' "${plugin_root}/src/taskbarcontextmenu.cpp"
grep -Fq 'panel->contextualActions()' "${plugin_root}/src/taskbarcontextmenu.cpp"
if grep -Fq 'panel->actions()' "${plugin_root}/src/taskbarcontextmenu.cpp"; then
  echo "Deprecated Plasma::Containment::actions() call found" >&2
  exit 1
fi

for page in overview applications history processes; do
  grep -Fq "${page}.page" "${launcher}"
done
grep -Fq 'X-KDE-Shortcuts=Ctrl+Shift+Esc' "${launcher}"

grep -Fq 'RightButton;NoModifier' "${shell_update}"
grep -Fq 'org.meyuroos.contextmenu' "${shell_update}"
grep -Fq 'org.kde.PlasmaShell.evaluateScript' "${integration}"
grep -Fq 'plasma-systemmonitor' Containerfile
grep -Fq 'RightButton;NoModifier=org.meyuroos.contextmenu' build_files/build.sh
grep -Fq 'chmod 0755 /usr/libexec/meyuroos-apply-task-manager-integration' build_files/build.sh
for package in \
  kf6-kconfig-devel \
  kf6-kirigami-devel \
  kf6-kpackage-devel \
  kf6-kwindowsystem-devel \
  libplasma-devel; do
  grep -Fq "${package}" Containerfile
done
grep -Fq 'COMPONENTS Core Gui Qml Widgets' "${plugin_root}/CMakeLists.txt"
grep -Fq 'KirigamiPlatform' "${plugin_root}/CMakeLists.txt"
grep -Fq 'org.meyuroos.contextmenu.so' Containerfile

echo "MeyuroOS task-manager source validation passed."
