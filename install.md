
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


> [!NOTE]
> The RaspberryPi Zero must be connected to the internet for the rest of the install process. 📶

## 💻 Log in via SSH or Raspberry Pi Connect

### SSH 

> [!NOTE]
> Your computer must be connected to the **same WiFi network** as the Pi Zero for this to work. 📶

Use your terminal to log in via SSH

```bash
ssh whalepi@whalepi.local

```

When prompted, enter your password. You are now connected to the Raspberry Pi Zero! 🎉

Note if you have re-nstalled the OS you may get a scary looking error about a encryption and middle man attack. Just ignore this and run

```bash
ssh-keygen -f '/home/jdjm/.ssh/known_hosts' -R 'whalepi.local'
```

### Raspberry Pi Connect

If Raspberry Pi connect was set up during installing RaspberryPi OS then it's easy to connect from any internat connected PC via the [Raspberry Pi Connect website](https://www.raspberrypi.com/software/connect/). 

---

## ⚙️ Install Pre-requisites

### 🚚 Transfer & Install Package

Follow these steps to move the PAMGuard installation to your Pi Zero and get the watchdog running.

### Transfer the Files

The easiest way to transfer the firmware is to download it from github and then unzip 

```bash
cd /home/whalepi/
wget https://github.com/WhalePi/install_whalepi/releases/download/v0.9.0/pamguard_pizero.zip
```

> [!TIP]
> From your _local machine_, it is also possible to use `rsync` to securely move the zip folder to the Pi Zero:
>```bash
>rsync -avz --progress /home/whalepi/pamguard_pizero.zip whalepi@whalepi.local:/home/whalepi/pamguard_pizero.zip
>```

### Extract and Enter

Once the transfer is complete, unzip the package and move into the directory:

```bash
unzip pamguard_pizero.zip
cd pamguard_pizero
```

### Set up the recording folder and database

We need a recording folder and directory in the user root direct. 

Create a folder via 
```bash
mkdir /home/whalepi/PAMRecordings
```
Install sqlite 3 dependencies and create a blank database file

```bash
sudo apt update
sudo apt install sqlite3
sqlite3 /home/whalepi/whalepi_database.sqlite3 "VACUUM;"
```

### ☕ Java 21

WhalePi requires Java 21 to run. Install it using the following commands:

```bash
sudo apt update
sudo apt install openjdk-21-jdk

```

### 🐍 Python Dependencies

Install the required Python packages - these are needed if using the more advanced low power bluetooth feature in the watchdog.

```bash
# Install system dependencies
sudo apt-get update
sudo apt-get install python3-dbus python3-gi
sudo apt install python3-pip -y
```

### 🔹 Enable Bluetooth Serial

#### Bluetooth BL

WhalePi uses the latest low power bluetooth by default. This requires several dependencies that can be installed by running a script in the utils folder. Navigate to the `utils` folder within the install package and run the install script via 

```
sudo ./ble_install.sh
```
This should handle everything that is needed. 

#### Bluetooth Serial (Legacy)

Optional - we need to enable the Bluetooth stack for serial communication to use the legacy Bluetooth Serial comms which is an option for the WatchDog.  📱

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


### 🐚 Install tmux
tmux is needed so we can define a session in terminal which we can then come back , for example when using ssh to communicate with the PI zero. Install tmux via

```bash
sudo apt update
sudo apt install tmux
```
The tmux script also checks the `whalepidog_settings.json` file to check if daemon is set to true and therefore needs `jq` installed via

```bash
sudo apt install jq
```

> [!NOTE]
> If you do not install jq, then an error will show saying the daemon was not set to true - this is because the whalepidog_settings.json file cannot be read and returns null for all fields


### 🎙️ Set microphone volume to zero (IMPORTANT)

The COSMOS card has a strange issue where, if the microphone volume is set to anything other than zero, then there is cross talk. Disable the microphone by setting

```bash
 amixer -c 1 set Line 0
```

### 🔗 Enable I2C

I2C communication is needed for the depth sensors. Run

```bash
sudo raspi-config
```
Navigate to Interface Options. Select I2C and choose Yes to enable it. Finish and reboot the Pi.

---


## Start the Watchdog

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
*  `copydata` - checks whether a volume is present and copies the data from the PAMRecordings folder and database file to the root directory of the colume. 


For a full list of commands see [here](https://github.com/PAMGuard/PAMGuard/wiki/UDP-Commands);

> [!TIP]
> To "detach" from the session without stopping PAMGuard, press `Ctrl+B` followed by `D`.



