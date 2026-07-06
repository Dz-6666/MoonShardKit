# Changelog

## 0.2.0 - 2026-07-06

### Added

- Five-phase safe migration workflow generation.
- Deterministic migration waves with global and per-node budgets.
- Blocked-key reporting when no readable migration source exists.
- Safety validation for phase order, wave indexes, and pressure limits.
- Stable JSON output, CLI evidence, and a 10,000-key workflow benchmark.
- Cross-backend regression tests for ordering, budgets, blocking, and determinism.

## 0.1.0 - 2026-07-06

### Added

- Initial project structure, architecture, and roadmap.
- Stable cross-backend hash and placement score primitives.
- Node topology, placement, migration, and distribution report models.
- Weighted virtual-node consistent hash ring with distinct replica lookup.
- Integer-ticket weighted rendezvous ranking and placement namespaces.
- Topology-aware replica placement with graceful constraint fallback.
- Snapshot migration plans with primary, replica, and movement evidence.
- Distribution load, skew, completeness, zone, and rack analysis.
- Stable JSON output for placement, migration, and distribution reports.
- CLI demonstration for placement, distribution, and node expansion planning.
- Deterministic 10,000-key distribution and expansion workload.
- Cross-backend GitHub Actions checks, tests, demo, and workload.
- Contribution, issue, pull request, security, and licensing policies.
- Structured topology validation for duplicate and missing metadata.
- Unified algorithm dispatcher and deterministic batch placement.
