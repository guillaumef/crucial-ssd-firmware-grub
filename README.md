# crucial-ssd-firmware-grub


‘crucial-fw.pl’ is a little script to generate a single grub config for any crucial ssd firmware upgrade.
It’s a perl script.

You need:
```
 LWP::UserAgent
 File::Copy
 Archive::Extract (debian like: apt-get install libarchive-extract-perl)
 Archive::Zip (debian like: apt-get install libarchive-zip-perl)
```

‘crucial-fw.pl’ generates a file for grub (default is /etc/grub.d/45_crucial-fw).
Depending on the iso file, it will switch between two loading mode and grab the isolinux.cfg if needed.
This configuration is creating a submenu entry for grub containing one menu entry for each ssd reference specified in the configuration.

Your linux kernel must be able to mount a loopback iso file (loop and isofs modules). Any vanilla kernel is.

You have to maintain the .cfg file up-to-date.

```
 crucial-fw.pl <options>
   Options:
     -h | --help  : usage
     -a | --all   : generate all grub menu entries
                    (default behavior is to scan for SSD types)
     -t | --type  : specific ssds type to generate (multiple allowed)
     -l | --list  : list ssds type managed
```

Default behavior is to try to detect the kind of ssd running on the current host.
You can generate all of them with the '-a' option.

```
# ./crucial-fw.pl -a
Target: BX100 #1 (BX100_UPDATE_MU02_BOOTABLE.zip, BX100_UPDATE_MU02_BOOTABLE.iso)
  Downloading.. done
  Uncompressing.. BX100_UPDATE_MU02_BOOTABLE.iso done
  Moving to BX100-1.iso done
  Mounting done
  Grub -> mode initrd done
  Unmounting done
Target: BX200 #1 (BX200_UPDATE_MU02_BOOTABLE.zip, BX200_UPDATE_MU02_BOOTABLE.iso)
  Downloading.. done
  Uncompressing.. BX200_UPDATE_MU02_BOOTABLE.iso done
  Moving to BX200-1.iso done
  Mounting done
  Grub -> mode initrd done
  Unmounting done
Target: C300 #1 (c300-fw0002.zip, c300-fw0002.iso)
  Downloading.. done
  Uncompressing.. c300-fw0002.iso done
  Moving to C300-1.iso done
  Mounting done
  Grub -> mode linux16 done
 done
  Unmounting done
Target: C300 #2 (bootisolinux-0002-to-0006.zip, bootisolinux-0002-to-0006.iso)
  Downloading.. done
  Uncompressing.. bootisolinux-0002-to-0006.iso done
  Moving to C300-2.iso done
  Mounting done
  Grub -> mode linux16 done
 done
  Unmounting done
Target: C300 #3 (hp-crucial-5or6-to-7-05.zip, hp-crucial-5or6-to-7-05.iso)
  Downloading.. done
  Uncompressing.. hp-crucial-5or6-to-7-05.iso done
  Moving to C300-3.iso done
  Mounting done
  Grub -> mode linux16 done
 done
  Unmounting done
Target: M4 #1 (crucial-m4-070h-07-00.zip, crucial-m4-070h-07-00.iso)
  Downloading.. done
  Uncompressing.. crucial-m4-070h-07-00.iso done
  Moving to M4-1.iso done
  Mounting done
  Grub -> mode linux16 done
 done
  Unmounting done
Target: M500 #1 (crucial-m500.mu05-01-S0-tcg.zip, crucial-m500.mu05-01-S0-tcg.iso)
  Downloading.. done
  Uncompressing.. crucial-m500.mu05-01-S0-tcg.iso done
  Moving to M500-1.iso done
  Mounting done
  Grub -> mode linux16 done
 done
  Unmounting done
Target: M550 #1 (m550-sed-update-mu02-bootable.zip, m550-sed-update-mu02-bootable.iso)
  Downloading.. done
  Uncompressing.. M550_SED_UPDATE_MU02_BOOTABLE.iso done
  Moving to M550-1.iso done
  Mounting done
  Grub -> mode initrd done
  Unmounting done
Target: MX100 #1 (MX100_MU03_Update.zip, MX100_MU03_Update.iso)
  Downloading.. done
  Uncompressing.. MX100_MU03_Update.iso done
  Moving to MX100-1.iso done
  Mounting done
  Grub -> mode initrd done
  Unmounting done
Target: MX100old #1 (MX100_MU02_BOOTABLE_ALL_CAP.zip, MX100_MU02_BOOTABLE_ALL_CAP.iso)
  Downloading.. done
  Uncompressing.. MX100_MU02_BOOTABLE_ALL_CAP.iso done
  Moving to MX100old-1.iso done
  Mounting done
  Grub -> mode initrd done
  Unmounting done
Target: MX200 #1 (mx200-MU05-bootable.zip, mx200-MU05-bootable.iso)
  Downloading.. done
  Uncompressing.. MX200_MU05_Update.iso done
  Moving to MX200-1.iso done
  Mounting done
  Grub -> mode initrd done
  Unmounting done
Target: MX200old1 #1 (mx200-MU04-bootable.zip, mx200-MU04-bootable.iso)
  Downloading.. done
  Uncompressing.. mx200_revMU04_bootable_media_update.iso done
  Moving to MX200old1-1.iso done
  Mounting done
  Grub -> mode initrd done
  Unmounting done
Target: MX200old2 #1 (mx200-MU03-bootable.zip, mx200-MU03-bootable.iso)
  Downloading.. done
  Uncompressing.. MX200_MU03_BOOTABLE.iso done
  Moving to MX200old2-1.iso done
  Mounting done
  Grub -> mode initrd done
  Unmounting done
Target: MX300 #1 (MX300_M0CR070_Firmware_Update.zip, MX300_M0CR070_Firmware_Update.iso)
  Downloading.. done
  Uncompressing.. MX300_M0CR070_Firmware_Update.iso done
  Moving to MX300-1.iso done
  Mounting done
  Grub -> mode initrd done
  Unmounting done
Target: MX500 #1 (MX500_M3CR023_update.zip, MX500_M3CR023_update.iso)
  Downloading.. done
  Uncompressing.. MX500_M3CR023_update.iso done
  Moving to MX500-1.iso done
  Mounting done
  Grub -> mode initrd done
  Unmounting done

Generated in: /etc/grub.d/45_crucial-fw
      ISO in: /boot/crucial-fw
```
