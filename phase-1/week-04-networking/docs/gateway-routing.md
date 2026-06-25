# Lab 1 — Default Gateway Misconfiguration and Recovery

## Goal

Prove exactly why a broken default gateway affects
external connectivity but NOT local subnet
connectivity — using real ARP table evidence, not just
ping results.

## Concept

The default gateway is only consulted for traffic
leaving the local subnet. Devices on the SAME subnet
are reached directly via ARP, with no gateway
involvement at all. A working local network + broken
internet access is a strong signal the problem is the
gateway, not something deeper.

## Baseline (Before Breaking Anything)

```bash
ip addr show
ip route show
```
eth0: 192.168.1.105/24
default via 192.168.1.1 dev eth0
192.168.1.0/24 dev eth0 scope link

Two separate routes exist: one for the local subnet
(no gateway needed) and one default route for
everything else (via the gateway).

Confirmed both local and external connectivity working:
```bash
ping -c 3 192.168.1.1   # success
ping -c 3 8.8.8.8        # success
```

## The Break

```bash
ip route del default via 192.168.1.1 dev eth0
ip route add default via 192.168.1.250 dev eth0
```
Set the default gateway to a nonexistent IP
(192.168.1.250 — not a real device on the network).

## Results

```bash
ping -c 3 192.168.1.1
```
**Succeeded** — 0% packet loss. Local subnet traffic
unaffected by the broken gateway.

```bash
ping -c 3 8.8.8.8
```
**Failed immediately** with `Destination Host
Unreachable` (not a timeout — an instant rejection).

## Root Cause — Verified with ARP Table

```bash
ip neigh show
```
192.168.1.250 dev eth0 FAILED
192.168.1.1   dev eth0 lladdr 60:db:98:56:87:96 STALE

`FAILED` proves the machine sent an ARP request for
192.168.1.250 ("who has this IP?") and got no response
— because no device with that address exists on the
subnet. The real gateway (192.168.1.1) shows a valid
MAC address, confirming it's a real, responding device.

This is the actual evidence behind the symptom:
external packets can't even leave the local network
because there's no MAC address to send them to.

## Recovery

```bash
ip route del default via 192.168.1.250 dev eth0
ip route add default via 192.168.1.1 dev eth0
ip route show
ping -c 4 8.8.8.8
```
Confirmed: 0% packet loss, normal latency restored.

## Key Lessons

1. Local subnet traffic does not depend on the default
   gateway — it's resolved directly via ARP
2. "Destination Host Unreachable" (instant rejection)
   vs a timeout is a meaningful diagnostic distinction
   — unreachable often points to a local ARP/routing
   problem rather than something far away
3. `ip neigh show` provides direct proof of ARP
   resolution failure (`FAILED` state) — don't assume
   the mechanism, verify it
4. Diagnostic pattern: local works + external fails =
   check the default gateway first

## Commands Reference

| Command | Purpose |
|---|---|
| `ip route show` | View current routing table |
| `ip route del/add default via <ip> dev <iface>` | Modify default gateway |
| `ip neigh show` | View ARP table — proves MAC resolution success/failure |
| `ping -c N <target>` | Test reachability with a fixed packet count |
