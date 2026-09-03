# Hardware validation checklist

Record pass/fail without recording network names, MAC addresses, serial numbers,
account names, passwords, or other unique identifiers.

## Before installing a new unit

- [ ] PCB is marked `GOLDFINGER_V14 / 2021-12-07`.
- [ ] The UART helper reaches all five pass stages from a cold factory boot.
- [ ] `/proc/device-tree/model` reports the Goldfinger V14 r6 model.
- [ ] `findmnt /` and `findmnt /boot` both resolve to USB partitions.
- [ ] No eMMC partition is mounted during the USB test drive.
- [ ] Four CPUs and approximately 2 GiB RAM are visible.
- [ ] Approximately 16 GB eMMC is detected.
- [ ] Ethernet or Wi-Fi passes DHCP, DNS, and real traffic.
- [ ] HDMI is stable at the required resolution.
- [ ] Any USB ports needed for deployment work with known-good devices.
- [ ] Bluetooth and analog audio are tested if the deployment needs them.
- [ ] `systemctl --failed` shows no unexplained failed units after first setup.

## Installer acceptance

- [ ] The installer selects model 528 and ext4 automatically.
- [ ] PCB metadata, eMMC geometry, and protected-region checks pass.
- [ ] The recovery directory and `SHA256SUMS` are created on USB.
- [ ] Linux copy and filesystem verification finish before activation prompts.
- [ ] Both activation confirmations describe the recovery requirement.
- [ ] Saved-environment read-back verification passes.
- [ ] The device is cleanly powered down before media removal.

## First eMMC boot

- [ ] USB is physically absent.
- [ ] No UART key or command is sent during cold boot.
- [ ] The normal login is reached.
- [ ] `/` is `/dev/mmcblk2p2` and `/boot` is `/dev/mmcblk2p1`.
- [ ] The expected hardware and services remain available.
- [ ] The recovery directory is copied off the USB and its checksum manifest passes.

## Recovery precedence

- [ ] With the device off, insert the prepared USB in B1.
- [ ] Cold-power without sending UART input.
- [ ] Confirm U-Boot automatically executes the USB `s905_autoscript`.
- [ ] Confirm `/` and `/boot` are USB partitions and eMMC is unmounted.
- [ ] Shut down cleanly; remove USB; reconfirm unattended eMMC boot.

## Maintainer release matrix

- [x] USB helper boot reproduced on two units.
- [x] Guarded eMMC installation completed on the second unit.
- [x] USB-free eMMC cold boot completed on the second unit.
- [x] Automatic USB recovery precedence completed on the installed second unit.
- [x] Image checksum, gzip, FAT, ext4, and embedded-content audits passed.
- [ ] Full 2.4 GHz Wi-Fi association test.
- [ ] W4 high-speed storage retest with another device.
- [ ] Suspend/resume and extended thermal/network/storage soak.
- [ ] Full raw protected-region restoration rehearsal.

The unchecked maintainer items are documented limitations for the first
experimental community release, not hidden claims of support.
