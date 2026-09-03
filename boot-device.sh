#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 0 ]; then
	printf 'Usage: ./boot-device.sh\n' >&2
	exit 2
fi
if [ "$(id -u)" -eq 0 ]; then
	printf 'ERROR: run this command as the normal desktop user, not root.\n' >&2
	exit 1
fi
for command_name in picocom python3 readlink seq; do
	command -v "$command_name" >/dev/null 2>&1 || {
		printf 'ERROR: required command is missing: %s\n' "$command_name" >&2
		exit 1
	}
done

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

cat <<'EOF'

GOLDFINGER V14 — BOOT THE ARMBIAN USB
======================================
Validated PCB marking: GOLDFINGER_V14 / 2021-12-07

Stop if the date printed below GOLDFINGER_V14 on the PCB differs.

1. Disconnect power from the box.
2. Insert the prepared Armbian USB into the blue B1 port.
3. Connect a 3.3 V TTL UART adapter:
     box TX  -> adapter RX
     box RX  -> adapter TX
     box GND -> adapter GND
4. Do not connect a 3.3 V or 5 V power rail.
5. Connect the UART adapter's USB cable to this computer.
6. Leave box power disconnected until the program tells you to apply it.

This helper sends only RAM-only U-Boot commands. It does not call saveenv or
write eMMC. Remove other USB storage devices from the box during this step.

Take as long as needed; this wiring step has no timeout.
EOF
read -r -p 'Press Enter when USB and UART are connected and box power is off. '

uart_devices=()
for attempt in $(seq 1 30); do
	shopt -s nullglob
	serial_candidates=(/dev/serial/by-id/*)
	shopt -u nullglob
	uart_devices=()
	for candidate in "${serial_candidates[@]}"; do
		case "$(readlink -f "$candidate")" in
			/dev/ttyUSB*|/dev/ttyACM*) uart_devices+=("$candidate") ;;
		esac
	done
	if [ "${#uart_devices[@]}" -eq 0 ]; then
		shopt -s nullglob
		uart_devices=(/dev/ttyUSB* /dev/ttyACM*)
		shopt -u nullglob
	fi
	[ "${#uart_devices[@]}" -gt 0 ] && break
	printf '\rWaiting for a UART adapter... %2d/30' "$attempt"
	sleep 1
done
printf '\r%*s\r' 48 ''
[ "${#uart_devices[@]}" -gt 0 ] || {
	printf 'ERROR: no USB UART adapter was detected.\n' >&2
	exit 1
}

if [ "${#uart_devices[@]}" -eq 1 ]; then
	uart="${uart_devices[0]}"
	printf 'UART detected: %s\n' "$uart"
else
	printf 'Detected UART adapters:\n'
	for index in "${!uart_devices[@]}"; do
		printf '  [%d] %s\n' "$((index + 1))" "${uart_devices[$index]}"
	done
	read -r -p 'Choose the UART adapter number: ' choice
	case "$choice" in
		''|*[!0-9]*) printf 'ERROR: enter one number from the list.\n' >&2; exit 1 ;;
	esac
	if [ "$choice" -lt 1 ] || [ "$choice" -gt "${#uart_devices[@]}" ]; then
		printf 'ERROR: selection is outside the displayed list.\n' >&2
		exit 1
	fi
	uart="${uart_devices[$((choice - 1))]}"
fi

"$script_dir/tools/boot-usb-via-uart.py" "$uart"

cat <<'EOF'

USB BOOT PASSED
Armbian has reached user space from removable USB.
The first-login program may wait briefly for networking before asking questions.
Enter passwords only at the local serial prompt; never paste them into an issue.
Exit picocom with Ctrl-A, then Ctrl-X.
EOF
picocom --baud 115200 --noreset "$uart"
