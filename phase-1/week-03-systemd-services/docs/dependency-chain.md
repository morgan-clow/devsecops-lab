# Lab 3 — Dependency Chains and Cascade Failures

## Goal

Build a hard dependency between two services
(`Requires=` + `After=`) and observe exactly how
systemd handles cascading failures — both downward
(when the dependency stops) and the lack of automatic
recovery upward (when the dependency comes back).

## Setup

Two services simulating a database (serviceA) and an
app that depends on it (serviceB):

```bash
# serviceA.sh and serviceB.sh — identical pattern,
# each writes a heartbeat to its own log every 10s
```

serviceA.service:
```ini
[Unit]
Description=Service A - Simulated Database
After=network.target

[Service]
ExecStart=/usr/local/bin/serviceA.sh
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
```

serviceB.service (the dependency is set here):
```ini
[Unit]
Description=Service B - Simulated App (depends on Service A)
Requires=serviceA.service
After=serviceA.service

[Service]
ExecStart=/usr/local/bin/serviceB.sh
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
```

Both started cleanly and confirmed healthy with
`systemctl status`.

## Test 1 — Cascade DOWN

```bash
systemctl stop serviceA
systemctl status serviceB
```

Result: serviceB stopped automatically, without ever
being touched directly:

Stopping Service B...
serviceB.service: Deactivated successfully.
Stopped Service B...

`Requires=serviceA.service` cascaded the stop from A
to B exactly as designed — a hard dependency means a
failure/stop in the required unit takes down the
dependent unit too.

## Test 2 — No Automatic Cascade UP

```bash
systemctl start serviceA
systemctl status serviceB
```

Result: serviceA came back online, but serviceB
**remained stopped**. Nothing in `Requires=`/`After=`
watches for the dependency recovering and restarts
the dependent service automatically.

```bash
systemctl start serviceB   # had to be started manually
```

## Key Lesson — Real-World Incident Pattern

This is exactly how a short outage becomes a long one
in production:
1. Database (serviceA) crashes
2. App (serviceB) cascades down with it
3. On-call engineer restarts the database
4. Database is healthy again
5. App is still down — nobody restarted it, and
   nothing did it automatically
6. Users remain impacted even though "the root cause
   is fixed"

**Takeaway**: when recovering from an outage, you must
manually check and restart every downstream dependent
service — fixing the root cause alone does not
guarantee the whole chain recovers.

## Key Lessons

1. `Requires=` causes a hard, automatic cascade
   **downward** — if the required unit stops/fails,
   the dependent unit stops too
2. There is no automatic cascade **upward** — a
   dependency coming back online does not restart
   services that stopped because of it
3. Real incident response must include checking every
   downstream service in a dependency chain, not just
   the original failure point

## Commands Reference

| Command | Purpose |
|---|---|
| `systemctl stop <svc>` | Manually stop a service (test cascade effects) |
| `systemctl status <svc>` | Check current state and recent history |
| `Requires=` (in unit file) | Hard dependency — cascades stop/failure downward |
| `After=` (in unit file) | Ordering only — paired with Requires/Wants |
