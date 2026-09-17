#!/usr/bin/env bash
#
# ScapyCon 2026 Badge — Pocket EVSE firmware flash script
#
# Flashes the monolithic factory image (bootloader + partition table +
# flashloader + main app + a default name/background) to a badge in one
# shot, at the correct offset (0x0). This is deliberately a single
# monolithic write, not separate per-partition writes — writing the main
# app to the wrong offset on this board's dual-app-partition layout
# (factory + ota_0) will brick it, which is exactly what happened once
# during development. Don't "optimize" this into more granular writes.
#
# This public image ships with placeholder Wi-Fi credentials
# (YOUR_WIFI_SSID / YOUR_WIFI_PASSWORD) — it does NOT contain any real
# network's SSID/password. Every badge needs its own Wi-Fi set after
# flashing (see below).
#
# Usage:
#   ./flash.sh [PORT]
# Default PORT: /dev/ttyACM0
#
# Before running: put the badge in download mode — hold SW_BOOT, then plug
# in USB (or hold SW_BOOT and tap SW_RESET if already plugged in).
#
# After flashing: unplug and replug the badge (or power-cycle it) to boot
# the new firmware. This chip's native USB-Serial/JTAG interface is known
# to sometimes sit in the ROM download loader after a flash instead of
# cleanly booting the app — a physical power cycle reliably fixes this,
# software-only reset tricks don't always.
#
# The badge boots into EVSE mode via SW_D, but EVSE mode will show
# "SETUP MODE" until it has both real Wi-Fi and an OCPP identity — set
# both once per badge over a serial terminal (115200 baud) while it's in
# Name mode:
#
#   wifi:SSID,PASSWORD
#   ocpp:ws://<csms-host>/<unique-charge-point-id>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="$SCRIPT_DIR/factory_flash.bin"
PORT="${1:-/dev/ttyACM0}"
CHIP="esp32c5"

info()  { printf '[*] %s\n' "$*"; }
ok()    { printf '[+] %s\n' "$*"; }
err()   { printf '[x] %s\n' "$*" >&2; }

if [[ ! -f "$IMAGE" ]]; then
    err "Missing $IMAGE — this script expects factory_flash.bin next to it."
    exit 1
fi

if command -v esptool.py >/dev/null 2>&1; then
    ESPTOOL=(esptool.py)
elif command -v esptool >/dev/null 2>&1; then
    ESPTOOL=(esptool)
elif python3 -c "import esptool" >/dev/null 2>&1; then
    ESPTOOL=(python3 -m esptool)
else
    err "esptool not found. Install with: pip install esptool"
    exit 1
fi

if [[ ! -e "$PORT" ]]; then
    err "$PORT not found. Is the badge plugged in?"
    exit 1
fi

if command -v fuser >/dev/null 2>&1 && fuser "$PORT" >/dev/null 2>&1; then
    err "$PORT is busy — another program has it open (e.g. screen/minicom/monitor)."
    err "Close that first, then retry."
    exit 1
fi

info "Flashing $(basename "$IMAGE") ($(stat -c%s "$IMAGE" 2>/dev/null || stat -f%z "$IMAGE") bytes) to $PORT"
info "If the badge isn't already in download mode: hold SW_BOOT, then plug/reset."

"${ESPTOOL[@]}" --chip "$CHIP" -p "$PORT" write_flash 0x0 "$IMAGE"

ok "Flash complete and verified."
echo
info "Now unplug and replug the badge (power cycle) to boot the new firmware."
info "Then, per badge, open a serial terminal at 115200 baud on $PORT in Name mode and set a unique OCPP identity:"
echo "        ocpp:ws://<csms-host>/<unique-charge-point-id>"
info "SW_D enters EVSE mode; it shows SETUP MODE until the line above has been sent."
