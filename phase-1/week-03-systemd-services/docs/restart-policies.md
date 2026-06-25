# Lab 4 — Restart Policies

## Goal

Prove exactly what `Restart=on-failure` does and does NOT do — specifically that it only restarts a service on an error exit code, not a clean/successful exit. This is a common misconception (assuming it restarts on ANY stop).

## Concept

Restart=no          → never auto-restart (default)
Restart=always      → restart regardless of HOW it stopped,
even a clean intentional exit
Restart=on-failure  → restart ONLY on a non-zero
(error) exit code
Restart=on-success  → opposite, niche use case

`RestartSec=` controls how long systemd waits before attempting a restart after deciding one is warranted. Default is ~100ms — extremely fast, which is why repeated failures can hit systemd's rate limiter (`Start request repeated too quickly`) within the same second.

## Test 1 — Clean Exit (exit 0) Does NOT Trigger Restart

Modified serviceB.sh to run once and exit successfully:

```bash
#!/bin/bash
echo "$(date) - serviceB ran once and is exiting cleanly" >> /var/log/serviceB.log
exit 0
```

**Bug encountered**: initial edit left a leftover `while true; do` from the previous script version without a matching `done`, causing a bash syntax error (`status=2/INVALIDARGUMENT`) rather than testing the intended clean exit. Corrected by replacing the entire file content (not editing inside the old loop).

After the fix, with the script correctly running `exit 0`:

```bash
systemctl status serviceB
```

Result:
Active: inactive (dead)

No restart attempts, no failure state — confirmed stable after `sleep 5` and a second check. **`Restart=on-failure` did not restart the service because the exit code indicated success.**

## Test 2 — Error Exit (exit 1) DOES Trigger Restart

Modified serviceB.sh to exit with an error code:

```bash
#!/bin/bash
echo "$(date) - serviceB is about to fail" >> /var/log/serviceB.log
exit 1
```

```bash
systemctl daemon-reload
systemctl start serviceB
systemctl status serviceB
journalctl -u serviceB -n 15
```

Result:
Active: failed (Result: exit-code)
Process: ... (code=exited, status=1/FAILURE)

journalctl showed systemd repeatedly restarting the service (`restart counter is at 3, 4, 5`) until it hit the same rate limiter seen in Lab 2:
Start request repeated too quickly.

## Conclusion

| Exit Code | Restart=on-failure Behavior |
|---|---|
| 0 (success) | No restart — service stays `inactive (dead)` |
| 1+ (error) | Restart attempted repeatedly until rate-limited |

This confirms `on-failure` is specifically tied to the **exit code**, not simply "the process stopped."

## Recovery

Restored serviceB.sh to its original long-running form:

```bash
#!/bin/bash
while true; do
  echo "$(date) - serviceB (app) is running" >> /var/log/serviceB.log
  sleep 10
done
```

```bash
systemctl daemon-reload
systemctl reset-failed serviceB
systemctl start serviceB
```

Confirmed healthy: `Active: active (running)`.

## Key Lessons

1. `Restart=on-failure` checks the **exit code**, not whether the process simply stopped — clean exits (code 0) are never restarted under this policy
2. `RestartSec` defaults to ~100ms, which is why rapid failure loops can hit the rate limiter within a single second
3. A syntax error in a leftover/incomplete script produces `status=2/INVALIDARGUMENT` — different from an intentional `exit 1` (`status=1/FAILURE`); both are treated as failures by `on-failure`, but the codes tell different stories during diagnosis
4. Always fully replace a script's contents when changing its logic — partial edits inside an old loop structure can leave it syntactically broken

## Commands Reference

| Command | Purpose |
|---|---|
| `Restart=on-failure` | Restart only on non-zero exit code |
| `RestartSec=<n>` | Delay before attempting a restart |
| `systemctl reset-failed <svc>` | Clear rate-limit/failure state before retrying |
| `journalctl -u <svc> -n 15` | View recent restart attempts and exit codes |
