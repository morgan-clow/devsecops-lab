# Week 3 — systemd & Services

## Overview

This week covers systemd service management,
dependencies, and troubleshooting. All labs performed
on phase1-vm-2 (CentOS Stream 9) in a Proxmox homelab,
using custom test services built from scratch
(myapp, serviceA, serviceB) to simulate real
production applications.

---

## Core Concepts

### Unit File Anatomy

```ini
[Unit]
Description=...
After=network.target

[Service]
ExecStart=/path/to/script
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
  unit fails or stops, this unit cascades down too.
- **Wants=** — soft dependency. If the wanted unit
  fails, this unit is unaffected.
- **After=** — controls ORDER only, not whether
  something starts.
- **The trap**: `After=` alone does not pull in a
  dependency. A unit with only `After=` and no
  `Requires=`/`Wants=` starts regardless of whether
  its "dependency" ever started — silently, with no
  error. Production pattern: combine
  `Wants=`/`Requires=` with `After=` together.

### Process Tracking

systemd launches `ExecStart` as a child process and
tracks its exact PID. Verified directly by comparing
`systemctl status` ("Main PID: 21654") against
`ps aux | grep <script>` (same PID) — proving systemd
and the OS are tracking the identical process, not an
abstraction.

### journalctl vs Application Logs

`journalctl -u <service>` only captures
**stdout/stderr**. An app that logs to its own file
(`echo ... >> /var/log/app.log`) is invisible there —
journalctl shows only systemd's lifecycle messages.
Always check both in a real incident.

### Restart Policy and Exit Codes

`Restart=on-failure` restarts only on a **non-zero
exit code** — a clean `exit 0` is never restarted
under this policy. `RestartSec` (default ~100ms)
controls the delay before a restart attempt, which is
why rapid failures can hit systemd's built-in rate
limiter (`Start request repeated too quickly`) within
the same second.

### Drop-in Overrides

`systemctl edit <service>` creates a separate override
file in `/etc/systemd/system/<service>.service.d/`
without touching the original unit file. `systemctl
cat <service>` shows the fully merged effective
config. `systemctl status` surfaces a `Drop-In:` line
whenever overrides are present.

---

## Labs Completed

- [x] [Lab 1 — Custom Service](https://github.com/morgan-clow/devsecops-lab/blob/main/phase-1/week-03-systemd-services/docs/custom-service.md)
      — built a unit file from scratch, verified
      process tracking and log behavior
- [x] [Lab 2 — Broken ExecStart](https://github.com/morgan-clow/devsecops-lab/blob/main/phase-1/week-03-systemd-services/docs/broken-execstart.md)
      — diagnosed `status=203/EXEC`, hit and recovered
      from systemd's restart rate limiter
- [x] [Lab 3 — Dependency Chain](./lab3-dependency-chain.md)
      — proved `Requires=` cascades failures downward
      but never restarts dependents automatically when
      the dependency recovers
- [x] [Lab 4 — Restart Policies](./lab4-restart-policies.md)
      — proved `on-failure` is tied to exit code, not
      simply "the process stopped"
- [x] [Lab 5 — Drop-in Overrides](./lab5-drop-in-overrides.md)
      — modified service behavior without touching the
      original unit file

---

## Real-World Incident Patterns Demonstrated

1. **Bad deployment path** — ExecStart pointing to a
   nonexistent file, diagnosed via `status=203/EXEC`
   and `journalctl`
2. **Cascading outage** — a "database" going down
   takes the "app" with it automatically; recovering
   the database does NOT automatically recover the app
3. **Restart loop protection** — systemd's own rate
   limiter prevents infinite crash-restart cycles, but
   requires `systemctl reset-failed` to clear after a
   fix
4. **Safe customization** — using drop-ins to change
   behavior on services you don't own, without risking
   loss of changes on a package update

---

## Commands Reference

| Command | Purpose |
|---|---|
| `systemctl daemon-reload` | Re-scan unit files after creating/editing |
| `systemctl start/stop/restart <svc>` | Control service state |
| `systemctl status <svc>` | State, Main PID, exit reason, Drop-In info |
| `ps aux \| grep <process>` | Verify the actual OS process matches systemd's PID |
| `journalctl -u <svc>` | Logs for one specific unit |
| `journalctl -u <svc> -f` | Follow logs live |
| `journalctl -u <svc> -n 30` | Last 30 log lines for a unit |
| `systemctl reset-failed <svc>` | Clear failure/rate-limit counters |
| `systemctl edit <svc>` | Create/edit a drop-in override safely |
| `systemctl cat <svc>` | View merged effective configuration |
