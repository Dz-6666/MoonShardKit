# Architecture

MoonShardKit separates placement policy from networking and storage.

## Layers

`Stable hash`
: Produces backend-independent unsigned scores from keys, node IDs, and salts.

`Topology`
: Describes node identity, weight, zone, rack, availability, and virtual-node
count without opening sockets or reading service discovery.

`Placement`
: Implements consistent rings and rendezvous ranking.

`Replica policy`
: Selects distinct owners while honoring zone and rack diversity when the
topology makes those constraints feasible.

`Migration planner`
: Compares two immutable topology snapshots and emits per-key ownership moves.

`Analysis`
: Measures owner counts, expected shares, movement ratio, skew, and constraint
violations.

## Determinism contract

The same key set, node snapshot, algorithm configuration, and seed must produce
the same owners, replicas, migration plan, and report on all MoonBit backends.

## Non-goals

- network membership or failure detection;
- distributed consensus;
- copying user data;
- storing cluster configuration;
- cryptographic key protection.

The library computes plans. Applications decide when and how to execute them.
