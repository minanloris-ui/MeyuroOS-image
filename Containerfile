ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite:stable@sha256:9556db65991d57a03a7dc18e4ba28a686d8bcdcd6b61235aa69c8267bb22ff76"

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Build the native KDE System Settings module in an isolated stage so compiler
# packages do not become part of the final operating-system image.
FROM ${BASE_IMAGE} AS updater-builder
COPY apps/meyuro-update /tmp/meyuro-update
COPY apps/meyuro-task-manager-menu /tmp/meyuro-task-manager-menu
RUN dnf5 install -y \
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
        qt6-qtdeclarative-devel && \
    cmake -S /tmp/meyuro-update -B /tmp/meyuro-update-build \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr && \
    cmake --build /tmp/meyuro-update-build && \
    DESTDIR=/tmp/meyuro-app-root cmake --install /tmp/meyuro-update-build && \
    cmake -S /tmp/meyuro-task-manager-menu -B /tmp/meyuro-task-manager-menu-build \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr && \
    cmake --build /tmp/meyuro-task-manager-menu-build && \
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
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

COPY --from=updater-builder /tmp/meyuro-app-root/ /

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
