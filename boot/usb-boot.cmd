# RAM-only U-Boot script for a two-partition Armbian USB drive.
# Compile with: mkimage -A arm64 -T script -C none -n 'Goldfinger USB boot' \
#   -d boot/usb-boot.cmd boot/aml_autoscript
# Review the source before use. It never persists environment state or writes storage.

echo Goldfinger USB boot: RAM-only session
usb start

if fatload usb 0:1 0x01000000 uEnv.txt; then
  env import -t 0x01000000 ${filesize}
  if fatload usb 0:1 0x11000000 ${LINUX}; then
    if fatload usb 0:1 0x15000000 ${INITRD}; then
      if fatload usb 0:1 0x01000000 ${FDT}; then
        setenv bootargs ${APPEND}
        booti 0x11000000 0x15000000 0x01000000
      fi
    fi
  fi
fi

echo Goldfinger USB boot failed; returning to U-Boot
