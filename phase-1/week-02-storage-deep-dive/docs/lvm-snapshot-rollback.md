# LVM Snapshot — Create, Disaster, Rollback

## Concept

An LVM snapshot uses Copy-on-Write (CoW) — it does
NOT copy all data upfront. It only stores the
"before" version of blocks that change after the
snapshot is taken. This makes snapshot creation
nearly instant.

## Critical Rule: Timing Matters

A snapshot only protects data that existed AT THE
MOMENT it was created. Anything created or deleted
AFTER the snapshot is unaffected by a rollback to
that snapshot — rolling back simply restores the
exact state from snapshot creation time, nothing more.

### First Attempt — Wrong Order (Documented Mistake)

Initially created the snapshot, then created and
deleted a test file (important_data), then rolled
back expecting the file to reappear. It did not —
because the file never existed when the snapshot
was taken. This proved the timing rule the hard way.

### Second Attempt — Correct Order

```bash
# Step 1 - Create the file BEFORE the snapshot
echo "Important data that must survive" > /root/critical_file.txt

# Step 2 - Take the snapshot (file now captured inside it)
lvcreate -L 800M -s -n root_snapshot2 /dev/cs/root

# Step 3 - Simulate disaster
rm -f /root/critical_file.txt
# Confirmed deleted: ls returns "No such file or directory"

# Step 4 - Roll back
lvconvert --merge /dev/cs/root_snapshot2
reboot
```

## Why Reboot Is Required for Root

The root filesystem cannot be unmounted while the
system is running on it. LVM detects this and
SCHEDULES the merge instead of executing it
immediately. The merge completes automatically
during the next boot, before root is mounted
normally.

Confirmed by checking `lvs` before reboot — root
showed attribute `Owi-aos---` (capital O = merge
pending) with the snapshot still listed (#SN = 1).

## Result After Reboot

```bash
cat /root/critical_file.txt
# Important data that must survive

lvs
# Snapshot is gone — auto-removed after successful merge
# root back to clean -wi-ao---- attribute
```

File fully restored with original content. Snapshot
automatically cleaned up after merge completed.

## Key Lessons

1. Snapshots use Copy-on-Write — fast to create,
   only grow as the origin volume changes
2. A snapshot is a point-in-time picture — it cannot
   protect data created or deleted after it was taken
3. Root filesystem snapshot merges require a reboot
   to complete (cannot unmount root while running on it)
4. Always verify the ORDER of operations: create data
   → snapshot → disaster → rollback, not the reverse

## Commands Reference

| Command | Purpose |
|---|---|
| lvcreate -L <size> -s -n <name> <origin> | Create a snapshot |
| lvs | Check snapshot status and Data% used |
| lvconvert --merge <snapshot> | Roll back origin to snapshot state |
| vgs | Check VG free space (snapshot consumes this) |
