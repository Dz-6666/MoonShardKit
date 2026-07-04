# MoonShardKit

MoonShardKit is a deterministic shard placement and migration planning library
for MoonBit.

It provides consistent hashing, virtual nodes, rendezvous hashing, weighted
placement, topology-aware replicas, cluster change plans, and distribution
quality reports without depending on networking or storage APIs.

## Problems answered

1. Which node should own a key?
2. Which distinct zones should hold its replicas?
3. How much data moves when nodes join, leave, or change weight?
4. Is the resulting distribution balanced enough?
5. Can the same topology produce identical placement on every MoonBit backend?

## Status

Active development for the 2026 MoonBit Open Source Ecosystem Competition.
See [ROADMAP.md](ROADMAP.md) and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## License

Apache-2.0.
