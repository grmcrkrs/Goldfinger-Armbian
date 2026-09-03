# Validation status

Last updated: 2026-09-03.

## Supported hardware scope

All results apply to boards physically marked `GOLDFINGER_V14` with
`2021-12-07` printed directly below it. Similar enclosures and product names may
contain different PCB, memory, Ethernet, wireless, or storage revisions.

## Proven on the reference unit

| Area | Result |
|---|---|
| Boot | Repeated unattended eMMC boot after reboot and complete power removal |
| CPU/thermal | Four-core load test passed without reported throttling or errors |
| eMMC | Direct I/O and filesystem checks passed |
| Ethernet | RTL8211F Gigabit link and traffic passed |
| Wi-Fi | AP6398S/BCM4359C0 initialized; dual-band scan and 5 GHz traffic passed |
| HDMI | Stable small-panel output; release default is forced 1280x720 at 60 Hz |
| Bluetooth | Patched BCM4359C0 controller startup and active scan passed |
| USB | B1 SuperSpeed and W2/W3 high-speed storage passed |
| Analog audio | Left, right, and both-channel TRRS headphone tests passed |

## Proven on an untouched second unit

- The final image was written to USB and verified byte-for-byte.
- The UART helper interrupted factory U-Boot and cold-booted USB from scratch.
- Linux selected the Goldfinger r6 DTB and detected the expected CPU, memory,
  eMMC, Ethernet, Wi-Fi, Bluetooth, HDMI, USB, and audio hardware.
- The guarded `armbian-install` validated the board and eMMC layout, created and
  verified protected-region backups, populated and verified both Linux
  filesystems, then performed its twice-confirmed saved-environment activation.
- With USB removed, the unit cold-booted eMMC unattended with `/dev/mmcblk2p2`
  at `/` and `/dev/mmcblk2p1` at `/boot`; systemd reported zero failed units.
- With a prepared USB reinserted in B1, a later cold boot automatically selected
  USB without UART input. USB root and boot were mounted and eMMC was not.
- The no-RTC build-time normalization was exercised on the exact stale-clock
  condition and advanced only to the embedded image timestamp.

## Release qualification

The board enablement and installation path are technically qualified as an
experimental community release on two units. A third full eMMC installation is
intentionally not required for this first publication.

The redistributable BCM4359C0 firmware was also hot-loaded from RAM on reference
hardware. It created `wlan0`, found 12 nearby 2.4 GHz and 8 nearby 5 GHz BSS
entries, associated at 5220 MHz with 780 Mbit/s receive/transmit link rates, and
passed DHCP, routing, public traffic, and DNS. Bluetooth remained powered,
discovered three devices, and logged no errors. Network identifiers were not
captured. The final rebuilt image still requires one cold USB-boot confirmation.

The remaining publication work is a final rebuild/cold-boot check, clean-checkout
documentation rehearsal, artifact upload, and upstream submission.

## Known limitations and coverage gaps

- An untouched factory unit still needs UART interruption for its first USB boot.
  No vendor updater or undocumented recovery-button path is used.
- A full raw restoration from every protected-region backup has not been
  rehearsed. The installer does automatically restore the environment backup if
  its final activation write or read-back fails.
- The recovery backup from the second-unit installation was later overwritten
  when that same USB was reused during regression testing. New tooling refuses to
  erase media containing a Goldfinger recovery directory.
- 2.4 GHz association, suspend/resume, HDMI CEC, IR, hardware video decoding,
  extended GPU validation, and a multi-hour combined soak remain untested.
- W4 passed with a low-speed keyboard, but one high-speed storage device repeatedly
  disconnected. Treat storage support on W4 as provisional.
- Analog output can pop when streams start or stop. Begin tests at low volume.
- The image defaults to 720p for the validated small display. `uEnv.txt` contains
  a commented 1080p alternative for users whose monitor supports it.

## Evidence handling

Raw factory UART logs contain unique hardware identifiers. Publish redacted logs
and never publish credentials, recovery images, network names, radio addresses,
or per-unit factory dumps.
