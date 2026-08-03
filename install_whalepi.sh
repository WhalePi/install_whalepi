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
#   WHALEPI_VERSION   firmware release tag to install   (default: v0.9.4)
#   WHALEPI_USER      target user / home owner          (default: whalepi)
#   WHALEPI_NAME      short system name, max 6 letters/digits (e.g. 13 -> the
#                     system is "WhalePi_13"). If unset you are prompted for it.
#   ENABLE_LEGACY_BT  "1" to also enable legacy Bluetooth Serial (SPP)
#   INSTALL_SERVICE   install the start-on-boot service (default: 1, "0" skips)
#   START_NOW         "1" to launch the watchdog when finished
#   SKIP_APT          "1" to skip apt installs (used by the .deb, whose
#                     Depends: already provides the system packages)
#
# Example:
#   sudo WHALEPI_NAME=13 START_NOW=1 ./install_whalepi.sh
#
set -euo pipefail

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------
WHALEPI_VERSION="${WHALEPI_VERSION:-v0.9.4}"
WHALEPI_USER="${WHALEPI_USER:-whalepi}"
WHALEPI_NAME="${WHALEPI_NAME:-}"
ENABLE_LEGACY_BT="${ENABLE_LEGACY_BT:-0}"
INSTALL_SERVICE="${INSTALL_SERVICE:-1}"
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

# Valid system name: 1–6 characters, letters and digits only
valid_name() {
  case "$1" in
    "" ) return 1 ;;               # empty
    *[!A-Za-z0-9]* ) return 1 ;;   # any non-alphanumeric character
  esac
  [ "${#1}" -le 6 ]
}

# Obtain the system name from $WHALEPI_NAME or by prompting on the terminal.
# Works even when the script is piped to `sudo bash` by reading from /dev/tty.
prompt_name() {
  if [ -n "$WHALEPI_NAME" ]; then
    valid_name "$WHALEPI_NAME" \
      || die "WHALEPI_NAME='$WHALEPI_NAME' is invalid — use up to 6 letters/digits only."
    return
  fi
  if [ ! -r /dev/tty ]; then
    die "No system name given. Re-run with WHALEPI_NAME=<name> (up to 6 letters/digits), e.g. WHALEPI_NAME=13"
  fi
  while :; do
    printf 'Enter a short name for this WhalePi system (max 6 letters/digits, e.g. 13): ' > /dev/tty
    IFS= read -r WHALEPI_NAME < /dev/tty || die "Could not read a name from the terminal."
    if valid_name "$WHALEPI_NAME"; then
      break
    fi
    printf '  Invalid — use 1 to 6 letters or digits only (no spaces or symbols).\n' > /dev/tty
  done
}

# Locate the WhalePiDog settings JSON inside the firmware folder.
find_settings_file() {
  local f
  for f in whalepidog_settings.json watchdog_settings.json watchdog_settngs.json; do
    [ -f "$INSTALL_DIR/$f" ] && { printf '%s\n' "$INSTALL_DIR/$f"; return 0; }
  done
  # Fall back to the first *settings*.json shipped in the firmware root
  f="$(find "$INSTALL_DIR" -maxdepth 2 -iname '*settings*.json' 2>/dev/null | head -n1)"
  [ -n "$f" ] && { printf '%s\n' "$f"; return 0; }
  return 1
}

# ----------------------------------------------------------------------------
# Pre-flight checks
# ----------------------------------------------------------------------------
[ "$(id -u)" -eq 0 ] || die "Please run as root:  sudo $0"

id "$WHALEPI_USER" >/dev/null 2>&1 \
  || die "User '$WHALEPI_USER' does not exist. Create it first, or set WHALEPI_USER."

HOME_DIR="$(getent passwd "$WHALEPI_USER" | cut -d: -f6)"
[ -n "$HOME_DIR" ] || die "Could not determine home directory for $WHALEPI_USER"
INSTALL_DIR="$HOME_DIR/pamguard_pizero"

# Ask for the system name up front (before the long installs).
prompt_name

log "WhalePi installer"
echo "    Release : $WHALEPI_VERSION"
echo "    User    : $WHALEPI_USER ($HOME_DIR)"
echo "    Target  : $INSTALL_DIR"
echo "    Name    : WhalePi_$WHALEPI_NAME  (id=$WHALEPI_NAME, recordings=PAM$WHALEPI_NAME)"
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
# 3b. Apply the system name to the WhalePiDog settings
#     identification -> <name>,  recordingPrefix -> PAM<name>
# ----------------------------------------------------------------------------
log "Applying system name 'WhalePi_$WHALEPI_NAME' to the WhalePiDog settings"
if SETTINGS_FILE="$(find_settings_file)"; then
  if as_user jq \
        --arg id "$WHALEPI_NAME" \
        --arg pref "PAM$WHALEPI_NAME" \
        '.bluetoothSettings.identification = $id | .recordingPrefix = $pref' \
        "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"; then
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    chown "$WHALEPI_USER":"$WHALEPI_USER" "$SETTINGS_FILE"
    ok "Set identification=$WHALEPI_NAME and recordingPrefix=PAM$WHALEPI_NAME in $(basename "$SETTINGS_FILE")"
  else
    rm -f "$SETTINGS_FILE.tmp"
    warn "Could not update $SETTINGS_FILE (is it valid JSON?) — set identification/recordingPrefix by hand"
  fi
