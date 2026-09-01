# Architecture

The stack orchestrates sources, PostgreSQL instances, SQL scenarios, and result
artifacts. It never copies extension business logic.

```text
pg_money ───────────────┐
                       ├──> pg_fx ───────┐
pg_cryptocurrency ─────┘                 │
       │                                 v
       └──────────────────────────> pg_ledger
                                           │
                                           v
                                    pg_reconcile
                                           │
                                           v
                                        pg_risk
```

These arrows describe conceptual interoperability, not hard PostgreSQL
extension dependencies. Adapters discover companion extension schemas through
PostgreSQL catalogs and may be enabled after either side is installed.

`scripts/stack.py` resolves local overrides, sibling repositories, or Git refs;
checks pgrx and PostgreSQL features; then atomically writes exact sources and
commits to `versions.lock`. Docker supplies an isolated PostgreSQL major and
toolchain. SQL suites exercise only public extension contracts. The Rust
benchmark driver measures those same APIs and runs all extension validators
before publishing results.

