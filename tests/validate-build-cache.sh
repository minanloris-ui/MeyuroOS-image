#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

grep -Fq -- '--layers' Justfile
grep -Fq -- '--cache-from' Justfile
grep -Fq -- '--cache-to' Justfile
grep -Fq 'BUILD_CACHE_FROM=' .github/workflows/build.yml
grep -Fq 'BUILD_CACHE_TO=' .github/workflows/build.yml
grep -Fq 'meyuroos.contextmenu.so' Containerfile
grep -Fq 'cmake --build /tmp/meyuro-update-build --parallel' Containerfile
grep -Fq 'cmake --build /tmp/meyuro-task-manager-menu-build --parallel' Containerfile
grep -Fq 'COPY system_files/usr/share/plymouth/' Containerfile
grep -Fq 'COPY system_files/ /' Containerfile

sdk_install_line="$(grep -n -m1 'dnf5 install -y' Containerfile | cut -d: -f1)"
app_copy_line="$(grep -n -m1 'COPY apps/meyuro-update' Containerfile | cut -d: -f1)"
runtime_install_line="$(grep -n 'dnf5 install -y' Containerfile | tail -n1 | cut -d: -f1)"
system_copy_line="$(grep -n -m1 'COPY system_files/ /' Containerfile | cut -d: -f1)"
dracut_line="$(grep -n -m1 '/usr/bin/dracut' Containerfile | cut -d: -f1)"

test "${sdk_install_line}" -lt "${app_copy_line}"
test "${runtime_install_line}" -lt "${system_copy_line}"
test "${dracut_line}" -lt "${system_copy_line}"

if grep -Eq '^(dnf5 install|/usr/bin/dracut|cp -avf "/ctx/system_files")' build_files/build.sh; then
    echo "build.sh must stay configuration-only for effective layer caching" >&2
    exit 1
fi

python3 - <<'PY'
from pathlib import Path

workflow = Path(".github/workflows/build.yml").read_text(encoding="utf-8")
login = workflow.index("- name: Login to GitHub Container Registry")
build = workflow.index("- name: Build Image")
assert login < build, "registry login must happen before the cached build"

rechunk = workflow.index("- name: Rechunk with rpm-ostree")
rechunk_block = workflow[rechunk:workflow.index("# If you are feeling adventurous", rechunk)]
assert "github.event_name == 'workflow_dispatch'" in rechunk_block, "routine pushes must skip rechunking"
assert "inputs.optimize_updates" in rechunk_block, "release rechunking must remain available on demand"
PY

echo "MeyuroOS build-cache validation passed."
