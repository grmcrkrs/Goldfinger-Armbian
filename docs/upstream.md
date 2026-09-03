# Upstream submission

The tested implementation was rebased onto ophub commit
`7d2a755c0c4d36e0592195346290900278b89f9d` and submitted as
[ophub/amlogic-s9xxx-armbian#3655](https://github.com/ophub/amlogic-s9xxx-armbian/pull/3655).
It is split into two commits so maintainers can evaluate reusable framework
changes independently from this board.

## Change 1: generic board hooks

The first change adds optional hooks to the existing Amlogic image builder and
`armbian-install`:

- load a board-specific release file with error handling;
- allow a board image to select a validated model and filesystem;
- allow a validated direct-boot profile without a U-Boot overload file;
- delegate non-generic eMMC partitioning to a board hook;
- validate a constructed root filesystem before compression; and
- run a board activation hook only after both Linux filesystems are copied.

Without a board release file, the normal upstream path remains unchanged. The
minimal-container loop-device-node workaround is a separate build-host fix and
must not be folded into the board-support change without maintainer agreement.

## Change 2: Goldfinger board support

The second change adds:

- model ID 528 for `GOLDFINGER_V14 / 2021-12-07`;
- the Goldfinger DTB patch and 720p-compatible `uEnv.txt`;
- RAM-only USB and eMMC boot-script sources;
- exact board/eMMC validation and protected-region backup logic;
- twice-confirmed, verified, rollback-capable saved-environment activation;
- AP6398S Wi-Fi/Bluetooth setup and offline Ubuntu package installation; and
- stable physical USB port labels.

The submission states that qualification covers two boards with the exact PCB
marking/date and remains experimental community support.

## Generated and downloaded files

Do not commit:

- compressed or uncompressed operating-system images;
- generated `aml_autoscript`, `s905_autoscript`, or `emmc_autoscript` files;
- downloaded firmware binaries or NVRAM files;
- downloaded Ubuntu `.deb` packages;
- raw UART logs; or
- per-device backup material.

The preparation script downloads pinned inputs, verifies their SHA-256 hashes,
and generates U-Boot scripts locally. The published binary passed the completed
redistribution review in `docs/redistribution.md`; source review does not require
committing the blobs.

## Evidence in the submission

Link the standalone release documentation rather than attaching raw logs. The
useful evidence is the exact PCB boundary, final image hashes, two-unit boot and
installation results, tested peripherals, known limitations, and the documented
recovery model. Any UART excerpt must first be redacted of unique identifiers.
The PR links the standalone experimental release and includes summarized hardware
evidence only; it does not attach raw UART output.
