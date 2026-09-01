# Test matrix

| Gate | PG14 | PG15 | PG16 | PG17 | PG18 |
|---|---:|---:|---:|---:|---:|
| Smoke/install | PR, main | main | PR, main | main | PR, main |
| Full scenarios | main | main | PR, main | main | PR, main |
| Five install orders | — | — | — | — | PR, main, nightly |
| Security | main | main | main | main | PR, main, nightly |
| Basic races | main | main | main | main | PR, main, nightly |
| 128-client races | — | — | — | — | nightly |
| Benchmarks | — | — | — | — | weekly/manual |

The supported orders are authoritative in `stack/compatibility.toml`. v0.1
does not claim all 720 permutations. Each scenario uses fixed identities,
amounts, timestamps where API freshness permits, and explicit idempotency keys.

Failure categories used in CI triage are `BUILD`, `INSTALL`, `ADAPTER`,
`TYPE_COMPATIBILITY`, `INVARIANT`, `SECURITY`, `CONCURRENCY`, `UPGRADE`,
`PERFORMANCE`, and `SCENARIO`.
