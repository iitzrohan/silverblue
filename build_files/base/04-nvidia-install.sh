#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

if [[ ! $(command -v dnf5) ]]; then
    echo "Requires dnf5... Exiting"
    exit 1
fi

# Disable Multimedia
NEGATIVO17_MULT_PREV_ENABLED=N
if [[ -f /etc/yum.repos.d/fedora-multimedia.repo ]] && grep -q "enabled=1" /etc/yum.repos.d/fedora-multimedia.repo; then
    NEGATIVO17_MULT_PREV_ENABLED=Y
    echo "disabling negativo17-fedora-multimedia to ensure negativo17-fedora-nvidia is used"
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-multimedia.repo
fi

# Fetch Nvidia RPMs
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods-nvidia-open:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods-rpms

NVIDIA_TARGZ=$(jq -r '.layers[].digest' < /tmp/akmods-rpms/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods-rpms/"$NVIDIA_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods-rpms/

# Install Nvidia RPMs
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so

# # disable any remaining rpmfusion repos
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/rpmfusion*.repo

sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-cisco-openh264.repo

# ## nvidia install steps
dnf5 install -y /tmp/akmods-rpms/ublue-os/ublue-os-nvidia-addons-*.rpm

# # enable repos provided by ublue-os-nvidia-addons
sed -i '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/negativo17-fedora-nvidia.repo
sed -i '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/nvidia-container-toolkit.repo

source /tmp/akmods-rpms/kmods/nvidia-vars

dnf5 install -y \
    libnvidia-fbc \
    libva-nvidia-driver \
    nvidia-driver \
    nvidia-driver-cuda \
    nvidia-settings \
    nvidia-container-toolkit \
    /tmp/akmods-rpms/kmods/kmod-nvidia-"${KERNEL_VERSION}"-"${NVIDIA_AKMOD_VERSION}".fc"${RELEASE}".rpm

## nvidia post-install steps
# disable repos provided by ublue-os-nvidia-addons
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-nvidia.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/nvidia-container-toolkit.repo

# ensure kernel.conf matches NVIDIA_FLAVOR (which must be nvidia or nvidia-open)
# kmod-nvidia-common defaults to 'nvidia-open' but this will match our akmod image
sed -i "s/^MODULE_VARIANT=.*/MODULE_VARIANT=$KERNEL_MODULE_TYPE/" /etc/nvidia/kernel.conf

systemctl enable ublue-nvctk-cdi.service
semodule --verbose --install /usr/share/selinux/packages/nvidia-container.pp

# # Universal Blue specific Initramfs fixes
cp /etc/modprobe.d/nvidia-modeset.conf /usr/lib/modprobe.d/nvidia-modeset.conf

# we must force driver load to fix black screen on boot for nvidia desktops
sed -i 's@omit_drivers@force_drivers@g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
# as we need forced load, also mustpre-load intel/amd iGPU else chromium web browsers fail to use hardware acceleration
sed -i 's@ nvidia @ i915 amdgpu nvidia @g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf

# re-enable negativo17-mutlimedia since we disabled it
if [[ "${NEGATIVO17_MULT_PREV_ENABLED}" = "Y" ]]; then
    sed -i '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/fedora-multimedia.repo
fi