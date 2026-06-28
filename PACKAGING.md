# Building the WhalePi `.deb` package

This repo can be built into a standalone Debian package so users install
WhalePi with a single `apt` command and remove it cleanly with `apt remove`.

The package (`whalepi`) is **architecture-independent** (`Architecture: all`):
it declares the system prerequisites as `Depends:` and downloads the
PAMGuard firmware at install time, so the same `.deb` works on any Pi.

## What the user gets

```bash
# Install (resolves Java 21, tmux, sqlite3, BLE deps, ... automatically)
sudo apt install ./whalepi_0.9.0-1_all.deb

# Remove
sudo apt remove whalepi      # keeps firmware, recordings and database
sudo apt purge  whalepi      # also removes the unpacked firmware
```

On install, the package's `postinst` runs `install_whalepi.sh` with
`SKIP_APT=1` (apt has already pulled the dependencies) to download the
firmware and configure I2C, the microphone and Bluetooth.

## Build it

The `.deb` must be built on a Debian/Ubuntu/Raspberry Pi OS machine (it
cannot be built on macOS). A Raspberry Pi itself works fine.

```bash
# One-time: install the build tools
sudo apt update
sudo apt install devscripts debhelper build-essential

# From the repo root:
dpkg-buildpackage -us -uc -b

# The .deb lands in the parent directory:
ls ../whalepi_*_all.deb
```

`-us -uc` skip GPG signing; `-b` builds a binary-only package.

### Optional: lint the result

```bash
sudo apt install lintian
lintian ../whalepi_*.deb
```

## Distribute it

Attach the resulting `whalepi_0.9.0-1_all.deb` to the matching
**GitHub Release**. Users then install with:

```bash
wget https://github.com/WhalePi/install_whalepi/releases/download/v0.9.0/whalepi_0.9.0-1_all.deb
sudo apt install ./whalepi_0.9.0-1_all.deb
```

## Files

| File | Purpose |
|------|---------|
| `debian/control`   | Package metadata + the `Depends:` list |
| `debian/changelog` | Version history (drives the package version) |
| `debian/rules`     | Build recipe (debhelper) |
| `debian/install`   | Installs `install_whalepi.sh` to `/usr/lib/whalepi/` |
| `debian/postinst`  | Runs configuration after install |
| `debian/postrm`    | Cleans up the firmware on `purge` (keeps data) |
| `debian/copyright` | Licensing |

## Bumping the version

1. Add a new top entry to `debian/changelog` (e.g. `whalepi (0.10.0-1) ...`).
2. Update the default `WHALEPI_VERSION` in `install_whalepi.sh` and in
   `debian/postinst` if the firmware release tag changed.
3. Rebuild and re-attach to the new GitHub Release.

## If you later want true `sudo apt install whalepi`

That requires hosting a signed APT repository (e.g. GitHub Pages +
[`aptly`](https://www.aptly.info/) or
[`reprepro`](https://wiki.debian.org/DebianRepository/SetupWithReprepro)).
The `.deb` produced here drops straight into such a repo unchanged — only
the hosting and a one-time `sources.list.d` entry on the client are extra.
