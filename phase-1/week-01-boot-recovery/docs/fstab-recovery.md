# /etc/fstab Recovery Procedure

## What is /etc/fstab
Permanently defines filesystem mount points.
Read by systemd at boot. Errors cause boot failure.

## What a broken fstab looks like
- System hangs with message:
  "A start job is running for /dev/disk/by-uuid/..."
- Eventually drops into emergency mode
- Message: "You are in emergency mode"

## How to prevent fstab errors
- Always backup before editing:
  cp /etc/fstab /etc/fstab.backup
- Never type UUIDs manually — use blkid to find them
- Test mounts before rebooting:
  mount -a

## Recovery Procedure

### Step 1 — Enter emergency mode
- Wait for system to time out
- Enter root password when prompted

### Step 2 — Fix the fstab
Option A — Restore from backup:
  cp /etc/fstab.backup /etc/fstab

Option B — Fix manually:
  vi /etc/fstab
  Correct the wrong UUID or mount point

### Step 3 — Find correct UUID if needed
  blkid
  Copy the correct UUID for your device

### Step 4 — Verify fix
  cat /etc/fstab
  Confirm correct UUIDs and mount points

### Step 5 — Reboot
  systemctl reboot

## Key Commands
| Command | Purpose |
|---|---|
| blkid | Show UUID of all devices |
| mount -a | Test all fstab mounts without rebooting |
| cat /etc/fstab | View current fstab |
| cp /etc/fstab /etc/fstab.backup | Backup fstab |
