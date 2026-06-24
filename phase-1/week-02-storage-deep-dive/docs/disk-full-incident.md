# Disk-Full Incident — Detection and Recovery

## Why /var Filling Up Is Especially Dangerous

/var contains logs, application data, mail/print
queues, package manager cache, and persistent temp
files. When /var fills up:

- Logging stops (rsyslog/journald can't write)
  → losing visibility exactly when it's needed most
- Package manager (dnf/rpm) breaks
- Database/application writes fail
- In severe cases SSH session tracking can fail,
  risking lockout from the very system you need
  to fix

This creates a cascading failure: disk full → 
logging stops → you can't see why things are
breaking → tools you need to fix it start failing too.

## Incident Simulation

Filled root filesystem (which holds /var on this
system — no separate /var mount) using:

```bash
dd if=/dev/zero of=/var/fill_file bs=1M count=28000
```

Result: disk usage went from 7% to 93%.

## Diagnostic Procedure

### Step 1 — Confirm scope across all filesystems
```bash
df -hT
```

### Step 2 — Identify what's consuming space
```bash
du -sh /var/* 2>/dev/null | sort -rh | head -10
```
Immediately identified `/var/fill_file` at 28G as
the cause.

### Step 3 — Search for any large files system-wide
```bash
find /var -type f -size +1G -exec ls -lh {} \;
```
Confirmed the file and its exact size/owner/timestamp.

### Step 4 — Check for "phantom" disk usage
```bash
lsof +L1
```
Finds files that were deleted but are still held open
by a running process — disk space won't be freed until
the process releases the file handle. This tool was
NOT installed by default; installed with:
```bash
dnf install lsof -y
```
Lesson: diagnostic tools should be pre-installed
before an incident, not during one.

## Recovery

```bash
rm -f /var/fill_file
df -hT /
```
Disk usage returned to 7% immediately — confirming
the recovery and validating the root cause.

## Key Lessons

1. /var filling up can cascade into logging failures,
   package manager failures, and even SSH lockout
2. `du -sh /var/* | sort -rh` is the fastest way to
   locate large consumers
3. Deleted-but-still-open files won't free space
   until the holding process is restarted or the
   file is truncated — `lsof +L1` finds these
4. Pre-install diagnostic tools (lsof, etc.) before
   you need them in an emergency

## Commands Reference

| Command | Purpose |
|---|---|
| df -hT | Check filesystem usage and type |
| du -sh /path/* \| sort -rh | Find largest space consumers |
| find /path -size +1G | Locate specific large files |
| lsof +L1 | Find deleted-but-open files holding space |
| truncate -s 0 file | Zero out an active file without deleting it |
