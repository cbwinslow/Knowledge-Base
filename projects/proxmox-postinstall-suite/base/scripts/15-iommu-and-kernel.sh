#!/usr/bin/env bash
set -euo pipefail
GRUB="/etc/default/grub"
NEED="false"
grep -q 'intel_iommu=on' "$GRUB" || { sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on iommu=pt /' "$GRUB"; NEED="true"; }
update-grub
cat >/etc/modules-load.d/vfio.conf <<EOF
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
EOF
cat >/etc/modprobe.d/blacklist-nouveau.conf <<EOF
blacklist nouveau
options nouveau modeset=0
EOF
update-initramfs -u
if [[ "${AUTO_REBOOT_FOR_KERNEL:-true}" == "true" && "$NEED" == "true" ]]; then
  echo "Rebooting in 5s to apply kernel params..."; sleep 5; reboot
fi
