# Redistribution review

This document covers the inputs added specifically for Goldfinger V14 support.
It is not a substitute for the notices already carried by the upstream Armbian,
Ubuntu, Linux, or ophub image.

## Clear for source publication

- Project-authored scripts, device-tree changes, and documentation are released
  under GPL-2.0-or-later.
- `bluez_5.72-0ubuntu5.5_arm64.deb` is the Ubuntu Noble arm64 BlueZ package.
  SHA-256: `ced50bcaee2c563ba965ff5faa70ae54fc3e22b8ebc09ccf9474beed63eda9d4`.
- `libubootenv-tool_0.3.5-0.1build1_arm64.deb` is the Ubuntu Noble arm64 tool
  package. SHA-256:
  `fe98b3ed1731ff4660c874b4e9262864c1fa1fb0be0cd093b43c84699c5237b5`.
- `libubootenv0.1_0.3.5-0.1build1_arm64.deb` is its Ubuntu Noble arm64 library.
  SHA-256:
  `d6bac432ceb214b40b648f0e19cb9e3197ef3f8ce24f12da5e03e55a93127cb8`.

The build fetches those packages from Ubuntu's official arm64 archive and
verifies the pinned hashes. Their package copyright files and source licenses
must remain in the installed system.

## AP6398S firmware resolution

The redistributable replacement image uses these pinned inputs:

| Installed purpose | Source | SHA-256 |
|---|---|---|
| BCM4359C0 Wi-Fi firmware | Rockchip rkwifibt package, commit `b2af9d94` | `e59d485296365ca17bd7f9cfa7be390b0b58019ee9e2d59fb78445fa33d27d48` |
| AP6398S NVRAM | Rockchip rkwifibt package, commit `b2af9d94` | `92d89e67df52b9ffebde9ae852bb54f3fa10d5e3f8b4b777c9ff2fc5dd5fbf29` |
| BCM4359 Bluetooth HCD | Rockchip rkwifibt package, commit `b2af9d94` | `afc05608aa0058cde4ddc0f51138ff1b7629997c9f53d67c4948838d783b1fa6` |

The Rockchip firmware package identifies Apache-2.0 and carries a NOTICE file
covering the selected AP6398S bundle.
That NOTICE is copied into the image as `NOTICE.rkwifibt` and pinned at SHA-256
`38751245389e1e23f73e6f5384b5cbe7fa972cc4410c5adc9c04b082a0b9561a`.
Its HCD is byte-for-byte identical to the Bluetooth firmware already validated on
the two reference boxes. Its NVRAM has the same AP6398S calibration content as the
previous test input, with normalized line endings and whitespace.

The first redistributable Wi-Fi candidate was a BCM4359B1 image from a Cypress
package. It failed on this board's BCM4359C0 module with an SDIO HT-clock timeout
and never created `wlan0`. The selected C0 firmware identifies itself as version
`9.87.51.11.18`. A RAM-only hardware test produced `wlan0`, found both 2.4 GHz and
5 GHz networks, associated at 5220 MHz, negotiated 780 Mbit/s in both directions,
and passed DHCP, public traffic, and DNS. No network names or addresses were
recorded.

The source repositories are:

- <https://github.com/nishantpoorswani/rkwifibt>

## Final image validation

License review and the replacement firmware's live hardware regression are
complete. Downloaded blobs remain out of the source repository; the build fetches
them, verifies every hash, and embeds the package NOTICE. The final image was
rebuilt with the selected C0 firmware and passed a cold USB boot on 2026-09-03.
The cold-loaded firmware matched the pinned hashes, created `wlan0`, scanned both
wireless bands without an HT-clock failure, and initialized Bluetooth successfully.
