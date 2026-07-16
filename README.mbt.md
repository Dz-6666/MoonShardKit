# MoonShardKit

Deterministic shard placement and migration planning for MoonBit.

MoonShardKit is a backend-neutral foundation library for caches, object
stores, task queues, distributed indexes, and stateless routing systems. The
same topology and key set produce the same placement on Native, JavaScript,
WebAssembly, and WebAssembly-GC.

## Features

- Weighted consistent hashing with virtual nodes
- Integer-score weighted Rendezvous hashing
- Zone- and rack-aware replica placement
- Deterministic primary and replica migration plans
- Five-phase safe migration workflows: add, backfill, verify, cut over, clean up
- Global wave concurrency and per-node pressure budgets
- Migration-plan validation and blocked-key reporting
- Capacity-admitted batch placement with per-node primary/replica budgets
- Distribution, skew, and topology-violation reports
- Stable JSON output and a runnable CLI
- No network, database, service-discovery, or platform dependency

## Install

```bash
moon add Dz-6666/moonshardkit
```

## Example

```moonbit nocheck
let nodes = [
  @moonshardkit.ShardNode::new("node-a", zone="east", rack="rack-1"),
  @moonshardkit.ShardNode::new("node-b", zone="west", rack="rack-1"),
  @moonshardkit.ShardNode::new("node-c", zone="south", rack="rack-2"),
]

let placement = @moonshardkit.place_key(nodes, "customer-42", 3)
println(placement.to_json())
```

`placement.owners[0]` is the primary owner. Remaining entries are replicas,
ordered deterministically while preferring zone and rack diversity.

## Safe Migration Workflow

```moonbit nocheck
let workflow = @moonshardkit.plan_safe_migration(
  keys,
  old_nodes,
  new_nodes,
  replicas=3,
  max_actions_per_wave=64,
  max_actions_per_node=8,
)

assert_eq(@moonshardkit.validate_safe_migration(workflow).length(), 0)
```

The planner never emits source cleanup before target creation, backfill,
verification, and primary cutover. Keys without a readable source are reported
in `blocked_keys` instead of receiving an unsafe plan. The output is a pure,
deterministic control-plane plan; storage adapters execute and checkpoint it.

## Capacity-constrained admission

`plan_capacity_placement` turns placement into an admission decision for a
batch. It retains deterministic weighted Rendezvous ordering and topology-aware
replica preference, while never exceeding a node's primary or replica budget.
Keys that cannot obtain every requested owner remain visible in
`rejected_keys`; there is no hidden overload fallback.

```bash
moon run cmd/scenario --target js
```

The scenario models a four-region control plane with 24 tenants, three
replicas, and explicit per-node limits. It prints a stable JSON audit report
with accepted/rejected keys and every budgeted node load.

## Verify

```bash
moon fmt --check
moon check --deny-warn --target all
moon info && git diff --exit-code -- '*.mbti'
moon test --deny-warn --target all
moon run cmd/main --target js
moon run bench/main --target js
moon run cmd/scenario --target js
```

The benchmark workload places 10,000 deterministic keys and reports load
spread, movement ratio, safe-workflow action count, wave count, blocked keys,
and validation issues after a topology change.

CI uses the executable quality gates supported by the current MoonBit CLI:
`moon fmt --check`, `moon check --deny-warn --target all`, `moon info` plus a
clean `.mbti` diff, and `moon test --deny-warn --target all`. `moon fmt` and
`moon info` do not accept `--deny-warn` in this CLI version, so CI documents
their equivalent checks rather than adding commands that always fail.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Usage guide](docs/USAGE.md)
- [Project value](docs/VALUE_PROPOSITION.md)
- [Related work](docs/RELATED_WORK.md)
- [Verification evidence](docs/EVIDENCE.md)
- [Benchmark plan](docs/BENCHMARK_PLAN.md)
- [Changelog](CHANGELOG.md)

## License

Apache-2.0.
