# Install whalepi

## Introduction

This guide takes you through how to install WhalePi on a Raspberry Pi Zero

## Install Raspberry Pi OS

Install Raspberry Pi OS Lite. The easiest way to do this is using Raspberry Pi Imager on another Raspberry Pi device. Note we do NOT want a desktop environment on here so make sure you install the Lite version of Raspberry Pi OS. Set the user to ```whalepi``` and ensure you have a password set. When asked about the ssh address, select a unique name for the raspberry pi zero. e.g. whalepi_13. This means we can ssh to multipe devices later. Here we have used ``whalepi`` as the unique address. 

## Log in via SSH

Use terminal to log in via SSH. Note your computer must be connected to the same WiFi network as the Pi Zero for this to work. 

```bash
ssh whalepi@whalepi.local
```
When prompted enter the password. You are now connected to the Raspberry Pi Zero
Note that, if you have been using previous versions of 

## Install pre-requisites 

### Java 21
Install Java 21 

```bash
sudo apt update
sudo apt install openjdk-21-jdk
```

### Enable Bluetooth serial
We need to enable Bluetooth. 

### Trasnfer the install package



