# Safety model

## Hardware boundary

Use this image only on a PCB marked `GOLDFINGER_V14 / 2021-12-07`. A matching
case is not proof of compatible hardware. Use a 3.3 V TTL UART adapter; RS-232
levels or connecting a power rail can damage the board.

## First USB boot

The recommended helper and manual fallback use RAM-only U-Boot operations. They
may initialize USB, load files into RAM, and execute the loaded script. They must
not call `saveenv`, `store`, `mmc write`, `fatwrite`, `ext4write`, or the vendor
`update` command.

An untouched box still requires UART interruption. Do not advertise this image as
a universal plug-and-play USB boot for factory units.

## Guarded eMMC installation

Do not select a similar generic Amlogic profile. This image locks
`armbian-install` to Goldfinger model 528 and ext4.

Before writing, the installer requires:

- the expected Goldfinger DTB, S905X3 profile, and PCB compatibility metadata;
- an MMC whole disk in the validated 16 GB capacity class;
- 512-byte logical sectors and the expected partition geometry;
- no mounted eMMC filesystems; and
- sufficient USB space for verified protected-region backups.

The validated layout preserves these factory regions:

| Region | Range |
|---|---|
| Factory bootloader | 0-4 MiB, except the DOS partition entries in sector zero |
| Reserved data | 36-100 MiB |
| Saved U-Boot environment | 116-124 MiB until final activation |
| Linux BOOT | starts at 132 MiB; 511 MiB |
| Linux root | starts at 644 MiB; remainder of eMMC |

The installer copies and verifies Linux before its final, twice-confirmed saved
environment update. It retains the factory U-Boot binary. If activation or its
read-back fails, it attempts to restore the saved environment backup immediately.

## Recovery backup retention

The installer creates `/ddbr/goldfinger-v14-TIMESTAMP` on the installation USB.
It contains per-unit raw data and must never be committed, uploaded, or shared.

After proving the first USB-free eMMC boot:

1. reconnect the installation USB to a trusted computer;
2. copy the entire recovery directory to protected local storage;
3. run `sha256sum --status -c SHA256SUMS` inside the copy; and
4. retain both the verified USB image and a working UART adapter.

The public USB writer refuses to erase a disk while this recovery directory is
present. Do not bypass that guard merely to save time.

The backup is diagnostic and repair material, not a one-click factory-reset image.
Raw restoration can overwrite current per-unit state and must be based on a
specific diagnosis. A full raw factory restoration has not been rehearsed.

## Recovery boot

After eMMC activation, a prepared USB in B1 is attempted before eMMC and has been
cold-boot tested without UART input. This can recover from a broken Linux root
filesystem. Damage to factory U-Boot, its environment, or early eMMC regions may
still require UART and targeted raw repair.

## Failure rule

If an installer check fails, stop. Preserve the USB, its recovery directory, and
a redacted UART log. Do not retry with a different model, generic partitioner, or
commands copied from an unrelated Amlogic box.
