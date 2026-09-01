# Benchmarks

The Tokio benchmark driver runs concurrent clients against SQL in
`bench/workloads`. It records operations, errors, throughput, mean, p50, p95,
p99, and p99.9 latency together with the stack version, exact extension commit
hashes, PostgreSQL and extension versions, Rust/pgrx versions, deterministic
seed, host resources, and selected database settings. Output is JSON for
artifact comparison.

```bash
just bench pg18 ledger_transfer 16
bench/run.sh --workload full_exchange --clients 64 --iterations 1000
```

Supported workload names cover ledger transfers/multi-posting/idempotency, FX
rate/quote/execution, external reconciliation/balance/exact matching, risk
amount/rolling-volume/exposure checks, and a composed exchange. The driver runs
`ledger_validate()`, `reconcile_validate()`, and `risk_validate()` afterward;
any violation suppresses a successful performance result.

Stable hard regression thresholds and 100k/1M/10M storage-growth fixtures are
v0.2 work and require dedicated, reproducible infrastructure.
