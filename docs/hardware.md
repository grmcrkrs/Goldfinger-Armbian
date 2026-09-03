# Hardware notes

## Reference board

- Validated PCB marking: `GOLDFINGER_V14`
- Validated PCB date printed directly below it: `2021-12-07`
- Product/family reference: VWP-210-16
- SoC: Amlogic S905X3 (SM1)
- Memory/storage: 2 GiB RAM, 16 GiB eMMC on the tested unit
- Ethernet: RTL8211F-class gigabit PHY
- Wireless: AP6398S combo module (Broadcom BCM4359 family)
- Serial console: 115200 baud, 8 data bits, no parity, 1 stop bit

Board revisions and silent component substitutions are common in TV boxes. A matching
case or retail name is not proof of identical hardware. The public image filename and
embedded compatibility ID therefore include `2021-12-07`. Treat a different or absent
PCB date as unvalidated hardware even if the enclosure looks identical. The verification
script and visual board comparison are mandatory before writing eMMC.

## UART connection

Use a USB-UART adapter with **3.3 V TTL logic** at 115200 baud, 8 data bits, no
parity, and 1 stop bit. An RS-232-voltage adapter can damage the board. Disconnect
box power before wiring and connect only these signals:

| Box header | Ordinary USB-UART adapter |
|---|---|
| TX | RX |
| RX | TX |
| GND | GND |

Do not connect the box or adapter's 3.3 V or 5 V power pin.

The reference work repurposed a DX-SMART LoRa development board containing a CH340
USB-UART interface. Its tested mapping was box TX to PA9, box RX to PA10, and box
GND to board GND. The development board's RST was also tied to its own GND to hold
the STM32 in reset. That mapping is an example for this particular development
board, not a requirement for other UART adapters.

## Physical USB labels

Labels are neutral and describe the tested enclosure orientation:

| Label | Physical port | Linux topology | Tested capability |
|---|---|---|---|
| B1 | Blue | `2-1` | USB 3 bulk storage |
| W2 | White | `1-1.3` | USB 2 bulk storage |
| W3 | White | `1-1.1` | USB 2 bulk storage |
| W4 | White | `1-2` | Low-speed keyboard; high-speed storage provisional |

The udev rules provide `/dev/usb-port-B1`, `/dev/usb-port-W2`, and corresponding
partition aliases when block devices are attached.
