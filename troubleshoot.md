## Troubleshooting

Sometimes things go wrong with WhalePI. Here are some tips and tricks for troubleshooting. 

## Checking the COSMOS soundcard is working

There is a handy utility in the `pamguard_pizero/utils` folder called soundcheck. 

Yopu can start soundcheck by navigating to the utils folder `cd /home/whalepi/pamguard_pizero/utils` and running

```bash
./soundcheck.sh
```
Check the COSMOS card is working by tapping hydrophones and checking the level meters show something happening. 

```bash
  +============================================================+
  |              SOUND CHECK - Audio Level Meter               |
  +============================================================+

  Device: PCM32768 [plughw:0,0]
  Channels: 2 (Stereo)

  +-- Ch L ----------------------------------------------------------+
  | [LOW ] [░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░|░░] |
  |       -60       -40       -20      -10    -6  -3  0  dB        |
  |       RMS:   -60.0 dB    Peak:   -50.1 dB                      |
  +------------------------------------------------------------------+
  +-- Ch R ----------------------------------------------------------+
  | [ OK ] [██████████████████████░░░░░░░░░░░░░░░░░|░░░░░░░░░░] |
  |       -60       -40       -20      -10    -6  -3  0  dB        |
  |       RMS:   -32.6 dB    Peak:   -13.1 dB                      |
  +------------------------------------------------------------------+

  Tap your microphone to test levels
```


## Check a serial GPS is attached 

Use `dmesg` to list adapters

```bash
 dmesg | grep tty
```

 Without a GPS this will return something like 

 ```bash
[    0.000000] Kernel command line: coherent_pool=1M 8250.nr_uarts=1 snd_bcm2835.enable_headphones=0 cgroup_disable=memory snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_hdmi=0  smsc95xx.macaddr=B8:27:EB:EC:7F:F8 vc_mem.mem_base=0x1ec00000 vc_mem.mem_size=0x20000000  console=ttyS0,115200 console=tty1 root=PARTUUID=0012c651-02 rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=GB
[    0.000271] printk: legacy console [tty1] enabled
[    2.215335] 3f201000.serial: ttyAMA1 at MMIO 0x3f201000 (irq = 99, base_baud = 0) is a PL011 rev2
[    2.217690] serial serial0: tty port ttyAMA1 registered
[    2.221843] printk: legacy console [ttyS0] disabled
[    2.223383] 3f215040.serial: ttyS0 at MMIO 0x3f215040 (irq = 71, base_baud = 50000000) is a 16550
[    2.225767] printk: legacy console [ttyS0] enabled
[   10.656583] systemd[1]: Created slice system-getty.slice - Slice /system/getty.
[   10.697865] systemd[1]: Created slice system-serial\x2dgetty.slice - Slice /system/serial-getty.
[   10.823286] systemd[1]: Expecting device dev-ttyS0.device - /dev/ttyS0...
```

With a GPS attached then the last few lines should look like.

```bash
[  897.215445] cdc_acm 1-1.1:1.0: ttyACM0: USB ACM device
[  946.428610] usb 1-1.1: pl2303 converter now attached to ttyUSB0
```

Specifically your are looking for something like 

- ttyUSB0 or ttyUSB1 (Standard USB adapters) <-Serial GPS is usually this
- ttyACM0 (Arduinos or cellular modems)
- ttyS0 or ttyAMA0 (Onboard GPIO UART)
