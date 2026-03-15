# WhalePi

##
Welcome to WhalePi, a flexible passive acoustic recording and real-time analysis system based on a Raspberry Pi Zero and [PAMGuard](www.pamguard.org). The aim of WhalePi is to create a flexible medium-power recording system for cetaceans. Cetaceans cover over eight octaves, from the 100Hz calls of Blue Whales to the 130,000 Hz clicks of Kogia and porpoises, with some broadband click components going even higher in frequency. This means any recording system to cover all species needs to have both a high dynamic range (i.e., 24-bit), a high sample rate (i.e. 384,000 kS/s), and ideally multiple channels. WhalePi provides a solution to create such a system by running PAMGuard software on low-cost hardware, particularly a COSMOS DAQ card and Raspberry Pi Zero 2 W. 

PAMGuard is a highly flexible modular programme enabling users to create an acoustic workflow for real-time analysis.  It also integrates with various hardware like sound cards and GPS. WhalePi facilitates setting up a PAMGuard configuration and running it on a Raspberry Pi.  While most modern Raspberry Pi boards work, WhalePi is optimised for the Raspberry Pi Zero 2 W, which has medium power consumption. This allows for autonomous deployment for days or weeks on a large 12V battery or solar panels.  The Raspberry Pi supports up to 1TB of storage for recordings or detection. For instance, the system could save only PAMGuard’s automated click detector output, effectively unlimited storage.  

The COSMOS sound card connects to the Raspberry Pi and drivers have been developed to run it efficiently through PAMGuard.  This allows for 24-bit recordings with high dynamic range.  The sound card can manage stereo channels at a 384 kHz sample rate per channel covering all cetacean species provided a hydrophone with a suitable frequency response is used.  GPS and analogue sensors for depth and temperature can also be integrated. 

WhalePi  does not come with plans for an  housing but the COSMOS sound card and Raspberry Pi are relatively compact.  They can be mounted inside a small Peli Case or underwater housing like those made by BlueRobotics().  This potentially allows you to create an advanced PAM system for under $500. While WhalePi won’t replace devices like SoundTraps or CPODs it’s useful for situations where flexibility cost and/or real-time communication are important. 


Installing WhalePi

First set up the raspberry pi with all the required libraries and programs by following the instructions here install.md

Download the latest release and transfer it to a user directory called “whalepi” e.g. /home/whalepi/. Unzip inside this folder - this should mean there is a folder called /home/whalepi/pamguard_pizero. Got start WhalePi use the script type `./whalepidog_pizero.sh`. 

Viewing data

There are three ways to view data, directly  by attaching a monitor to the RaspberryPi Zero, using RaspberryPi Connect and/or using a phone app. 

Use RaspberryPi Connect

Connect a monitor to the RPi Zero 2

https://www.raspberrypi.com/software/connect/

Use the WhalePi phone app

Go to the 

Development
