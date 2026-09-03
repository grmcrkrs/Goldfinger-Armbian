# USB boot and eMMC installation

These instructions apply only to a PCB marked `GOLDFINGER_V14` with
`2021-12-07` printed directly below it.

## Recommended path: finished release image

1. Download the revision-tagged `.img.gz` and matching `.sha256` release assets.
2. Verify them with `sha256sum -c FILE.img.gz.sha256`.
3. Flash the compressed image to a disposable USB with a verifying image writer.
4. Insert the USB in the blue B1 port while the box is powered off.
5. Wire a 3.3 V TTL UART adapter as described in `docs/hardware.md`.
6. Run `./boot-device.sh` as the normal Linux desktop user.
7. Apply box power only when the helper says to do so.
8. Complete Armbian first login locally and test the required hardware.
9. Run `sudo armbian-install` only after USB operation is satisfactory.
10. On success, run `poweroff`, remove power and USB, then cold-boot eMMC.
11. Reconnect the installation USB to a computer and preserve the complete
    `/ddbr/goldfinger-v14-*` recovery directory before reusing that media.

The helper requires Python 3 and permission to open the UART. On Ubuntu and
Debian, serial access normally comes from the `dialout` group. If an administrator
adds the user to that group, log out and back in before retrying.

## What the UART helper does

`tools/boot-usb-via-uart.py` watches for this factory U-Boot's countdown and sends
only these operations:

1. interrupt autoboot;
2. initialize USB storage;
3. load `aml_autoscript` from USB partition 1 into RAM; and
4. execute that RAM-resident script.

It never calls `saveenv`, the vendor updater, or a storage-write command. Remove
other USB storage from the box so the installation stick is USB device zero.
The normal output is a five-stage progress report. `--verbose` exposes the raw
UART log and should be used only for troubleshooting because factory logs contain
unique hardware identifiers.

## Manual spacebar fallback

Use this only when the helper does not recognize a bootloader variation.

Connect with your UART device path:

```sh
picocom --baud 115200 --noreset /dev/serial/by-id/YOUR_UART_DEVICE
```

With the box powered off, start pressing the spacebar repeatedly and apply power.
Continue until the `goldfinger#` prompt appears. Then enter these commands one at
a time:

```text
usb start
fatload usb 0:1 ${loadaddr} aml_autoscript
autoscr ${loadaddr}
```

The `fatload` command must report that bytes were read before `autoscr` is used.
If U-Boot reports no USB storage, power off, confirm the stick is in B1, remove
other storage, and retry. Do not improvise `saveenv`, `store`, `mmc write`,
`fatwrite`, `ext4write`, or `update` commands.

Exit picocom with Ctrl-A followed by Ctrl-X.

## First login and test drive

The stock Armbian first-login process may wait briefly for networking. Create
credentials only at that local prompt. The public image contains none.

Confirm that root and boot are on USB before installation:

```sh
findmnt /
findmnt /boot
```

They should resolve to USB partitions, normally `/dev/sda2` and `/dev/sda1` on
this board. Run `scripts/verify.sh` and the relevant parts of `docs/testing.md`.

## Guarded eMMC installer

Run:

```sh
sudo armbian-install
```

The Goldfinger integration condenses the board-specific work into this normal
command. It performs the following sequence:

1. selects model profile 528 and ext4 without asking the user to guess;
2. requires the expected DTB, SoC, PCB compatibility ID, eMMC size, and 512-byte
   logical sector geometry;
3. aborts if an eMMC partition is mounted;
4. advances a clearly stale offline clock only to the image build-time minimum;
5. creates and verifies protected-region backups on the USB;
6. writes only the validated MBR partition entries while preserving bootloader,
   reserved, environment, and hardware boot-partition regions;
7. formats, copies, and verifies the eMMC BOOT and root filesystems;
8. confirms critical kernel, initramfs, DTB, boot-script, and fstab contents;
9. asks twice before the final saved-environment activation; and
10. reads activation back, automatically restoring the saved environment backup
    if that small final update or its verification fails.

If either activation prompt is declined, Linux files remain on eMMC but the saved
factory startup remains unactivated. If installation reports any other failure,
stop and preserve the USB and UART output before attempting repair.

## First eMMC boot

After success:

```sh
poweroff
```

Wait for filesystem shutdown, physically disconnect power, remove the USB, and
restore power. A successful test reaches the login prompt with `/dev/mmcblk2p2`
mounted at `/` and `/dev/mmcblk2p1` at `/boot`.

## USB recovery precedence

Once the saved boot path has been activated, a prepared USB in B1 is tried before
the eMMC Armbian script. This behavior has been cold-boot tested without UART
input. It provides a recovery Linux system if the eMMC userspace later breaks.
It does not replace the need for UART when diagnosing U-Boot or raw-storage damage.

## Source reproduction

The release source is the Goldfinger board overlay applied to the pinned ophub
revision in `docs/provenance.md`. It produces the finished revision-tagged image,
including the guarded installer and offline board packages. Older scripts that
modified a generic USB after flashing were deliberately removed because they did
not reproduce the complete release.
