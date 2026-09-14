#!/bin/bash

set -ouex pipefail

# Runtime packages and system_files are installed in separate Containerfile
# layers. Keeping this script configuration-only prevents normal UI changes
# from repeating package downloads or the initramfs rebuild.

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

# Keep the color scheme beside the Kvantum profile as recommended by Kvantum,
# so selecting the profile also resolves the intended application palette.
install -Dm0644 /usr/share/color-schemes/MeyuroGlass.colors \
    /usr/share/Kvantum/MeyuroGlass/MeyuroGlass.colors

# Seed new profiles before the first Plasma session. Existing profiles are
# migrated once by the XDG autostart helper shipped in system_files/.
install -Dm0644 /usr/share/meyuroos/theme-defaults/kvantum.kvconfig \
    /etc/skel/.config/Kvantum/kvantum.kvconfig
install -Dm0644 /usr/share/meyuroos/theme-defaults/kvantum.kvconfig \
    /etc/xdg/Kvantum/kvantum.kvconfig
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

# Provide window-only defaults even if a desktop session does not process XDG
# autostart entries. These keys do not alter the Plasma panel or wallpaper.
kwriteconfig6 --file /etc/xdg/kdeglobals --group KDE --key widgetStyle kvantum
kwriteconfig6 --file /etc/xdg/kwinrc --group Plugins --key blurEnabled true
kwriteconfig6 --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
kwriteconfig6 --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__MeyuroGlass
kwriteconfig6 --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft M
kwriteconfig6 --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight IAX
systemctl --global enable meyuroos-glass-theme.service

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