else
  warn "No WhalePiDog settings JSON found in $INSTALL_DIR — skipping name configuration"
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
# 8. Locate the watchdog launch script
# ----------------------------------------------------------------------------
TMUX_SCRIPT=""
for cand in whalepidog_pizero_tmux.sh pamdog_pizero_tmux.sh; do
  if [ -f "$INSTALL_DIR/$cand" ]; then
    TMUX_SCRIPT="$cand"
    chmod +x "$INSTALL_DIR/$cand"
    break
  fi
done
[ -n "$TMUX_SCRIPT" ] || warn "No watchdog launch script found in $INSTALL_DIR"

# ----------------------------------------------------------------------------
# 9. Auto-start service (set INSTALL_SERVICE=0 to skip)
#
# The unit is written here rather than delegating to the firmware's
# utils/install_whalepidog_service.sh, so that it always exists, honours
# WHALEPI_USER, and points at whichever launch script is actually shipped.
# ----------------------------------------------------------------------------
if [ "$INSTALL_SERVICE" = "1" ]; then
  if [ -z "$TMUX_SCRIPT" ]; then
    warn "Skipping boot service — no watchdog launch script to run"
  elif ! command -v systemctl >/dev/null 2>&1; then
    warn "systemctl not available — skipping boot service"
  else
    log "Installing auto-start service (whalepidog.service)"
    SERVICE_FILE="/etc/systemd/system/whalepidog.service"
    TMUX_BIN="$(command -v tmux 2>/dev/null || echo /usr/bin/tmux)"

    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=WhalePiDog Watchdog (tmux)
After=network.target

[Service]
Type=forking
User=$WHALEPI_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/$TMUX_SCRIPT
ExecStop=$TMUX_BIN kill-session -t pamguard
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    chmod 0644 "$SERVICE_FILE"
    ok "Wrote $SERVICE_FILE"

    systemctl daemon-reload || warn "systemctl daemon-reload failed"

    systemctl enable whalepidog.service || warn "systemctl enable reported an error"
    if systemctl is-enabled whalepidog.service >/dev/null 2>&1; then
      ok "Service enabled — WhalePi will start on boot"
    else
      warn "Service did NOT enable. Check: systemctl status whalepidog"
    fi
  fi
fi

# ----------------------------------------------------------------------------
# 10. (Optional) start the watchdog now
# ----------------------------------------------------------------------------
if [ "$START_NOW" = "1" ]; then
  if [ "$INSTALL_SERVICE" = "1" ] && [ -f /etc/systemd/system/whalepidog.service ]; then
    log "Starting whalepidog service"
    if systemctl start whalepidog.service; then
      ok "Service started — attach with: tmux attach -t pamguard"
    else
      warn "Could not start the service. Check: systemctl status whalepidog"
    fi
  elif [ -n "$TMUX_SCRIPT" ]; then
    log "Starting watchdog ($TMUX_SCRIPT)"
    as_user bash -c "cd '$INSTALL_DIR' && ./'$TMUX_SCRIPT'" \
      && ok "Watchdog started in tmux session 'pamguard'" \
      || warn "Watchdog launch reported a problem"
  else
    warn "Could not find a tmux launch script — start it manually"
  fi
fi

# ----------------------------------------------------------------------------
# Done
# ----------------------------------------------------------------------------
echo
ok "WhalePi installation complete!  System name: WhalePi_$WHALEPI_NAME"
echo
echo "Next steps:"
echo "  • Reboot is recommended so I2C takes effect:   sudo reboot"
if systemctl is-enabled whalepidog.service >/dev/null 2>&1; then
  echo "  • WhalePi will start automatically on boot (whalepidog.service)"
  echo "  • Start it now:         sudo systemctl start whalepidog"
  echo "  • Check it:             systemctl status whalepidog"
  echo "  • Disable auto-start:   sudo systemctl disable whalepidog"
else
  echo "  • Auto-start is NOT enabled. Re-run with: sudo INSTALL_SERVICE=1 $0"
  [ -n "${TMUX_SCRIPT:-}" ] && \
  echo "  • Start manually:       cd $INSTALL_DIR && ./$TMUX_SCRIPT"
fi
echo "  • Attach to the session: tmux attach -t pamguard"
