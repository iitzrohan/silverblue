#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Add Packages repo
dnf5 -y copr enable ublue-os/packages

# Add staging repo
dnf5 -y copr enable ublue-os/staging

# Add Nerd Fonts Repo
dnf5 -y copr enable che/nerd-fonts

# Add Fedora Multimedia Repo
dnf config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-multimedia.repo
sed -i '0,/enabled=1/{s/enabled=1/enabled=1\npriority=90/}' /etc/yum.repos.d/fedora-multimedia.repo

echo "::endgroup::"
