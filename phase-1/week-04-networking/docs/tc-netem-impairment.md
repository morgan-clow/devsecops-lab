# Lab 5 — Network Impairment Simulation with tc/netem

## Goal

Use tc (traffic control) and netem (network emulator)
to artificially inject latency and packet loss into a
real interface, proving these conditions can be tested
deliberately rather than waiting for them to happen by
accident in production.

## Concept

netem lets you simulate degraded network conditions —
latency, packet loss, jitter, corruption — on a live
interface. This makes it possible to answer questions
like "does our application handle 200ms latency
gracefully, or does it time out?" through deliberate
testing instead of guesswork.

## Baseline

```bash
tc qdisc show dev eth0
```
qdisc fq_codel 0: root ...

Default queueing discipline already active (fq_codel —
modern automatic queue management most Linux systems
use to prevent buffer bloat).

```bash
ping -c 5 8.8.8.8
```
Baseline latency: ~8.5-9ms, 0% packet loss.

## Test 1 — Artificial Latency

```bash
tc qdisc add dev eth0 root netem delay 200ms
ping -c 5 8.8.8.8
```
Result: latency jumped to ~209-223ms — almost exactly
the 200ms added on top of the real ~8.5ms baseline.
Clean, measurable, predictable proof netem is working.

## Test 2 — Artificial Packet Loss

```bash
tc qdisc change dev eth0 root netem loss 30%
ping -c 10 8.8.8.8
```
Result: 7 of 10 packets received, exactly 30% loss.
Sequence numbers 3, 7, and 10 were silently missing
from the output — no error, just gaps in the sequence.
This is exactly how real packet loss appears in
production monitoring: silence for specific packets,
not an explicit failure message.

Latency for successfully-received packets remained
normal (~8-9ms), confirming loss and latency are
independent, separately-simulated conditions.

## Recovery

```bash
tc qdisc del dev eth0 root netem
tc qdisc show dev eth0   # confirms fq_codel restored
ping -c 5 8.8.8.8
```
Confirmed full recovery: ~8.4ms average latency, 0%
packet loss — matching the original baseline exactly.

## Key Lessons

1. `tc qdisc add ... netem` injects controllable,
   precise network impairment for deliberate testing
2. `tc qdisc change` modifies existing netem rules
   without stacking duplicates; `tc qdisc del` removes
   netem entirely and restores the previous discipline
3. Real packet loss shows up as missing sequence
   numbers with no error message — not a visible
   "failure," just silence for that packet
4. Latency and packet loss can be simulated
   independently — useful for isolating which specific
   condition an application struggles with
5. Always verify recovery after testing impairment —
   `tc qdisc show` confirms the original discipline is
   back in place

## Commands Reference

| Command | Purpose |
|---|---|
| `tc qdisc show dev <iface>` | View current queueing discipline |
| `tc qdisc add dev <iface> root netem delay <ms>` | Add artificial latency |
| `tc qdisc change dev <iface> root netem loss <%>` | Modify existing netem rule (e.g. to packet loss) |
| `tc qdisc del dev <iface> root netem` | Remove netem, restore default discipline |
