#!/usr/bin/env bash
#
# install_whalepi.sh — one-shot installer for WhalePi on a Raspberry Pi Zero 2 W
#
# This automates every step in install.md: it installs all prerequisites,
# downloads and unpacks the PAMGuard firmware, configures Bluetooth, I2C and
# the microphone, and (optionally) installs the auto-start service.
#
# Quick start (on the Pi, connected to the internet):
#
#   curl -sSL https://raw.githubusercontent.com/WhalePi/install_whalepi/main/install_whalepi.sh | sudo bash
#
# or download first and inspect before running:
#
#   wget https://raw.githubusercontent.com/WhalePi/install_whalepi/main/install_whalepi.sh
#   chmod +x install_whalepi.sh
#   sudo ./install_whalepi.sh
#
# Options (environment variables):
#   WHALEPI_VERSION   firmware release tag to install   (default: v0.9.0)
#   WHALEPI_USER      target user / home owner          (default: whalepi)
#   ENABLE_LEGACY_BT  "1" to also enable legacy Bluetooth Serial (SPP)
#   INSTALL_SERVICE   "1" to install the auto-start service at the end
#   START_NOW         "1" to launch the watchdog when finished
#   SKIP_APT          "1" to skip apt installs (used by the .deb, whose
#                     Depends: already provides the system packages)
#
# Example:
#   sudo INSTALL_SERVICE=1 WHALEPI_VERSION=v0.9.0 ./install_whalepi.sh
#
set -euo pipefail

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------
WHALEPI_VERSION="${WHALEPI_VERSION:-v0.9.0}"
WHALEPI_USER="${WHALEPI_USER:-whalepi}"
ENABLE_LEGACY_BT="${ENABLE_LEGACY_BT:-0}"
INSTALL_SERVICE="${INSTALL_SERVICE:-0}"
START_NOW="${START_NOW:-0}"
SKIP_APT="${SKIP_APT:-0}"

