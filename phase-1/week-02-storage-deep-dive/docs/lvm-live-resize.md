# LVM Live Resize — Adding Capacity Without Downtime

## Starting State

VG "cs" — 31GB total, 0GB free (fully allocated)
LV root — 27.79GB
LV swap — 3.20GB

System: phase1-vm-1, RHEL/CentOS Stream 9

## Why This Matters

Most production VGs are fully allocated when first
provisioned. Adding capacity requires adding a new
physical disk to the VG rather than resizing existing
disks — this avoids downtime and data risk.

## Procedure

### Step 1 — Add new virtual disk in Proxmox
Added a 10GB disk (sdb) to the VM via Proxmox
Hardware tab while the VM remained running.

### Step 2 — Create a partition and Physical Volume
```bash
fdisk /dev/sdb          # created sdb1 (5GB)
pvcreate /dev/sdb1
```

Note: Only partitioned 5GB of the available 10GB.
Remaining 5GB on /dev/sdb left unpartitioned for
future use.

### Step 3 — Extend the existing Volume Group
```bash
vgextend cs /dev/sdb1
```

Result:
- VG "cs" grew from 31.00g → 35.99g
- VG now spans 2 PVs: /dev/sda2 and /dev/sdb1

### Step 4 — Extend the LV and filesystem live
```bash
lvextend -r -L +4G /dev/cs/root
```

The `-r` flag automatically resized the XFS
filesystem immediately after extending the LV —
no separate xfs_growfs command needed, no
unmount, no downtime.

Result:
- LV root grew from 27.79g → 31.79g
- Filesystem grew to match (confirmed with df -hT /)
- Root filesystem now physically spans two disks:
  sda2 (original) and sdb1 (newly added)

## Verification

```bash
lvs    # confirmed LV size
vgs    # confirmed VG free space consumed
pvs    # confirmed both PVs in the VG
lsblk  # confirmed cs-root spans sda2 + sdb1
df -hT /  # confirmed filesystem size matches LV size
```

## Key Lesson — XFS Cannot Shrink

This filesystem is XFS. XFS can be grown live
(as demonstrated above) but can NEVER be shrunk —
not live, not even when unmounted. This is a
fundamental design limitation of XFS, not a
missing feature.

If this LV needs to be smaller in the future the
only options are:
1. Create a new smaller LV
2. Copy data to the new LV
3. Remount and switch over
4. Delete the old LV

ext4 filesystems CAN be shrunk, but only while
unmounted, and the filesystem must be shrunk
BEFORE the LV is reduced (opposite order from growing).

## Commands Reference

| Command | Purpose |
|---|---|
| pvcreate | Initialize a disk/partition for LVM use |
| vgextend | Add a PV's space into an existing VG |
| lvextend -r | Grow an LV and its filesystem in one step |
| vgs / lvs / pvs | Check VG/LV/PV status |
| df -hT | Verify actual filesystem size |
