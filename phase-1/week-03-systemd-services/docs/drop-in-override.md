# Lab 5 — Drop-in Override Configurations

## Goal

Modify a service's behavior without ever editing its
original unit file, using systemd's drop-in override
mechanism — the production-correct way to customize
services managed by packages or shared infrastructure.

## Concept

A drop-in override lives in a separate directory:
/etc/systemd/system/<service>.service.d/*.conf

systemd merges any `.conf` files found there with the
original unit file at runtime. Settings in the
drop-in take priority. This matters because if the
original unit file is ever overwritten (e.g. by a
package update), a separate drop-in survives untouched.

## Procedure

### Step 1 — Create the override

```bash
systemctl edit serviceB
```
This automatically creates
`/etc/systemd/system/serviceB.service.d/` and opens an
editor for the override content — without touching the
original `serviceB.service` file at all.

Added:
```ini
[Service]
RestartSec=10
```

### Step 2 — Verify the override file exists

```bash
cat /etc/systemd/system/serviceB.service.d/override.conf
```
[Service]
RestartSec=10

### Step 3 — Verify the original file is untouched

```bash
cat /etc/systemd/system/serviceB.service
```
Confirmed identical to the original — `Requires=`,
`After=`, `ExecStart=`, `Restart=on-failure`, all
unchanged.

### Step 4 — View the merged effective configuration

```bash
systemctl cat serviceB
```
Output clearly shows BOTH files, labeled by source path:
/etc/systemd/system/serviceB.service
[entire original unit file]
/etc/systemd/system/serviceB.service.d/override.conf
[Service]
RestartSec=10

This is the authoritative way to see what systemd is
*actually* using — especially important once a
service has multiple override files layered on top of
the original.

### Step 5 — Apply and confirm

```bash
systemctl daemon-reload
systemctl restart serviceB
systemctl status serviceB
```
Status output included a new line not seen in any
previous lab:
Drop-In: /etc/systemd/system/serviceB.service.d
└─override.conf

systemd explicitly surfaces drop-in overrides directly
in `systemctl status` — this is the first thing to
check when a service behaves differently than its main
unit file suggests.

## Key Lessons

1. `systemctl edit <service>` is the safe, built-in way
   to create a drop-in — it never touches the original
   unit file
2. `systemctl cat <service>` shows the fully merged
   effective configuration across the original file and
   any drop-ins
3. `systemctl status` surfaces a `Drop-In:` line
   whenever overrides are present — a key diagnostic
   clue in real troubleshooting
4. Drop-ins survive package updates that might
   overwrite the original unit file, making them the
   correct way to customize services you don't own

## Commands Reference

| Command | Purpose |
|---|---|
| `systemctl edit <svc>` | Create/edit a drop-in override safely |
| `systemctl cat <svc>` | View merged effective configuration |
| `systemctl status <svc>` | Shows `Drop-In:` line if overrides exist |
| `/etc/systemd/system/<svc>.service.d/*.conf` | Where drop-in files live |
