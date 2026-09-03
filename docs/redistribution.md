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
| BCM4359 Wi-Fi firmware | reMarkable Cypress mirror, commit `04f5d06f` | `47112a382d4fae929a6fdbd95c9bb968392b4ce54dc682bc7b359fe5fdaf5e02` |
| AP6398S NVRAM | Rockchip rkwifibt package, commit `b2af9d94` | `92d89e67df52b9ffebde9ae852bb54f3fa10d5e3f8b4b777c9ff2fc5dd5fbf29` |
| BCM4359 Bluetooth HCD | Rockchip rkwifibt package, commit `b2af9d94` | `afc05608aa0058cde4ddc0f51138ff1b7629997c9f53d67c4948838d783b1fa6` |

The Cypress mirror includes a source-and-binary distribution license that permits
redistributing its object code for use with Cypress integrated circuits. That
license is copied into the image as `LICENCE.cypress` and pinned at SHA-256
`3a892759b73e8b459f1a750954b316118b0061fd9d1868d11fa258c104ee7e0c`.
The selected Wi-Fi file also matches the generic ophub copy byte-for-byte.

The Rockchip firmware package identifies Apache-2.0 and carries a NOTICE file.
That NOTICE is copied into the image as `NOTICE.rkwifibt` and pinned at SHA-256
`38751245389e1e23f73e6f5384b5cbe7fa972cc4410c5adc9c04b082a0b9561a`.
Its HCD is byte-for-byte identical to the Bluetooth firmware already validated on
the two reference boxes. Its NVRAM has the same AP6398S calibration content as the
previous test input, with normalized line endings and whitespace.

The source repositories are:

- <https://github.com/reMarkable/brcmfmac-firmware>
- <https://github.com/nishantpoorswani/rkwifibt>

## Remaining publication gate

License review is no longer the blocking item. Downloaded blobs still remain out
of the source repository; the build fetches them, verifies every hash, and embeds
their license notices. The replacement Wi-Fi binary has not yet been physically
regression-tested on the Goldfinger board. Build the replacement image, verify it,
then confirm both 2.4/5 GHz Wi-Fi and Bluetooth before uploading release assets.
