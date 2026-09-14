#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

required_files=(
  "apps/meyuro-update/CMakeLists.txt"
  "apps/meyuro-update/src/CMakeLists.txt"
  "apps/meyuro-update/src/icons/meyuro-logo.png"
  "apps/meyuro-update/src/kcm_meyuro_update.json"
  "apps/meyuro-update/src/meyuroupdatemodule.h"
  "apps/meyuro-update/src/meyuroupdatemodule.cpp"
  "apps/meyuro-update/src/ui/main.qml"
  "disk_config/iso.toml"
)

for file in "${required_files[@]}"; do
  test -s "${file}" || { echo "Missing required update-center source: ${file}" >&2; exit 1; }
done

python3 -m json.tool apps/meyuro-update/src/kcm_meyuro_update.json >/dev/null

grep -Fq '/usr/bin/bootc' apps/meyuro-update/src/meyuroupdatemodule.cpp
grep -Fq '/usr/bin/pkexec' apps/meyuro-update/src/meyuroupdatemodule.cpp
grep -Fq 'QStringLiteral("upgrade")' apps/meyuro-update/src/meyuroupdatemodule.cpp
grep -Fq 'QStringLiteral("rollback")' apps/meyuro-update/src/meyuroupdatemodule.cpp
grep -Fq '"Icon": "meyuro-logo"' apps/meyuro-update/src/kcm_meyuro_update.json
grep -Fq 'source: "meyuro-logo"' apps/meyuro-update/src/ui/main.qml
grep -Fq 'icons/meyuro-logo.png' apps/meyuro-update/src/CMakeLists.txt
grep -Fq 'COPY apps/meyuro-update' Containerfile
grep -Fq 'COPY --from=updater-builder' Containerfile
grep -Fq 'ghcr.io/minanloris-ui/meyuroos:latest' disk_config/iso.toml
grep -Fq 'IMAGE_NAME: "meyuroos"' .github/workflows/build-disk.yml

if grep -R -Fq 'ghcr.io/ublue-os/image-template' disk_config; then
  echo "ISO configuration still points to the template image" >&2
  exit 1
fi

if test -e cosign.key; then
  echo "cosign.key must never be committed to the repository" >&2
  exit 1
fi

echo "MeyuroOS update-center source validation passed."