GH_REPO="WhalePi/install_whalepi"
ZIP_NAME="pamguard_pizero.zip"
ZIP_URL="https://github.com/${GH_REPO}/releases/download/${WHALEPI_VERSION}/${ZIP_NAME}"

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
log()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m  ✗ %s\033[0m\n' "$*" >&2; exit 1; }

# Run a command as the target (non-root) user
as_user() { sudo -u "$WHALEPI_USER" "$@"; }

# ----------------------------------------------------------------------------
# Pre-flight checks
# ----------------------------------------------------------------------------
[ "$(id -u)" -eq 0 ] || die "Please run as root:  sudo $0"

id "$WHALEPI_USER" >/dev/null 2>&1 \
  || die "User '$WHALEPI_USER' does not exist. Create it first, or set WHALEPI_USER."

HOME_DIR="$(getent passwd "$WHALEPI_USER" | cut -d: -f6)"
[ -n "$HOME_DIR" ] || die "Could not determine home directory for $WHALEPI_USER"
INSTALL_DIR="$HOME_DIR/pamguard_pizero"

log "WhalePi installer"
echo "    Release : $WHALEPI_VERSION"
echo "    User    : $WHALEPI_USER ($HOME_DIR)"
echo "    Target  : $INSTALL_DIR"
echo

# ----------------------------------------------------------------------------
# 1. APT packages
# ----------------------------------------------------------------------------
if [ "$SKIP_APT" = "1" ]; then
  warn "SKIP_APT=1 — assuming system packages are already installed (e.g. via .deb Depends)"
else
  log "Updating package lists"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y

  log "Installing system packages (Java 21, sqlite3, python deps, tmux, jq, ...)"
  apt-get install -y \
    openjdk-21-jdk \
    sqlite3 \
    python3-dbus python3-gi python3-pip \
    tmux jq \
    unzip wget \
    rfkill \
    alsa-utils
  ok "System packages installed"
fi

# ----------------------------------------------------------------------------
# 2. Download & unpack the firmware
# ----------------------------------------------------------------------------
if [ -d "$INSTALL_DIR" ]; then
  warn "$INSTALL_DIR already exists — skipping download (delete it to re-install)"
else
  log "Downloading firmware: $ZIP_URL"
  as_user wget -O "$HOME_DIR/$ZIP_NAME" "$ZIP_URL" \
    || die "Download failed. Check WHALEPI_VERSION ($WHALEPI_VERSION) is a valid release."
  log "Extracting firmware"
  as_user unzip -o -q "$HOME_DIR/$ZIP_NAME" -d "$HOME_DIR"
  rm -f "$HOME_DIR/$ZIP_NAME"
  [ -d "$INSTALL_DIR" ] || die "Expected $INSTALL_DIR after unzip but it is missing"
  ok "Firmware extracted to $INSTALL_DIR"
fi

# ----------------------------------------------------------------------------
# 3. Recording folder + blank database
# ----------------------------------------------------------------------------
log "Creating recording folder and database"
as_user mkdir -p "$HOME_DIR/PAMRecordings"
if [ ! -f "$HOME_DIR/whalepi_database.sqlite3" ]; then
  as_user sqlite3 "$HOME_DIR/whalepi_database.sqlite3" "VACUUM;"
  ok "Created blank database whalepi_database.sqlite3"
else
  ok "Database already present"
fi

# ----------------------------------------------------------------------------
# 4. Bluetooth Low Energy dependencies
# ----------------------------------------------------------------------------
BLE_SCRIPT="$INSTALL_DIR/utils/install_ble_deps.sh"
if [ -f "$BLE_SCRIPT" ]; then
  log "Installing Bluetooth LE dependencies"
  chmod +x "$BLE_SCRIPT"
  bash "$BLE_SCRIPT" || warn "BLE dependency script reported a problem (continuing)"
  ok "BLE dependencies installed"
else
  warn "BLE install script not found at $BLE_SCRIPT — skipping"
fi

log "Unblocking Bluetooth"
rfkill unblock bluetooth || warn "rfkill unblock bluetooth failed (continuing)"

# ----------------------------------------------------------------------------
# 4b. (Optional) Legacy Bluetooth Serial (SPP / compatibility mode)
# ----------------------------------------------------------------------------
if [ "$ENABLE_LEGACY_BT" = "1" ]; then
  log "Enabling legacy Bluetooth Serial (compatibility mode)"
  BT_SVC="/etc/systemd/system/dbus-org.bluez.service"
  if [ ! -f "$BT_SVC" ] && [ -f /lib/systemd/system/bluetooth.service ]; then
    cp /lib/systemd/system/bluetooth.service "$BT_SVC"
  fi
  if [ -f "$BT_SVC" ]; then
    # add -C to bluetoothd if not already present
    if ! grep -q 'bluetoothd .*-C' "$BT_SVC"; then
      sed -i -E 's#(ExecStart=/usr/lib(exec)?/bluetooth/bluetoothd)([^\n]*)#\1\3 -C#' "$BT_SVC"
    fi
    # add the SDP ExecStartPost line if not already present
    if ! grep -q 'sdptool add SP' "$BT_SVC"; then
      sed -i '/ExecStart=.*bluetoothd/a ExecStartPost=/usr/bin/sdptool add SP' "$BT_SVC"
    fi
    systemctl daemon-reload
    systemctl restart bluetooth || warn "Could not restart bluetooth"
    ok "Legacy Bluetooth Serial enabled"
  else
    warn "Bluetooth service file not found — skipping legacy serial setup"
  fi
fi

# ----------------------------------------------------------------------------
# 5. Microphone volume to zero (COSMOS cross-talk fix)
# ----------------------------------------------------------------------------
log "Setting microphone (Line) volume to zero"
amixer -c 0 set Line 0 >/dev/null 2>&1 \
  && ok "Microphone muted" \
  || warn "Could not set Line volume (sound card may not be attached yet)"

# ----------------------------------------------------------------------------
# 6. Enable I2C (for depth/temperature sensors) — non-interactive
# ----------------------------------------------------------------------------
log "Enabling I2C"
if command -v raspi-config >/dev/null 2>&1; then
  raspi-config nonint do_i2c 0 && ok "I2C enabled"
else
  warn "raspi-config not found — enable I2C manually if you need sensors"
fi

# ----------------------------------------------------------------------------
# 7. Ownership
# ----------------------------------------------------------------------------
log "Fixing ownership"
chown -R "$WHALEPI_USER":"$WHALEPI_USER" "$INSTALL_DIR" "$HOME_DIR/PAMRecordings" \
  "$HOME_DIR/whalepi_database.sqlite3"
chmod +x "$INSTALL_DIR"/*.sh "$INSTALL_DIR"/utils/*.sh 2>/dev/null || true

# ----------------------------------------------------------------------------
# 8. (Optional) auto-start service
# ----------------------------------------------------------------------------
if [ "$INSTALL_SERVICE" = "1" ]; then
  SVC_SCRIPT="$INSTALL_DIR/utils/install_whalepidog_service.sh"
  if [ -f "$SVC_SCRIPT" ]; then
    log "Installing auto-start service"
    chmod +x "$SVC_SCRIPT"
    ( cd "$INSTALL_DIR/utils" && bash "$SVC_SCRIPT" ) \
      && ok "Service installed — WhalePi will start on boot" \
      || warn "Service install reported a problem"
  else
    warn "Service installer not found at $SVC_SCRIPT — skipping"
  fi
fi

# ----------------------------------------------------------------------------
# 9. (Optional) start the watchdog now
# ----------------------------------------------------------------------------
if [ "$START_NOW" = "1" ]; then
  TMUX_SCRIPT=""
  for cand in whalepidog_pizero_tmux.sh pamdog_pizero_tmux.sh; do
    [ -f "$INSTALL_DIR/$cand" ] && TMUX_SCRIPT="$cand" && break
  done
  if [ -n "$TMUX_SCRIPT" ]; then
    log "Starting watchdog ($TMUX_SCRIPT)"
    as_user bash -c "cd '$INSTALL_DIR' && ./'$TMUX_SCRIPT'" \
      && ok "Watchdog started in tmux session 'pamguard'"
  else
    warn "Could not find a tmux launch script — start it manually"
  fi
fi

# ----------------------------------------------------------------------------
# Done
# ----------------------------------------------------------------------------
echo
ok "WhalePi installation complete!"
echo
echo "Next steps:"
echo "  • Reboot is recommended so I2C takes effect:   sudo reboot"
echo "  • Start the watchdog:   cd $INSTALL_DIR && ./whalepidog_pizero_tmux.sh"
echo "  • Attach to it:         tmux attach -t pamguard"
[ "$INSTALL_SERVICE" = "1" ] || \
echo "  • To auto-start on boot, re-run with: sudo INSTALL_SERVICE=1 $0"
