#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

rpm-ostree override replace \
  --from repo='fedora' \
  --experimental \
  --remove=OpenCL-ICD-Loader \
  ocl-icd \
  || true

rpm-ostree install \
    ublue-os-luks \
    ublue-os-signing \
    ublue-os-udev-rules

# use negativo17 for 3rd party packages with higher priority than default
curl -Lo /etc/yum.repos.d/negativo17-fedora-multimedia.repo https://negativo17.org/repos/fedora-multimedia.repo
sed -i '0,/enabled=1/{s/enabled=1/enabled=1\npriority=90/}' /etc/yum.repos.d/negativo17-fedora-multimedia.repo

rpm-ostree override replace \
      --experimental \
      --from repo='fedora-multimedia' \
        libheif \
        libva \
        libva-intel-media-driver \
        mesa-dri-drivers \
        mesa-filesystem \
        mesa-libEGL \
        mesa-libGL \
        mesa-libgbm \
        mesa-libxatracker \
        mesa-va-drivers \
        mesa-vulkan-drivers

rpm-ostree override remove \
        gnome-software-rpm-ostree
    rpm-ostree override replace \
        --experimental \
        --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        gnome-software