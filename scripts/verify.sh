#!/bin/sh
set -eu

expected_dtb_hash="52bc2785e5c9e3c204e9feee20e3dff774f702880b6dd69489536f627b0bcfab"
failures=0
warnings=0

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; failures=$((failures + 1)); }
warn() { printf 'WARN  %s\n' "$1"; warnings=$((warnings + 1)); }

printf 'Goldfinger privacy-safe, read-only baseline verification\n'
printf 'Kernel: %s\n' "$(uname -r)"

board_release="/etc/armbian-board-release.conf"
if [ -r "$board_release" ] &&
	grep -qx 'BOARD_COMPATIBILITY_ID="goldfinger-v14-2021-12-07"' "$board_release" &&
	grep -qx 'BOARD_PCB_MARKING="GOLDFINGER_V14"' "$board_release" &&
	grep -qx 'BOARD_PCB_DATE="2021-12-07"' "$board_release"; then
	pass "exact PCB compatibility metadata"
else
	fail "PCB compatibility metadata missing or unexpected"
fi

if [ -r /proc/device-tree/model ]; then
	model="$(tr -d '\000' < /proc/device-tree/model)"
	case "$model" in
		*Goldfinger*) pass "expected board model selected" ;;
		*) fail "unexpected board model" ;;
	esac
else
	fail "device-tree model unavailable"
fi

dtb_path="/boot/dtb/amlogic/meson-sm1-goldfinger-v14-r6.dtb"
if [ -f "$dtb_path" ]; then
	dtb_hash="$(sha256sum "$dtb_path" | awk '{print $1}')"
	[ "$dtb_hash" = "$expected_dtb_hash" ] && pass "proven r6 DTB hash" || fail "r6 DTB hash mismatch"
else
	fail "r6 DTB file missing"
fi

cpu_count="$(getconf _NPROCESSORS_ONLN)"
[ "$cpu_count" -eq 4 ] && pass "four CPUs online" || fail "expected four CPUs; found $cpu_count"

root_source="$(findmnt -nro SOURCE / 2>/dev/null || true)"
boot_source="$(findmnt -nro SOURCE /boot 2>/dev/null || true)"
root_parent="$(lsblk -no PKNAME "$root_source" 2>/dev/null | head -n1 || true)"
boot_parent="$(lsblk -no PKNAME "$boot_source" 2>/dev/null | head -n1 || true)"
if [ "$root_source" = "/dev/mmcblk2p2" ] && [ "$boot_source" = "/dev/mmcblk2p1" ]; then
	pass "root and boot are on validated eMMC partitions"
elif [ -n "$root_parent" ] && [ "$root_parent" = "$boot_parent" ]; then
	case "$root_parent" in
		sd*) pass "root and boot are on the same removable-media class disk" ;;
		*) fail "root and boot are not on a validated device pair" ;;
	esac
else
	fail "root and boot are not on a validated device pair"
fi

[ -e /sys/class/net/eth0 ] && pass "Ethernet interface present" || fail "Ethernet interface missing"
[ -e /sys/class/net/wlan0 ] && pass "Wi-Fi interface present" || fail "Wi-Fi interface missing"
[ -d /sys/class/bluetooth/hci0 ] && pass "Bluetooth controller present" || fail "Bluetooth controller missing"

if [ -r /sys/class/drm/card0-HDMI-A-1/status ]; then
	[ "$(cat /sys/class/drm/card0-HDMI-A-1/status)" = "connected" ] \
		&& pass "HDMI connected" || warn "HDMI not connected"
else
	warn "HDMI connector status unavailable"
fi

[ -d /sys/class/sound/card0 ] && pass "ALSA sound card present" || fail "ALSA sound card missing"

if command -v systemctl >/dev/null 2>&1; then
	failed_units="$(systemctl --failed --no-legend 2>/dev/null | wc -l)"
	[ "$failed_units" -eq 0 ] && pass "zero failed systemd units" || fail "$failed_units failed systemd unit(s)"
fi

if command -v lsmod >/dev/null 2>&1; then
	lsmod | awk '$1 == "btsdio" { found=1 } END { exit found ? 0 : 1 }' \
		&& fail "btsdio is loaded" || pass "false btsdio controller suppressed"
fi

if command -v usb-port-list >/dev/null 2>&1; then
	usb-port-list
fi

printf 'SUMMARY: %s failure(s), %s warning(s)\n' "$failures" "$warnings"
[ "$failures" -eq 0 ]
