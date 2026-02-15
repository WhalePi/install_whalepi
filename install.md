
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

### 🚚 Transfer the Install Package

Grab the zip folder and transfer it the pizero via

rsync -avz --progress /home/jdjm/Desktop/pamguard_pizero.zip jdjm@whalepi.local:/home/whalepi/

Then unzip the file via

Enter the folder using
cd pamguard_pizero

To test things are working start the watchdog. 

./pamdog_pizero_tmux

This starts the watchdog ina  new tmux session which means we can log out of the pi and back in again and still see what's going on with PAMGuard. To access the session simply use

tmux attach -t pamguard

You should see the typical window for pamgaurd. Use commands such as start, stop and summary to control PAMGuard. See more here. 





---

