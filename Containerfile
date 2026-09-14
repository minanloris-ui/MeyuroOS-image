ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite:stable@sha256:9556db65991d57a03a7dc18e4ba28a686d8bcdcd6b61235aa69c8267bb22ff76"

# Allow the configuration script to be referenced without copying it into the
# final image. Keep this context independent from system_files so changing a
# theme or application does not invalidate the package-install layers.
FROM scratch AS build-scripts
COPY build_files /

# Build the native KDE System Settings module in an isolated stage so compiler
# packages do not become part of the final operating-system image.
FROM ${BASE_IMAGE} AS updater-builder
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    dnf5 install -y \
        cmake \
        extra-cmake-modules \
        gcc-c++ \
        kf6-kcmutils-devel \
        kf6-kconfig-devel \
        kf6-kcoreaddons-devel \
        kf6-ki18n-devel \
        kf6-kirigami-devel \
        kf6-kpackage-devel \
        kf6-kwindowsystem-devel \
        libplasma-devel \
        ninja-build \
        qt6-qtbase-devel \
        qt6-qtdeclarative-devel

# Source changes now invalidate only the small native compilation layer, not
# the much slower KDE/Qt SDK installation above.
COPY apps/meyuro-update /tmp/meyuro-update
COPY apps/meyuro-task-manager-menu /tmp/meyuro-task-manager-menu
RUN cmake -S /tmp/meyuro-update -B /tmp/meyuro-update-build \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr && \
    cmake --build /tmp/meyuro-update-build --parallel && \
    DESTDIR=/tmp/meyuro-app-root cmake --install /tmp/meyuro-update-build && \
    cmake -S /tmp/meyuro-task-manager-menu -B /tmp/meyuro-task-manager-menu-build \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr && \
    cmake --build /tmp/meyuro-task-manager-menu-build --parallel && \
    DESTDIR=/tmp/meyuro-app-root cmake --install /tmp/meyuro-task-manager-menu-build && \
    find /tmp/meyuro-app-root -name 'kcm_meyuro_update.so' -print -quit | grep -q . && \
    find /tmp/meyuro-app-root -name 'org.meyuroos.contextmenu.so' -print -quit | grep -q .

# Base Image
FROM ${BASE_IMAGE}
## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:testing
# FROM ghcr.io/ublue-os/aurora:stable
# FROM ghcr.io/ublue-os/bluefin-nvidia-open:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:44
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

### MODIFICATIONS

# Runtime packages change rarely, so install them before copying project files.
# This makes the layer reusable for normal UI and source-code iterations.
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    dnf5 install -y \
        kvantum \
        kvantum-qt5 \
        plasma-systemmonitor \
        tmux

# The Plymouth watermark is the only project asset embedded into initramfs.
# Put its rebuild before the broad system_files copy, allowing Podman to reuse
# it when unrelated window themes, launchers, or applications change.
COPY system_files/usr/share/plymouth/ /usr/share/plymouth/
RUN if [[ "${KERNEL_FLAVOR:-}" == "surface" ]]; then \
        KERNEL_SUFFIX="surface"; \
    else \
        KERNEL_SUFFIX=""; \
    fi && \
    QUALIFIED_KERNEL="$(dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' "kernel${KERNEL_SUFFIX:+-${KERNEL_SUFFIX}}")" && \
    /usr/bin/dracut --no-hostonly --kver "${QUALIFIED_KERNEL}" --reproducible --zstd -v --add ostree --add fido2 -f "/usr/lib/modules/${QUALIFIED_KERNEL}/initramfs.img" && \
    chmod 0600 "/usr/lib/modules/${QUALIFIED_KERNEL}/initramfs.img"

COPY --from=updater-builder /tmp/meyuro-app-root/ /
COPY system_files/ /

RUN --mount=type=bind,from=build-scripts,source=/build.sh,target=/ctx/build.sh \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
