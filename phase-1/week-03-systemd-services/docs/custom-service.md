# Lab 1 — Build a Custom systemd Service from Scratch

## Goal

Write a unit file from scratch, load it into systemd,
and verify it manages a real long-running process —
establishing the foundation for the rest of Week 3.

## Concepts Covered

### Unit File Anatomy

```ini
[Unit]
Description=My Custom Test Application
After=network.target

[Service]
ExecStart=/usr/local/bin/myapp.sh
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
```

- `[Unit]` — metadata and dependencies
- `[Service]` — how to actually run the program
- `[Install]` — how this hooks into boot targets

### Wants vs Requires vs After

- **Requires=** — hard dependency. If the required
  unit fails, this unit fails too.
- **Wants=** — soft dependency. If the wanted unit
  fails, this unit is unaffected and starts anyway.
- **After=** — controls ORDER only, not whether
  something starts.
- **The trap**: `After=` alone does NOT pull in a
  dependency. If a unit only has
  `After=postgresql.service` with no
  `Requires=`/`Wants=`, and postgresql is never
  started, the unit starts anyway — immediately,
  with no error. In production this causes
  "works in testing, fails after a clean reboot"
  outages.
- **Production pattern**: combine both —
  `Wants=postgresql.service` + `After=postgresql.service`
  (or `Requires=` for a true hard dependency).

### Process Tracking — How systemd Actually Controls a Service

systemd launches the `ExecStart` command as a child
process and remembers its exact Process ID (PID). That
PID is the literal mechanical link between the unit
file and the running program.

Proven by comparing:
```bash
systemctl status myapp   # shows "Main PID: 21654"
ps aux | grep myapp.sh   # shows the SAME PID: 21654
```

`systemctl stop` sends a termination signal to that
specific PID — it directly kills the tracked process,
it isn't an abstract action.

### journalctl vs Application Log Files

systemd's journal (`journalctl -u <service>`) only
captures what a process writes to **stdout/stderr**.
If an application logs to its own file instead
(`echo ... >> /var/log/app.log`), journalctl shows
ONLY systemd's own lifecycle messages — none of the
application's actual activity.

Proven directly: `journalctl -u myapp` showed only
start/stop messages, while `/var/log/myapp.log`
contained the full heartbeat history.

**Lesson**: checking only journalctl can give a false
sense that "the service is fine" while having zero
visibility into what the application is actually
doing. Always check both in a real incident.

## Procedure

### Step 1 — The Script

```bash
#!/bin/bash
while true; do
  echo "$(date) - myapp is running" >> /var/log/myapp.log
  sleep 10
done
```
Saved at `/usr/local/bin/myapp.sh`, made executable:
```bash
chmod +x /usr/local/bin/myapp.sh
```

This acts as a stand-in for a real long-running
application (web server, monitoring agent, etc.) —
something that starts and keeps running indefinitely,
periodically doing work.

### Step 2 — The Unit File

Saved at `/etc/systemd/system/myapp.service`
(content above).

### Step 3 — Load and Start

```bash
systemctl daemon-reload   # required after creating/editing a unit file
systemctl start myapp
systemctl status myapp
```

Confirmed healthy state:

Active: active (running)

Main PID: 21654 (myapp.sh)

CGroup: /system.slice/myapp.service

├─21654 /bin/bash /usr/local/bin/myapp.sh

└─21656 sleep 10

### Step 4 — Verify with ps

```bash
ps aux | grep myapp.sh
```
Confirmed same PID (21654) appears, proving systemd
and the OS are tracking the identical process.

### Step 5 — Check Both Log Sources

```bash
journalctl -u myapp -n 10
cat /var/log/myapp.log
```
journalctl showed only "Started My Custom Test
Application." The log file showed every 10-second
heartbeat — proving the distinction above.

### Step 6 — Stop and Verify Termination

```bash
systemctl stop myapp
ps aux | grep myapp.sh
```
Confirmed PID 21654 no longer appears — the actual
process was terminated, not just marked stopped.

## Key Lessons

1. The Main PID shown in `systemctl status` is the
   literal OS process systemd is tracking — verifiable
   directly with `ps aux`
2. `After=` alone does not guarantee a dependency is
   ever started — combine with `Wants=`/`Requires=`
3. journalctl only sees stdout/stderr — an app logging
   to its own file is invisible there; check both
4. `systemctl stop` performs a real, direct action on
   a real process — not an abstraction

## Commands Reference

| Command | Purpose |
|---|---|
| `systemctl daemon-reload` | Re-scan unit files after creating/editing |
| `systemctl start/stop <svc>` | Control service state |
| `systemctl status <svc>` | Current state + Main PID |
| `ps aux \| grep <process>` | Verify the actual OS process |
| `journalctl -u <svc> -n 10` | Last N log lines for a unit |
