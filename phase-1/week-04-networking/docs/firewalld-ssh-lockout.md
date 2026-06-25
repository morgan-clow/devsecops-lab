# Lab 3 — firewalld Port Block and Recovery (SSH Lockout Simulation)

## Goal

Simulate a real SSH lockout caused by a firewall
change, recover safely using an existing session, and
learn to distinguish connection error signatures.

## Baseline

```bash
firewall-cmd --list-all
```
SSH access was permitted only via an existing rich
rule (not the general `ssh` service):
rich rules:
rule family="ipv4" source address="192.168.1.200" service name="ssh" accept

## The Break

```bash
firewall-cmd --remove-rich-rule='rule family="ipv4" source address="192.168.1.200" service name="ssh" accept' --permanent
firewall-cmd --reload
```

**Safety note**: an already-established SSH session
survived the firewall change (existing connections
aren't automatically killed). The actual test was
attempting a brand NEW connection.

## Result

New connection attempt from a separate terminal:
```bash
ssh root@192.168.1.105
```
ssh: connect to host 192.168.1.105 port 22: Connection timed out

## Error Signature Comparison

| Error | Meaning | Root Cause Category |
|---|---|---|
| Destination Host Unreachable | No route/ARP resolution possible | Routing/ARP problem (Lab 1) |
| Connection timed out | Packet arrived, nothing answered | Firewall silently dropping traffic |
| Connection refused | Packet arrived, port is closed/no service listening | No service running on that port |

`Connection timed out` specifically indicates the
packet reached the destination but firewalld silently
dropped it — the sender waits and eventually gives up
with no response at all.

## Recovery

Fixed from the still-active original session (never
risk losing the only working connection during a
lockout test):

```bash
firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.200" service name="ssh" accept' --permanent
firewall-cmd --reload
firewall-cmd --list-all
```

Confirmed recovery — new SSH connection attempt from
Windows succeeded immediately.

## Key Lessons

1. Always keep an existing/console session open before
   testing firewall changes that could affect SSH access
2. Existing TCP connections often survive a firewall
   rule change; only NEW connection attempts are
   actually tested by the new rules
3. "Connection timed out" specifically signals a
   firewall drop — different from "refused" (no
   service listening) or "unreachable" (no route/ARP)
4. Rich rules and the general services list are
   independent — a port can be blocked from the
   services list but still allowed via a specific rich
   rule, or vice versa

## Commands Reference

| Command | Purpose |
|---|---|
| `firewall-cmd --list-all` | View full current firewall state |
| `firewall-cmd --add/remove-rich-rule='...' --permanent` | Modify rich rules |
| `firewall-cmd --reload` | Apply permanent changes |
| `ssh user@host` (new terminal) | Test if NEW connections are actually blocked |
