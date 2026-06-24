# Week 2 — Storage Deep Dive

## Overview

This week covers Linux storage fundamentals beyond
basic LVM creation — focusing on live operations,
failure recovery, and the production-level details
that separate exam knowledge from operational skill.
All labs performed on phase1-vm-1 (CentOS Stream 9)
in a Proxmox homelab.

---

## Core Concepts

### PV / VG / LV Relationship

- **PV (Physical Volume)** — a disk or partition with
  LVM metadata written to it, making it "LVM aware"
- **VG (Volume Group)** — a storage pool made of one
  or more PVs; a single VG can span multiple physical
  disks, which is how you grow storage beyond the size
  of any single disk
- **LV (Logical Volume)** — a flexible, resizable
  volume carved out of a VG; its physical data can be
  spread across multiple disks in that VG transparently

### XFS Cannot Shrink

XFS filesystems can be grown live, but can **never**
be shrunk — not live, not even offline. This is a
fundamental design limitation, not a missing feature.
ext4 can be shrunk, but only while unmounted, and the
filesystem must be shrunk *before* the LV is reduced
(opposite order from growing).

### LVM Snapshots Use Copy-on-Write

A snapshot does not copy all data upfront. It only
stores the "before" version of blocks that change
after the snapshot is taken — making creation nearly
instant. A snapshot only protects data that existed
at the moment it was created; anything created or
deleted afterward is unaffected by a rollback.

---

## Labs Completed

- [x] Add a new virtual disk in Proxmox and extend an
      existing VG (rather than create a separate VG)
- [x] Live-extend an LV and its XFS filesystem with
      zero downtime using `lvextend -r`
- [x] Fill the root filesystem to ~93% and diagnose +
      recover from a disk-full condition
- [x] Create an LVM snapshot, simulate data loss, and
      roll back to recover the original data

---

## Deliverables

- [lvm-live-resize.md](https://github.com/morgan-clow/devsecops-lab/blob/main/phase-1/week-02-storage-deep-dive/docs/lvm-live-resize.md)
- [disk-full-incident.md](https://github.com/morgan-clow/devsecops-lab/blob/main/phase-1/week-02-storage-deep-dive/docs/disk-full-incident.md)
- [lvm-snapshot-rollback.md](https://github.com/morgan-clow/devsecops-lab/blob/main/phase-1/week-02-storage-deep-dive/docs/lvm-snapshot-rollback.md)
- [screenshots/](https://github.com/morgan-clow/devsecops-lab/tree/main/phase-1/week-02-storage-deep-dive/screenshots)

---

## Key Commands Reference

| Command | Purpose |
|---|---|
| `pvcreate` | Initialize a disk/partition for LVM |
| `vgextend` | Add a PV's space into an existing VG |
| `lvextend -r -L +<size>` | Grow an LV and its filesystem in one step |
| `du -sh /path/* \| sort -rh` | Find largest space consumers |
| `find /path -size +1G` | Locate large files |
| `lsof +L1` | Find deleted-but-open files holding disk space |
| `lvcreate -L <size> -s -n <name> <origin>` | Create a snapshot |
| `lvconvert --merge <snapshot>` | Roll back to snapshot state |
| `vgs` / `lvs` / `pvs` | Check VG/LV/PV status |

---

## Real-World Incidents Simulated

1. **Adding capacity without downtime** — extended an
   existing fully-allocated VG with a new disk and grew
   root live, zero service interruption
2. **Disk-full cascade** — demonstrated why a full /var
   can cascade into logging failures, package manager
   failures, and even SSH access issues; diagnosed and
   recovered using `du`/`find`/`lsof`
3. **Point-in-time recovery** — used an LVM snapshot to
   recover a deleted file, including documenting a
   first attempt that failed due to incorrect operation
   order (snapshot taken before the file existed)
