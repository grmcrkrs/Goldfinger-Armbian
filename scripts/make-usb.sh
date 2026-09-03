#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat >&2 <<'EOF'
Usage:
  make-usb.sh --image IMAGE --sha256 HASH --device /dev/DEVICE
              [--description TEXT] [--write]

The default is a read-only dry run. --write enables two interactive confirmations,
writes the entire image, and verifies every written byte. IMAGE may be .img, .xz,
or .gz. HASH is the publisher's checksum of that downloaded file. The target must
be an unmounted removable USB disk, not a partition.
EOF
	exit 2
}

image=""
expected_image_hash=""
device=""
description="Custom disk image"
write_mode="no"

while [ "$#" -gt 0 ]; do
	case "$1" in
		--image) [ "$#" -ge 2 ] || usage; image="$2"; shift 2 ;;
		--sha256) [ "$#" -ge 2 ] || usage; expected_image_hash="$2"; shift 2 ;;
		--description) [ "$#" -ge 2 ] || usage; description="$2"; shift 2 ;;
		--device) [ "$#" -ge 2 ] || usage; device="$2"; shift 2 ;;
		--write) write_mode="yes"; shift ;;
		-h|--help) usage ;;
		*) usage ;;
	esac
done

[ -n "$image" ] && [ -n "$expected_image_hash" ] && [ -n "$device" ] || usage
[ -f "$image" ] || { printf 'Error: image not found: %s\n' "$image" >&2; exit 1; }
case "$expected_image_hash" in
	*[!0-9a-fA-F]*|'') printf 'Error: --sha256 must be a hexadecimal SHA-256.\n' >&2; exit 1 ;;
esac
[ "${#expected_image_hash}" -eq 64 ] || {
	printf 'Error: --sha256 must contain exactly 64 hexadecimal characters.\n' >&2
	exit 1
}
printf '[1/4] Verifying the downloaded image checksum...\n'
actual_image_hash="$(sha256sum "$image" | awk '{print $1}')"
[ "${actual_image_hash,,}" = "${expected_image_hash,,}" ] || {
	printf 'Error: downloaded image checksum does not match the supplied checksum.\n' >&2
	exit 1
}
printf '      Checksum verified.\n'

printf '[2/4] Validating the selected USB target...\n'
[ -b "$device" ] || { printf 'Error: target is not a block device: %s\n' "$device" >&2; exit 1; }
[ "$(lsblk -dnro TYPE "$device")" = "disk" ] || {
	printf 'Error: target must be a whole disk, not a partition.\n' >&2
	exit 1
}

canonical_device="$(readlink -f "$device")"
transport="$(lsblk -dnro TRAN "$canonical_device")"
removable="$(lsblk -dnro RM "$canonical_device")"
[ "$transport" = "usb" ] && [ "$removable" = "1" ] || {
	printf 'Error: target is not reported as a removable USB disk.\n' >&2
	exit 1
}

root_source="$(findmnt -nro SOURCE / 2>/dev/null || true)"
root_parent=""
if [ -n "$root_source" ]; then
	root_parent="$(lsblk -no PKNAME "$root_source" 2>/dev/null | head -n1 || true)"
fi
if [ -n "$root_parent" ] && [ "$canonical_device" = "/dev/$root_parent" ]; then
	printf 'Error: refusing to overwrite the disk containing the running root filesystem.\n' >&2
	exit 1
fi

if lsblk -nrpo MOUNTPOINT "$canonical_device" | awk 'NF { found=1 } END { exit !found }'; then
	printf 'Error: the target or one of its partitions is mounted. Unmount it first.\n' >&2
	exit 1
fi
printf '      Target is an unmounted removable USB whole disk.\n'

stream_image() {
	case "$image" in
		*.xz) xz -dc -- "$image" ;;
		*.gz) gzip -dc -- "$image" ;;
		*) cat -- "$image" ;;
	esac
}

format_dd_progress() {
	total="$1"
	label="$2"
	awk -v RS='\r' -v total="$total" -v label="$label" '
		$1 ~ /^[0-9]+$/ && $2 == "bytes" {
			bytes=$1
			percent=int((bytes * 100) / total)
			printf "\r      %-9s %3d%%  %.2f / %.2f GiB", label, percent,
				bytes / 1073741824, total / 1073741824
			fflush()
		}
		END { printf "\n" }
	' >&2
}

printf '[3/4] Testing decompression and measuring the image...\n'
measure_file="$(mktemp)"
trap 'rm -f "$measure_file"' EXIT
(stream_image | wc -c > "$measure_file") &
measure_pid=$!
elapsed=0
while kill -0 "$measure_pid" 2>/dev/null; do
	printf '\r      Reading image stream... %3d seconds elapsed' "$elapsed" >&2
	sleep 1
	elapsed=$((elapsed + 1))
done
if ! wait "$measure_pid"; then
	printf '\nError: the image could not be decompressed completely.\n' >&2
	exit 1
