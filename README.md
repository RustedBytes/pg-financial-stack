# pg-financial-stack

Integration, compatibility, concurrency, security, scenario, and benchmark
validation for the RustedBytes PostgreSQL financial extensions:

| Extension | Responsibility | Manifest source |
|---|---|---|
| `pg_money` | Exact fiat values | `RustedBytes/pg-money` |
| `pg_cryptocurrency` | Network-qualified crypto values | `RustedBytes/pg-cryptocurrency` |
| `pg_fx` | Rates and executable quotes | `RustedBytes/pg-fx` |
| `pg_ledger` | Exact double-entry accounting | `RustedBytes/pg-ledger` |
| `pg_reconcile` | External evidence and reconciliation | `RustedBytes/pg-reconcile` |
| `pg_risk` | Auditable risk decisions | `RustedBytes/pg-risk` |

This repository contains no financial business logic. A green run proves that
the exact versions recorded in `stack/versions.lock` install and work together.

## Compatibility

Stack 0.1 targets PostgreSQL 14–18, Rust 1.96 or newer, and pgrx 0.19.2.
The declared version ranges and supported install orders live in
[`stack/compatibility.toml`](stack/compatibility.toml). Every resolve validates
all extensions' Cargo pgrx version and PostgreSQL feature matrix before writing
an exact commit lock.

## Run locally

Docker and `just` are sufficient for the containerized stack commands. The
optional host-side resolver also needs Python 3.11+ and Git; the host-side
benchmark command needs Rust 1.96+. For sibling repositories:

```bash
just test-local pg18
```

To clone sources from the manifest:

```bash
just resolve git
just test pg18
```

Other entry points:

```bash
just test-all
just test-install-order pg18
just test-security pg18
just test-concurrency pg18
just validate-stack
just bench pg18 full_exchange 16
```

`just test` starts the selected PostgreSQL container, builds and installs all
extensions, creates a fresh database, and runs the suite. Set
`PG_STACK_<EXTENSION>_PATH` (for example `PG_STACK_PG_LEDGER_PATH`) to validate
a candidate checkout, or `PG_STACK_<EXTENSION>_REF` to select a branch, tag, or
commit. `just check-extension pg-ledger pg18` is the fast candidate path.

Packaged builds use `PG_STACK_ARTIFACT_DIR` with files named
`<extension>-pg<major>.tar.gz` and `just test-release-stack pg18`.

## What v0.1 validates

The full suite covers smoke installation, five supported installation orders,
late adapter enablement, exact fiat and crypto conversion chains, stablecoin
network isolation, complete USD/EUR and BTC/USD exchanges, historical
reconciliation, role and hostile-search-path checks, ledger/FX/risk concurrency
races, and the common invariant runner. Benchmark results are emitted as JSON
and are rejected if any extension validator fails.

See [architecture](docs/ARCHITECTURE.md), [test matrix](docs/TEST_MATRIX.md),
[invariants](docs/INVARIANTS.md), and [adding an extension](docs/ADDING_EXTENSION.md).
