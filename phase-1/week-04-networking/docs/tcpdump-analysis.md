# Lab 4 — tcpdump Packet Capture and Analysis

## Goal

Use tcpdump to observe raw network traffic at the
packet level, learn to filter out noise, and read the
basic structure of both ICMP and TCP packets.

## Concept

tcpdump captures packets as they actually travel
across an interface — the ground truth beneath
ping, curl, dig, and every other tool used in earlier
labs. Capturing without a filter on a busy network
produces overwhelming, mostly irrelevant noise; real
troubleshooting almost always uses a specific filter
(`host`, `port`, `src`, `dst`, etc).

## Attempt 1 — Unfiltered Capture (Too Noisy)

```bash
tcpdump -i eth0 -n
```
Captured 2775 packets in a short window — almost
entirely existing SSH session traffic plus background
broadcast noise from other devices on the home network
(ARP requests, mDNS, IGMP). The intended ping traffic
to 8.8.8.8 was impossible to find by eye in the noise.

**Lesson**: an unfiltered capture on any non-trivial
network is effectively unusable for targeted
troubleshooting.

## Attempt 2 — Filtered by Host (Clean Result)

```bash
tcpdump -i eth0 -n host 8.8.8.8
```
Run alongside `ping -c 3 8.8.8.8` in a separate
session. Result: exactly 6 packets, perfectly matching
the 3 pings sent:

192.168.1.105 > 8.8.8.8: ICMP echo request, seq 1
8.8.8.8 > 192.168.1.105: ICMP echo reply, seq 1
192.168.1.105 > 8.8.8.8: ICMP echo request, seq 2
8.8.8.8 > 192.168.1.105: ICMP echo reply, seq 2
192.168.1.105 > 8.8.8.8: ICMP echo request, seq 3
8.8.8.8 > 192.168.1.105: ICMP echo reply, seq 3

This is the literal data behind what `ping` summarizes
— the time gap between each request/reply pair is the
exact round-trip latency ping reports.

### Reading TCP Flags

[P.] = PUSH + ACK — carrying real data,
plus confirming receipt of previous data
[.]  = ACK only — pure confirmation, no new data

seq 27309:27905 = this packet contains bytes
27309 through 27905 of the
ongoing conversation
ack 2052        = confirms everything received
up through byte 2052

The constant stream of small PUSH/ACK packets is
characteristic of an interactive SSH session — every
keystroke and screen update generates traffic at this
level, very different from ping's simple
request/reply pattern.

## Key Lessons

1. Always filter tcpdump captures (`host`, `port`,
   etc.) — unfiltered captures on a real network are
   buried in irrelevant broadcast/background noise
2. ICMP (ping) traffic is simple: request → reply,
   one pair per ping
3. TCP traffic carries sequence/ack numbers and flags
   (`[P.]`, `[.]`, `[S.]`, etc.) describing exactly
   what data is being exchanged and acknowledged
4. The packet-level timestamps are the literal source
   of the latency numbers reported by higher-level
   tools like ping

## Commands Reference

| Command | Purpose |
|---|---|
| `tcpdump -i <iface> -n` | Capture all traffic on an interface, no hostname resolution |
| `tcpdump -i <iface> -n host <ip>` | Capture only traffic to/from a specific host |
| `tcpdump -i <iface> -n port <port>` | Capture only traffic on a specific port |
| `[P.]` / `[.]` flags | PUSH+ACK (data) vs ACK-only (confirmation) in TCP |
