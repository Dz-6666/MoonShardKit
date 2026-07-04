# Contributing

## Before opening a pull request

1. Open an issue with a minimal topology and deterministic key sample.
2. Keep one pull request focused on one placement behavior.
3. Add tests for owner order, movement, and constraint outcomes.
4. Update documentation and `CHANGELOG.md`.
5. Run:

```bash
moon fmt --check
moon check --target all
moon test --target wasm
moon test --target wasm-gc
moon test --target js
```

Native tests run in CI.

## Determinism rules

Do not use wall-clock time, ambient randomness, memory addresses, unordered map
iteration, or backend-specific formatting in placement decisions.

## Commit quality

Use small coherent commits. Empty commits and generated build outputs are not
accepted.
