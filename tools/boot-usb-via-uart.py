#!/usr/bin/env python3
"""Boot the prepared Goldfinger Armbian USB through the vendor UART console."""

import argparse
import os
import select
import sys
import termios
import time


COUNTDOWN = b"Hit Enter or space or Ctrl+C key"
PROMPT = b"goldfinger#"
USB_READY = b"1 Storage Device(s) found"
SCRIPT_NAME = b"reading aml_autoscript"
SCRIPT_LOADED = b"bytes read"
SCRIPT_MARKER = b"Goldfinger USB boot: RAM-only session"
USERSPACE_MARKERS = (b"armbian login:", b"Create root password:")


def configure_uart(fd: int) -> list:
    previous = termios.tcgetattr(fd)
    attrs = termios.tcgetattr(fd)
    attrs[0] = 0
    attrs[1] = 0
    attrs[2] = termios.CLOCAL | termios.CREAD | termios.CS8
    attrs[3] = 0
    attrs[4] = termios.B115200
    attrs[5] = termios.B115200
    attrs[6][termios.VMIN] = 0
    attrs[6][termios.VTIME] = 1
    termios.tcsetattr(fd, termios.TCSANOW, attrs)
    termios.tcflush(fd, termios.TCIOFLUSH)
    return previous


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Boot the prepared Armbian USB through Goldfinger U-Boot."
    )
    parser.add_argument("device", help="UART device path")
    parser.add_argument(
        "--timeout",
        type=float,
        default=180.0,
        help="overall timeout in seconds (default: 180)",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="show the raw boot log, which can contain hardware identifiers",
    )
    args = parser.parse_args()

    if args.timeout <= 0:
        parser.error("--timeout must be greater than zero")

    try:
        fd = os.open(args.device, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
    except FileNotFoundError:
        print(f"ERROR: UART device does not exist: {args.device}", file=sys.stderr)
        return 2
    except PermissionError:
        print(
            f"ERROR: permission denied opening {args.device}; check dialout membership.",
            file=sys.stderr,
        )
        return 2
    except OSError as error:
        print(f"ERROR: cannot open UART: {error}", file=sys.stderr)
        return 2

    try:
        previous = configure_uart(fd)
    except Exception:
        os.close(fd)
        raise

    deadline = time.monotonic() + args.timeout
    state = "countdown"
    recent = bytearray()
    usb_seen = False
    script_seen = False
    size_seen = False
    boot_script_started = False

    print("Goldfinger USB UART boot")
    print("  UART: 115200 8N1")
    print("  Storage writes: none from this launcher")
    print("[1/5] UART ready. Apply power to the box now.", flush=True)

    def send(command: bytes) -> None:
        os.write(fd, command + b"\r")
        termios.tcdrain(fd)

    try:
        while time.monotonic() < deadline:
            readable, _, _ = select.select([fd], [], [], 0.25)
            if not readable:
                continue

            try:
                data = os.read(fd, 4096)
            except BlockingIOError:
                continue
            if not data:
                continue

            if args.verbose:
                sys.stdout.buffer.write(data)
                sys.stdout.buffer.flush()

            recent.extend(data)
            if len(recent) > 16384:
                del recent[:-8192]

            if state == "countdown":
                if COUNTDOWN in recent:
                    send(b"")
                    state = "prompt"
                    recent.clear()
                elif PROMPT in recent:
                    state = "prompt"

            if state == "prompt" and PROMPT in recent:
                print("[2/5] U-Boot interrupted at goldfinger#.", flush=True)
                send(b"usb start")
                state = "usb"
                recent.clear()
                continue

            if state == "usb":
                usb_seen = usb_seen or USB_READY in recent
                if PROMPT in recent:
                    if not usb_seen:
                        print("FAIL: U-Boot did not find exactly one USB storage device.")
                        return 3
                    print("[3/5] USB storage detected.", flush=True)
                    send(b"fatload usb 0:1 ${loadaddr} aml_autoscript")
                    state = "load"
                    recent.clear()
                    continue

            if state == "load":
                script_seen = script_seen or SCRIPT_NAME in recent
                size_seen = size_seen or SCRIPT_LOADED in recent
                if PROMPT in recent:
                    if not (script_seen and size_seen):
                        print("FAIL: aml_autoscript was not loaded from USB partition 1.")
                        return 4
                    print("[4/5] RAM-only boot script loaded.", flush=True)
                    send(b"autoscr ${loadaddr}")
                    state = "boot"
                    recent.clear()
                    continue

            if state == "boot":
                boot_script_started = boot_script_started or SCRIPT_MARKER in recent
                if b"Goldfinger USB boot failed" in recent or PROMPT in recent:
                    print("FAIL: the USB boot script returned to U-Boot.")
                    return 5
                if boot_script_started and any(
                    marker in recent for marker in USERSPACE_MARKERS
                ):
                    print("[5/5] PASS: Armbian reached user-space login from USB.", flush=True)
                    print("The UART is released; use picocom if console access is needed.")
                    return 0
    finally:
        termios.tcsetattr(fd, termios.TCSANOW, previous)
        os.close(fd)

    print(f"FAIL: timed out during stage: {state}")
    if not args.verbose:
        print("Retry with --verbose to display the raw UART log.")
    return 6


if __name__ == "__main__":
    raise SystemExit(main())
