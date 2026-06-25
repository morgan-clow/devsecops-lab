# Week 4 — Networking Fundamentals

## Overview

This week covers Linux networking fundamentals and
troubleshooting — routing, DNS, firewalld, interface
binding, packet-level analysis, and deliberate network
impairment testing. All labs performed on phase1-vm-1
(CentOS Stream 9) in a Proxmox homelab.

---

## Core Concept — The Error Signature Reference

The single most valuable output of this week: real
evidence-backed proof that different network failures
produce distinctly different, recognizable error
messages — making it possible to identify roughly
which layer is broken before running a single
diagnostic command.

| Error Message | Root Cause | Lab |
|---|---|---|
| Destination Host Unreachable | No route/ARP resolution possible | Lab 1 (bad gateway) |
| Name or service not known | DNS lookup failed before any packet sent | Lab 2 (DNS) |
| Connection timed out | Packet arrived, firewall silently dropped it | Lab 3 (firewalld) |
| Connection refused | Packet arrived, nothing listening on that address/port | Interface binding (not built into final lab set) |

---

## Labs Completed

- [x] [Lab 1 — Default Gateway Misconfiguration](https://github.com/morgan-clow/devsecops-lab/blob/main/phase-1/week-04-networking/docs/gateway-routing.md)
      — proved local subnet traffic is unaffected by a
      broken gateway; verified ARP `FAILED` state as
      direct evidence rather than assumption
- [x] [Lab 2 — DNS Misconfiguration](https://github.com/morgan-clow/devsecops-lab/blob/main/phase-1/week-04-networking/docs/dns-recovery.md)
      — proved raw-IP ping bypasses DNS entirely while
      hostname ping requires it; established the
      "IP works, hostname doesn't = DNS problem"
      diagnostic pattern
- [x] [Lab 3 — firewalld SSH Lockout](https://github.com/morgan-clow/devsecops-lab/blob/main/phase-1/week-04-networking/docs/firewalld-ssh-lockout.md)
      — simulated and recovered from a real SSH
      lockout, using an existing session as a safety
      net rather than risking total lockout
- [x] [Lab 4 — tcpdump Packet Capture](https://github.com/morgan-clow/devsecops-lab/blob/main/phase-1/week-04-networking/docs/tcpdump-analysis.md)
      — learned why unfiltered captures are unusable
      noise, then used host/port filters to read real
      ICMP and TCP packet structure
- [x] [Lab 5 — tc/netem Network Impairment](https://github.com/morgan-clow/devsecops-lab/blob/main/phase-1/week-04-networking/docs/tc-netem-impairment.md)
      — deliberately injected and measured artificial
      latency and packet loss, then fully restored
      normal conditions

---

## Real-World Incident Patterns Demonstrated

1. **Local works, internet doesn't** — isolates the
   problem to the default gateway specifically, proven
   with ARP table evidence
2. **IP works, hostname doesn't** — isolates the
   problem to DNS specifically, before checking
   anything else
3. **Existing connections survive firewall changes,
   new ones don't** — the critical safety pattern for
   testing any firewall rule that could affect your
   own access
4. **"Works on the server, not from the network"** —
   the classic signature of a service bound to
   `127.0.0.1` instead of `0.0.0.0`
5. **Unfiltered packet captures are noise** — real
   troubleshooting always filters by host/port first
6. **Deliberate impairment testing** — proving an
   application's behavior under bad network conditions
   instead of waiting to discover it during a real
   outage

---

## Commands Reference

| Command | Purpose |
|---|---|
| `ip addr show` / `ip route show` | View interface IPs and routing table |
| `ip neigh show` | View ARP table — proves MAC resolution success/failure |
| `dig <domain> +short` | Query DNS directly |
| `cat /etc/resolv.conf` | View DNS server configuration |
| `firewall-cmd --list-all` | View full firewall state |
| `firewall-cmd --add/remove-rich-rule='...' --permanent` | Modify rich rules |
| `ss -tulnp \| grep <port>` | Show exactly which address a service is bound to |
| `tcpdump -i <iface> -n host/port <value>` | Filtered packet capture |
| `tc qdisc add/change/del dev <iface> root netem ...` | Inject/remove artificial network conditions |
