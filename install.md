
# 🐳 Install WhalePi

## 📝 Introduction

This guide takes you through how to install **WhalePi** on a Raspberry Pi Zero.

---

## 💾 Install Raspberry Pi OS

1. **Install Raspberry Pi OS Lite:** The easiest way to do this is using **Raspberry Pi Imager** on another device.
2. ⚠️ **Important:** We do **NOT** want a desktop environment, so ensure you select the **Lite** version.
3. 👤 **User Setup:** Set the username to `whalepi` and ensure you have a password set.
4. 🌐 **Hostname:** When asked about the SSH address, select a unique name (e.g., `whalepi_13`). This allows us to SSH to multiple devices later. In this guide, we use `whalepi` as the unique address.

---

## 💻 Log in via SSH

Use your terminal to log in via SSH.

> [!NOTE]
> Your computer must be connected to the **same WiFi network** as the Pi Zero for this to work. 📶

```bash
ssh whalepi@whalepi.local

```

When prompted, enter your password. You are now connected to the Raspberry Pi Zero! 🎉

Note if you have re-nstalled the OS you may get a scary looking error about a encryption and middle man attack. Just ignore this and run

```bash
ssh-keygen -f '/home/jdjm/.ssh/known_hosts' -R 'whalepi.local'
```

---

## ⚙️ Install Pre-requisites

### ☕ Java 21

WhalePi requires Java 21 to run. Install it using the following commands:

```bash
sudo apt update
sudo apt install openjdk-21-jdk

```

### 🔹 Enable Bluetooth Serial

We need to enable the Bluetooth stack for serial communication. 📱

By default, the Bluetooth stack on the Pi does not enable the Serial Port Profile. We need to modify the Bluetooth service configuration to run in "compatibility mode." Enable Compatibility Mode

Open the Bluetooth service file:

```bash
sudo nano /etc/systemd/system/dbus-org.bluez.service
```
Find the line starting with ExecStart=/usr/lib/bluetooth/bluetoothd.

Add a ```-C``` (compatibility flag) at the end of that line.

On the line immediately below it, add ```ExecStartPost=/usr/bin/sdptool add SP```.

It should look like this: 

```
    ExecStart=/usr/lib/bluetooth/bluetoothd -C
    ExecStartPost=/usr/bin/sdptool add SP
```

Save and exit (Ctrl+O, Enter, Ctrl+X).

Restart Bluetooth Services

Apply the changes by reloading the daemon:

```bash
sudo systemctl daemon-reload
sudo systemctl restart bluetooth
```

It sounds like you're setting up some serious bioacoustics gear! Here is a cleaner, more professional version of those instructions to help you (or anyone else) follow the deployment process without any friction.

---

## 🚚 Transfer & Install Package

Follow these steps to move the PAMGuard installation to your Pi Zero and get the watchdog running.

### 1. Transfer the Files

From your local machine, use `rsync` to securely move the zip folder to the Pi Zero:

```bash
rsync -avz --progress /home/whalepi/pamguard_pizero whalepi@whalepi.local:/home/whalepi/
```

### 2. Extract and Enter

Once the transfer is complete, unzip the package and move into the directory:

```bash
unzip pamguard_pizero.zip
cd pamguard_pizero

```

### 3. Start the Watchdog

To ensure things are running smoothly, launch the watchdog script. This initializes a new **tmux** session, allowing the process to persist even if you disconnect from SSH.

```bash
./pamdog_pizero_tmux.sh

```

---

## 🛠 Managing the Session

Since PAMGuard is running inside `tmux`, you can log out of the Pi at any time without killing the process.

* **To Re-attach:** Use this command to see the current status:
```bash
tmux attach -t pamguard
```

* **Control Commands:** Once inside the session, you can manage PAMGuard using:
* `start` – Begins audio processing.
* `stop` – Pauses/Ends audio processing.
* `summary` – Displays current stats.
* `status` - checks whether pamgaurd is runnning (1) or not (0).

For a full list of commands see [here](https://github.com/PAMGuard/PAMGuard/wiki/UDP-Commands);

> [!TIP]
> To "detach" from the session without stopping PAMGuard, press `Ctrl+B` followed by `D`.



