#!/usr/bin/env bash
set -euo pipefail

# Enable IOMMU passthrough for Intel (Dell R720 has Xeon E5 series)
GRUB="/etc/default/grub"
NEED_REBOOT="false"

if ! grep -q 'intel_iommu=on' "$GRUB"; then
  sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on iommu=pt /' "$GRUB"
  NEED_REBOOT="true"
fi

update-grub

# Enable vfio modules
cat >/etc/modules-load.d/vfio.conf <<EOF
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
EOF

# Blacklist nouveau on hosts that might have NVIDIA cards (Proxmox host best without GUI)
cat >/etc/modprobe.d/blacklist-nouveau.conf <<EOF
blacklist nouveau
options nouveau modeset=0
EOF

update-initramfs -u

if [[ "${AUTO_REBOOT_FOR_KERNEL:-true}" == "true" && "$NEED_REBOOT" == "true" ]]; then
  echo "Kernel parameters changed. System will reboot in 10 seconds..."
  sleep 10
  reboot
fi

echo "IOMMU step complete."
