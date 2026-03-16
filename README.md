# WhalePi

##
Welcome to WhalePi, a flexible passive acoustic recording and real-time analysis system based on a Raspberry Pi Zero and [PAMGuard](www.pamguard.org). The aim of WhalePi is to create a flexible medium-power recording system for cetaceans. Cetaceans cover over eight octaves, from the 100Hz calls of Blue Whales to the 130,000 Hz clicks of Kogia and porpoises, with some broadband click components going even higher in frequency. This means any recording system to cover all species needs to have both a high dynamic range (i.e., 24-bit), a high sample rate (i.e. 384,000 kS/s), and ideally multiple channels. WhalePi provides a solution to create such a system by running PAMGuard software on low-cost hardware, particularly a COSMOS DAQ card and Raspberry Pi Zero 2 W. 

PAMGuard is a highly flexible modular programme enabling users to create an acoustic workflow for real-time analysis.  It also integrates with various hardware like sound cards and GPS. WhalePi facilitates setting up a PAMGuard configuration and running it on a Raspberry Pi.  While most modern Raspberry Pi boards work, WhalePi is optimised for the Raspberry Pi Zero 2 W, which has medium power consumption. This allows for autonomous deployment for days or weeks on a large 12V battery or solar panels.  The Raspberry Pi supports up to 1TB of storage for recordings or detection. For instance, the system could save only PAMGuard’s automated click detector output, effectively unlimited storage.  

The COSMOS sound card connects to the Raspberry Pi and drivers have been developed to run it efficiently through PAMGuard.  This allows for 24-bit recordings with high dynamic range.  The sound card can manage stereo channels at a 384 kHz sample rate per channel covering all cetacean species provided a hydrophone with a suitable frequency response is used.  GPS and analogue sensors for depth and temperature can also be integrated. 

WhalePi  does not come with plans for an  housing but the COSMOS sound card and Raspberry Pi are relatively compact.  They can be mounted inside a small Peli Case or underwater housing like those made by BlueRobotics().  This potentially allows you to create an advanced PAM system for under $500. While WhalePi won’t replace devices like SoundTraps or CPODs it’s useful for situations where flexibility cost and/or real-time communication are important. 


---

## What you need

### Recommended hardware
- **Raspberry Pi Zero 2 W** (WhalePi is optimised for this board)
- **COSMOS DAQ** audio interface / sound card
- **Hydrophone** suitable for your target species and frequency range
- **Storage**: microSD / USB storage (up to 1TB supported by the Pi)
- **Power**: a stable 5V supply for bench testing, and a **12V battery** or **solar + battery** system for field deployments

### Optional hardware
- **GPS** (for timestamped position logging)
- **Analogue / I2C sensors** such as depth and temperature

---

## Installing WhalePi

1) **Prepare the Raspberry Pi**
- Follow the setup instructions in `install.md` to install prerequisites (Java 21, Bluetooth support, tmux, etc.) and configure the Pi.

2) **Download and transfer WhalePi**
- Download the latest release and transfer it to a user directory called `whalepi` e.g. `/home/whalepi/`.
- Unzip inside this folder - this should mean there is a folder called `/home/whalepi/pamguard_pizero`.

3) **Start WhalePi**
- From inside the package directory, start WhalePi using the watchdog script:
  - `./whalepidog_pizero.sh`

> Tip: `install.md` also describes an alternative tmux-based start script (`./pamdog_pizero_tmux.sh`). Use whichever start method your release includes.

---

## How WhalePi works (high level)

WhalePi is essentially:
- A Raspberry Pi running **PAMGuard** (the analysis engine)
- A high performance audio front-end (COSMOS DAQ) for **24-bit** recording at high sample rates
- A **watchdog script** that starts and monitors PAMGuard, and (optionally) exposes status/control over Bluetooth for use with a phone app

Typical workflows include:
- **Record raw audio** for later analysis
- **Run real-time detection** (e.g., click detection) and only save detections/summary products to reduce storage usage
- **Log metadata** (GPS, depth, temperature) alongside audio/detections

---

## Running and controlling WhalePi

Depending on the release you installed, PAMGuard may be launched inside a **tmux** session so it continues running after you disconnect from SSH.

### If using tmux
- Reattach:
  - `tmux attach -t pamguard`
- Detach without stopping (inside tmux):
  - `Ctrl+B` then `D`

### Common control commands
When connected to the running session, you can use commands like:
- `start` – begins audio processing
- `stop` – pauses/ends audio processing
- `summary` – displays current stats
- `status` – checks whether PAMGuard is running (1) or not (0)

For the full command set see the PAMGuard UDP command documentation:
https://github.com/PAMGuard/PAMGuard/wiki/UDP-Commands

---

## Viewing data

There are three ways to view data, directly  by attaching a monitor to the RaspberryPi Zero, using RaspberryPi Connect and/or using a phone app. 

### Use RaspberryPi Connect

**Option A: Connect a monitor to the RPi Zero 2**
- This is the simplest approach for initial bench testing and debugging.

**Option B: Raspberry Pi Connect (remote access)**
- Raspberry Pi Connect provides a remote way to access the Pi without physically attaching a display:
https://www.raspberrypi.com/software/connect/

### Use the WhalePi phone app

The WhalePi phone app is intended for field convenience: checking system status, viewing detections/summary information, and issuing start/stop/status actions without a laptop.

Go to the **Releases** section of this repository to find app availability and installation notes (if published alongside the WhalePi release package).

> Note: Bluetooth setup (BLE / legacy serial) is described in `install.md`. Ensure Bluetooth is configured before relying on the phone app.

---

## Where outputs are stored (general guidance)

Exact output paths depend on your PAMGuard configuration, but in general you should expect:
- **Raw audio** (if enabled): stored on the Pi’s configured storage location
- **Detector outputs** (e.g. clicks): stored as PAMGuard data products (often much smaller than raw audio)
- **Logs / status**: produced by the watchdog and/or PAMGuard

If you change the PAMGuard configuration, confirm output directories and available disk space before deployment.

---

## Deployment checklist (quick)

Before leaving the bench:
- Confirm audio input is working (hydrophone + COSMOS DAQ)
- Confirm correct sample rate and channel count
- Confirm outputs are being written where you expect
- Confirm time sync (and GPS if used)
- Confirm power budget and storage budget for the planned duration
- Confirm remote access method (monitor, Raspberry Pi Connect, and/or phone app)
- If using sensors (depth/temp), confirm I2C is enabled and sensors are logging

---

## Development

This repository focuses on installation and setup for WhalePi on the Raspberry Pi.

If you are contributing:
- Keep changes small and testable
- Update docs alongside any changes to install/run scripts
- Document hardware assumptions (Pi model, DAQ version, sensors)
