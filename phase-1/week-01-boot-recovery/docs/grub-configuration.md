📄 grub-configuration.md — ADD THIS SECTION:

## Lab 3 — GRUB Recovery

### What I broke
- Renamed grub.cfg to simulate corruption

### What I saw
- grub> prompt appeared on reboot
- No boot menu — GRUB couldn't find config

### Recovery process
- Used ls to find boot partition (hd0,msdos1)
- Identified kernel and initramfs files
- Attempted manual boot — hit out of memory error
- Restored snapshot and regenerated grub.cfg

### Commands used
- ls — find partitions
- set root= — set boot partition
- linux — load kernel
- initrd — load initramfs
- boot — attempt boot
- grub2-mkconfig — regenerate config

### Key lesson
GRUB out of memory errors in VMs often mean
the VM needs more RAM allocated or boot from
rescue ISO instead
