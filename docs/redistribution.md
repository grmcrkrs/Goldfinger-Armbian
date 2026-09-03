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

## Binary-image publication hold

The tested image adds these AP6398S firmware inputs:

| Installed purpose | Source | SHA-256 |
|---|---|---|
| BCM4359 Wi-Fi firmware | AOSP Amlogic Yukawa, pinned commit | `3523a4507e2da4d956eeccab58692f209feb1cbfede07c2b5157e3812d3f10f2` |
| AP6359/AP6398S NVRAM | AOSP Amlogic Yukawa, pinned commit | `280d4ed2cd8775560805349d3f6c177b18ff27a8ee423b80c4115a400124d902` |
| BCM4359 Bluetooth HCD | Khadas Fenix | `afc05608aa0058cde4ddc0f51138ff1b7629997c9f53d67c4948838d783b1fa6` |

The AOSP tree marks the package as having proprietary material and does not
provide a clear redistribution grant for these exact blobs. The Khadas Fenix
repository's project license does not, by itself, prove that its third-party
firmware blob is covered by that license. The exact files were not found in the
official linux-firmware tree, whose inclusion policy requires an explicit
redistribution basis.

Therefore:

- the source repository may contain checksums and download/build instructions;
- it must not commit the downloaded firmware blobs;
- the tested binary image must not be uploaded publicly yet; and
- publication can proceed after an authoritative license or permission covering
  redistribution of these exact files is identified.

If that permission cannot be established, the safe fallback is a public image
without these three additions plus a clearly separate, user-run firmware fetch
step. Ethernet and the UART boot path do not depend on those additions, but
Wi-Fi and Bluetooth would not be advertised as working out of the box.
