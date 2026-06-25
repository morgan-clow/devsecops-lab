# Lab 2 — Broken ExecStart and Recovery

## Goal

Simulate a common production mistake — a unit file's
ExecStart pointing to a script that doesn't exist —
and practice the full diagnose-and-recover workflow
using systemctl and journalctl.

## Scenario

A typo or stale path after a deployment change causes
ExecStart to point at a nonexistent file. This happens
constantly in production when a deployment script
moves files but the unit file isn't updated to match.

## The Break

```bash
vi /etc/systemd/system/myapp.service
```
Changed:
```ini
ExecStart=/usr/local/bin/myapp_typo.sh
```
```bash
systemctl daemon-reload
systemctl start myapp
```

## Diagnosis

```bash
systemctl status myapp
```
Key evidence:

Active: failed (Result: exit-code)

Main PID: ... (code=exited, status=203/EXEC)

`status=203/EXEC` = systemd tried to execute the file
and could not — missing file or missing execute
permission. This is the single most important code to
recognize immediately.

```bash
journalctl -u myapp -n 30
```
Most diagnostic line:

Failed to locate executable /usr/local/bin/myapp_typo.sh: No such file or directory

## The Restart Storm

`Restart=on-failure` (set in the unit file) caused
systemd to retry starting the service 5 times within
the same second. The journal showed the identical
failure cycle repeating:

Started → Failed to locate executable → Main process

exited (203/EXEC) → Failed with result 'exit-code' →

Scheduled restart job, restart counter is at N → Stopped

After the 5th attempt, systemd's built-in rate limiter
(`StartLimitBurst`/`StartLimitIntervalSec`, default
~5 starts per 10 seconds) tripped:

Start request repeated too quickly.

This protects the system from an infinite
crash-restart loop consuming CPU indefinitely.

## Recovery

```bash
# 1. Fix the actual path
vi /etc/systemd/system/myapp.service
# ExecStart=/usr/local/bin/myapp.sh

# 2. Reload
systemctl daemon-reload

# 3. Clear the failure/rate-limit state
systemctl reset-failed myapp

# 4. Start again
systemctl start myapp
systemctl status myapp
```
Confirmed full recovery:

Active: active (running)

Main PID: 21858 (myapp.sh)

`reset-failed` is the step most commonly forgotten —
without it, a service can remain affected by the rate
limiter even after the underlying problem is fixed.

## Key Lessons

1. `status=203/EXEC` = bad path or missing execute
   permission on ExecStart — recognize this instantly
2. `journalctl -u <service>` shows the precise failure
   reason — check this before guessing
3. `Restart=on-failure` can cause rapid restart loops;
   systemd self-limits after ~5 attempts in 10 seconds
4. Always run `systemctl reset-failed <service>` after
   fixing a failed service, before starting it again

## Commands Reference

| Command | Purpose |
|---|---|
| `systemctl status <svc>` | Current state + last exit reason |
| `journalctl -u <svc> -n 30` | Recent log history for one unit |
| `journalctl -u <svc> -f` | Follow logs live |
| `systemctl reset-failed <svc>` | Clear failure/rate-limit counters |
| `systemctl daemon-reload` | Re-scan unit files after editing |
