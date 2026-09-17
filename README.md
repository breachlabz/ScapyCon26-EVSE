# ScapyCon26 EVSE Badge — Flash Kit

Pre-built factory firmware image and one-shot flashing script for the
**ScapyCon 2026** conference badge (ESP32-C5), running in **Pocket EVSE**
mode — an OCPP-speaking charge point simulator built into the badge.

Firmware source lives at
[dissecto-GmbH/scapycon-2026-badge-firmware](https://github.com/dissecto-GmbH/scapycon-2026-badge-firmware).
This repo just packages a ready-to-flash binary + script so you don't
need to set up ESP-IDF to get a badge running.

> **Wi-Fi note:** `factory_flash.bin` ships with placeholder Wi-Fi
> credentials (`YOUR_WIFI_SSID` / `YOUR_WIFI_PASSWORD`), not any real
> network's password. You set your own Wi-Fi after flashing (see below).

## Requirements

- A ScapyCon 2026 badge (ESP32-C5)
- USB cable
- [`esptool`](https://github.com/espressif/esptool) (`pip install esptool`)

## Flashing

```bash
./flash.sh [PORT]      # default PORT: /dev/ttyACM0
```

1. Put the badge in download mode: hold **SW_BOOT**, then plug in USB
   (or hold **SW_BOOT** and tap **SW_RESET** if already plugged in).
2. Run `flash.sh`. It writes the whole `factory_flash.bin` image to
   offset `0x0` in a single write — this board has a dual-app-partition
   layout (`factory` + `ota_0`), and writing the main app to the wrong
   offset will brick it, so don't split this into per-partition writes.
3. Unplug and replug the badge (power cycle) to boot the new firmware.
   This chip's native USB-Serial/JTAG interface sometimes sits in the
   ROM download loader after a flash instead of booting cleanly — a
   physical power cycle reliably fixes this; software-only resets don't
   always.

## First-time setup (per badge)

The badge boots into EVSE mode via **SW_D**, but shows **"SETUP MODE"**
until it has both Wi-Fi and an OCPP identity. Open a serial terminal at
115200 baud while the badge is in Name mode and send:

```
wifi:SSID,PASSWORD
ocpp:ws://<csms-host>/<unique-charge-point-id>
```

Each badge needs its own OCPP charge point ID (the last path segment of
the URL) so the CSMS can tell badges apart.

## License

See the upstream firmware repo for licensing.
