# Provenance and pinned inputs

## Reference software

- Release candidate:
  `Armbian_26.08.0_amlogic_goldfinger-v14-2021-12-07_noble_6.12.103_server_2026.09.03.img.gz`
- Release candidate SHA-256:
  `fb034022b05a3416fbd20155d75ce92427630cb0c79f9701ebf896c6df4bff4f`
- Release candidate uncompressed SHA-256:
  `1271c1f54a4d33a972e9e2d5fac7781280fd7d90d4ad7fe6df2ee65cb015d640`
- Goldfinger compatibility ID: `goldfinger-v14-2021-12-07`
- Pinned ophub source revision: `26ce84cdd716b307517e794880666ebb3ca19944`

- Pinned image: `Armbian_26.08.0_amlogic_s905x3_noble_6.12.103_server_2026.08.15.img.gz`
- Pinned image SHA-256: `c703b8723cddaeedd4f813b07ee51e8428197ce28bed0c3b1bba6fc898d79560`
- Uncompressed image SHA-256:
  `97776096fa40f0f38d64e5ef11fddd0f1738d3b20753a6dd6d1524f5da60c4be`
- Official release tag: `Armbian_noble_arm64_server_2026.08`
- Userspace: Armbian-unofficial 26.08.0-trunk, Ubuntu Noble
- Kernel: 6.12.103-ophub
- Base DTB: `meson-sm1-x96-max-plus-100m.dtb`
- Base DTB SHA-256: `386cdd6714f2e507db8b443c263c1a7d5fb7facc24bce9c8b2208d8bfe5c67eb`
- Base decompiled DTS SHA-256: `3412fbc87bc9c30fbc13fe302513981dcadcf365ce88fd2eed4837d90f41e440`
- Proven r6 DTB SHA-256: `52bc2785e5c9e3c204e9feee20e3dff774f702880b6dd69489536f627b0bcfab`

The DTB byte hash depends on the same `dtc` representation and build input. The
script verifies both base and output hashes so an upstream change fails closed.

## Wireless firmware

The firmware fetcher pins and verifies:

- AP6398S Wi-Fi firmware SHA-256:
  `e59d485296365ca17bd7f9cfa7be390b0b58019ee9e2d59fb78445fa33d27d48`
- AP6398S NVRAM SHA-256:
  `92d89e67df52b9ffebde9ae852bb54f3fa10d5e3f8b4b777c9ff2fc5dd5fbf29`
- AP6398S Bluetooth HCD SHA-256:
  `afc05608aa0058cde4ddc0f51138ff1b7629997c9f53d67c4948838d783b1fa6`

The BCM4359C0 Wi-Fi binary, NVRAM, byte-identical physically tested Bluetooth HCD,
and Apache NOTICE are fetched from the Rockchip Wi-Fi/Bluetooth package at commit
`b2af9d94739922cbafb8c92514d2fa79c1e71a59`. The NOTICE is embedded in the image
and validated by hash. See `docs/redistribution.md`.

## Offline installer packages

The final image also embeds checksum-pinned Ubuntu Noble arm64 packages needed for
the guarded U-Boot environment access and offline Bluetooth setup. Their exact
versions, repository origin, and hashes are recorded in `docs/redistribution.md`;
their packaged copyright files remain installed.
