# Lab 2 — DNS Misconfiguration and Recovery

## Goal

Prove the distinction between a DNS failure and a
network/routing failure, using a three-way comparison:
a DNS tool (dig), a raw-IP ping, and a hostname ping.

## Concept

DNS is only consulted when a HOSTNAME needs to be
converted into an IP address. A raw IP address (like
8.8.8.8) requires no DNS lookup at all — there's
nothing to resolve. This makes "ping by IP vs ping by
hostname" one of the fastest ways to isolate whether a
problem is DNS-specific or a deeper network issue.

## Baseline

```bash
cat /etc/resolv.conf
```
```
nameserver 192.168.1.1
```
```bash
dig google.com +short
```
Returned real IPs — DNS working correctly, resolving
through the gateway acting as DNS resolver.

## The Break

```bash
echo "nameserver 192.168.1.250" > /etc/resolv.conf
```
Pointed DNS at a nonexistent server (same nonexistent-IP
pattern used in Lab 1's gateway test).

## Results — Three-Way Comparison

```bash
dig google.com +short
```
;; connection timed out; no servers could be reached

Confirms DNS resolution itself is broken — tried to
query 192.168.1.250 and got no response.

```bash
ping -c 3 8.8.8.8
```
**Succeeded**, 0% packet loss. No DNS involved — a raw
IP needs no lookup, so this proves routing/network
connectivity is completely unaffected.

```bash
ping -c 3 google.com
```
ping: google.com: Name or service not known

The OS could not even convert the hostname into an IP
address before attempting to send a single packet —
this error happens entirely client-side, before any
network traffic is generated.

## Diagnostic Pattern Established
Raw IP ping works + hostname ping fails
= DNS is the problem, not routing or
the network itself
Isolate and check DNS configuration directly
rather than wasting time on cables, gateways,
or firewall rules

## Recovery

```bash
echo "nameserver 192.168.1.1" > /etc/resolv.conf
dig google.com +short
ping -c 3 google.com
```
Confirmed recovery — `dig` returned real IPs, and
`ping google.com` succeeded, showing the resolved IP
directly in its output (`142.250.114.102`) as visible
proof resolution happened successfully.

## Key Lessons

1. DNS lookups only happen for hostnames — raw IP
   addresses bypass DNS entirely
2. `ping <IP>` succeeding while `ping <hostname>`
   fails is a clean, fast signal that DNS specifically
   is broken, not the network
3. `dig <domain> +short` querying a broken resolver
   produces a clear timeout message naming the failure
   mode ("no servers could be reached")
4. `ping <hostname>` failing shows the resolved IP
   address was never even obtained — the failure
   happens before any packet is sent

## Commands Reference

| Command | Purpose |
|---|---|
| `cat /etc/resolv.conf` | View current DNS server configuration |
| `dig <domain> +short` | Query DNS directly, see only the IP result |
| `ping -c N <IP>` | Test pure network/routing reachability, no DNS |
| `ping -c N <hostname>` | Test DNS resolution + reachability together |
