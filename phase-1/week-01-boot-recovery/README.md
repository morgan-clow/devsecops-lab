# Week 1 — Boot Process & Recovery

## Overview

This week covers the Linux boot process and recovery procedures.
The goal is to confidently troubleshoot and recover systems that
fail to boot. Every lab in this folder was performed on a CentOS Stream 9
VM running in a Proxmox homelab environment.

---

## The Linux Boot Sequence

| Stage | Component | What It Does |
|---|---|---|
| 1 | BIOS/UEFI | POST hardware check, finds bootloader |
| 2 | GRUB | Loads kernel, presents boot menu |
| 3 | initramfs | Temporary filesystem, mounts real root |
| 4 | Kernel | Initializes hardware, starts PID 1 |
| 5 | systemd | Starts services, presents login prompt |

---

## BIOS vs UEFI

**BIOS** (Basic Input/Output System) is older firmware that does not 
support disks larger than 2TB and boots slower.

**UEFI** (Unified Extensible Firmware Interface) is modern firmware 
that supports large disks, boots faster, and includes Secure Boot 
which prevents unauthorized bootloaders from running.

---

## What initramfs Does

Initial RAM filesystem detects and initializes storage hardware,
find the real root filesystem, then it mounts the real root filesystem.
After, it hands control over to the real system, then it disappears.

---

## Why This Matters Operationally

Boot recovery matters because we all will eventually face a system that
will not boot. It is important that we have the skills to recover 
a system without major data lost if at all possible.

---

## Labs Completed This Week

- [ ] Lab 1: Break /etc/fstab and recover using rescue mode
- [ ] Lab 2: Reset root password using rd.break
- [ ] Lab 3: Corrupt GRUB configuration and rebuild
- [ ] Lab 4: Full failed boot simulation and recovery

---

## Key Commands Reference

| Command | Purpose |
|---|---|
| `grub2-mkconfig -o /boot/grub2/grub.cfg` | Rebuild GRUB config |
| `grubby --default-kernel` | Show default kernel |
| `systemctl list-units --state=failed` | Check failed services |
| `journalctl -xb` | View boot logs |
| `lsblk` | List block devices |
| `blkid` | Show UUIDs of all devices |