fi
printf '\r      Image stream complete in %d seconds.          \n' "$elapsed" >&2
source_bytes="$(cat "$measure_file")"
rm -f "$measure_file"
trap - EXIT
target_bytes="$(lsblk -bdnro SIZE "$canonical_device" | xargs)"
[ -n "$target_bytes" ] && [ "$target_bytes" -gt 0 ] || {
	printf 'Error: could not determine target capacity.\n' >&2
	exit 1
}
[ "$source_bytes" -le "$target_bytes" ] || {
	printf 'Error: the uncompressed image is larger than the target disk.\n' >&2
	exit 1
}
printf '      Image stream is readable and fits on the target.\n'

source_size="$(numfmt --to=iec-i --suffix=B "$source_bytes")"
target_size="$(lsblk -dnro SIZE "$canonical_device")"
target_model="$(lsblk -dno MODEL "$canonical_device" | sed 's/[[:space:]]*$//')"

printf '[4/4] Preflight summary\n\n'
printf 'READY TO FLASH\n'
printf '  Image\n'
printf '    Build:       %s\n' "$description"
printf '    Size:        %s\n' "$source_size"
printf '    Integrity:   PASS\n'
printf '  USB drive\n'
printf '    Device:      %s\n' "$canonical_device"
printf '    Model:       %s\n' "$target_model"
printf '    Capacity:    %s\n' "$target_size"
printf '  Safety checks\n'
printf '    Removable:   PASS\n'
printf '    Unmounted:   PASS\n'
printf '    Image fits:  PASS\n\n'

if [ "$write_mode" != "yes" ]; then
	printf 'DRY RUN COMPLETE — NOTHING WAS ERASED OR WRITTEN.\n'
	printf 'Rerun with --write only when you are ready to erase this USB drive.\n'
	exit 0
fi

[ "$(id -u)" -eq 0 ] || {
	printf 'Error: --write must be run as root after reviewing the dry run.\n' >&2
	exit 1
}
[ -t 0 ] && [ -t 1 ] || {
	printf 'Error: writing requires an interactive terminal.\n' >&2
	exit 1
}

# Refuse to erase an installation USB that still holds a board recovery set.
# This checks only the expected directory name and never reads backup contents.
command -v debugfs >/dev/null 2>&1 || {
	printf 'Error: debugfs is required for the recovery-backup safety check.\n' >&2
	exit 1
}
while read -r partition fstype; do
	[ "$fstype" = "ext4" ] || continue
	if debugfs -R 'ls -p /ddbr' "$partition" 2>/dev/null |
		grep -q '/goldfinger-v14-'; then
		printf 'Error: %s contains a Goldfinger boot-chain recovery backup.\n' "$partition" >&2
		printf 'Copy and verify that backup elsewhere before reusing this USB drive.\n' >&2
		exit 1
	fi
done < <(lsblk -nrpo NAME,FSTYPE "$canonical_device" | awk 'NF == 2 {print $1, $2}')

printf '\nALL DATA ON %s WILL BE DESTROYED.\n' "$canonical_device"
read -r -p "Confirm this choice? (y/n) " confirm_first
case "$confirm_first" in
	y|Y) ;;
	*) printf 'Not confirmed; nothing was written.\n' >&2; exit 1 ;;
esac
read -r -p "Confirm again? (y/n) " confirm_second
case "$confirm_second" in
	y|Y) ;;
	*) printf 'Second confirmation declined; nothing was written.\n' >&2; exit 1 ;;
esac

if [ "$write_mode" != "yes" ]; then
	printf 'Internal safety error: write mode was not enabled.\n' >&2
	exit 1
fi

printf '\nPLEASE WAIT THROUGH ALL 3 STEPS.\n'
printf '  1/3  Write and flush the image (usually the slowest step)\n'
printf '  2/3  Checksum the source image\n'
printf '  3/3  Read the USB back and verify it\n'
printf 'Temporary pauses are normal. Do not remove the USB drive.\n\n'

printf '[1/3] Writing the image to %s...\n' "$canonical_device"
stream_image | dd of="$canonical_device" bs=16M conv=fsync status=progress \
	2> >(format_dd_progress "$source_bytes" "Written")
sync
printf '      Write complete.\n'

printf '[2/3] Calculating the uncompressed source checksum...\n'
source_hash="$(stream_image | dd bs=16M status=progress \
	2> >(format_dd_progress "$source_bytes" "Source") | sha256sum | awk '{print $1}')"
printf '      Source checksum complete.\n'

printf '[3/3] Reading the USB back for byte-for-byte verification...\n'
device_hash="$(dd if="$canonical_device" bs=16M count="$source_bytes" \
	iflag=count_bytes status=progress \
	2> >(format_dd_progress "$source_bytes" "Read back") | sha256sum | awk '{print $1}')"
printf '      Readback checksum complete.\n'
[ "$source_hash" = "$device_hash" ] || {
	printf 'Error: verification failed. Do not use this USB drive.\n' >&2
	exit 1
}

printf '\nFLASH COMPLETE\n'
printf '  Written:      %s\n' "$source_size"
printf '  Read back:    %s\n' "$source_size"
printf '  Verification: PASS — the USB exactly matches the source image\n'
printf 'The USB drive is ready for board-support staging.\n'
