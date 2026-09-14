#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# Install the Qt 5/6 Kvantum engines used by the Meyuro Glass application
# style.  kvantum-data supplies the smooth translucent KvMojave SVG that the
# Meyuro theme recolors through its own configuration.
dnf5 install -y \
    kvantum \
    kvantum-qt5 \
    plasma-systemmonitor \
    tmux

# Put the MeyuroOS task-manager action at the top of the panel's native
# right-click menu for new Plasma profiles. Existing profiles are migrated by
# the XDG autostart helper shipped below.
PLASMA_SHELL_DEFAULTS="/usr/share/plasma/shells/org.kde.plasma.desktop/contents/defaults"
sed -i \
    '/^\[Panel\]\[ContainmentActions\]$/,/^\[/ s/^RightButton;NoModifier=.*/RightButton;NoModifier=org.meyuroos.contextmenu/' \
    "${PLASMA_SHELL_DEFAULTS}"
grep -Fq 'RightButton;NoModifier=org.meyuroos.contextmenu' \
    "${PLASMA_SHELL_DEFAULTS}"

# Keep the large upstream vector asset in its distro package while installing
# the small, MeyuroOS-owned palette and behavior configuration from this repo.
install -d -m 0755 /usr/share/Kvantum/MeyuroGlass
cp -f /usr/share/Kvantum/KvMojave/KvMojave.svg \
    /usr/share/Kvantum/MeyuroGlass/MeyuroGlass.svg
chmod 0644 /usr/share/Kvantum/MeyuroGlass/MeyuroGlass.svg

# Plasma desktop styles do not allow symlinks in Plasma 6. Copy the canonical
# color scheme so the application and shell palettes cannot drift apart.
install -Dm0644 /usr/share/color-schemes/MeyuroGlass.colors \
    /usr/share/plasma/desktoptheme/MeyuroGlass/colors

# Seed new profiles before the first Plasma session. Existing profiles are
# migrated once by the XDG autostart helper shipped in system_files/.
install -Dm0644 /usr/share/meyuroos/theme-defaults/kvantum.kvconfig \
    /etc/skel/.config/Kvantum/kvantum.kvconfig
install -Dm0644 /usr/share/meyuroos/theme-defaults/gtk-settings.ini \
    /etc/skel/.config/gtk-3.0/settings.ini
install -Dm0644 /usr/share/meyuroos/theme-defaults/gtk-settings.ini \
    /etc/skel/.config/gtk-4.0/settings.ini
install -Dm0644 /usr/share/meyuroos/theme-defaults/gtk.css \
    /etc/skel/.config/gtk-3.0/gtk.css
install -Dm0644 /usr/share/meyuroos/theme-defaults/gtk.css \
    /etc/skel/.config/gtk-4.0/gtk.css
chmod 0755 /usr/libexec/meyuroos-apply-glass-theme
chmod 0755 /usr/libexec/meyuroos-apply-task-manager-integration

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket

# The Plymouth watermark is embedded in the boot initramfs. Rebuild it after
# copying system_files so the Meyuro OS branding is visible during startup.
if [[ "${KERNEL_FLAVOR:-}" == "surface" ]]; then
    KERNEL_SUFFIX="surface"
else
    KERNEL_SUFFIX=""
fi

QUALIFIED_KERNEL="$(dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' "kernel${KERNEL_SUFFIX:+-${KERNEL_SUFFIX}}")"
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v --add ostree --add fido2 -f "/usr/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 "/usr/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
