# CI failure categories

- `BUILD`: Rust, pgrx, or extension compilation failed.
- `INSTALL`: an extension could not be created in PostgreSQL.
- `ADAPTER`: a late or automatic adapter was absent or non-idempotent.
- `TYPE_COMPATIBILITY`: an exact amount or asset identity changed.
- `INVARIANT`: an extension or stack validation row failed.
- `SECURITY`: a role boundary or trusted search path was bypassed.
- `CONCURRENCY`: a race duplicated effects, lost updates, or admitted stale state.
- `UPGRADE`: persisted data or extension transition changed incompatibly.
- `PERFORMANCE`: a correct workload exceeded its configured regression gate.
- `SCENARIO`: an end-to-end expected state was not reached.

CI retains `versions.lock` for every run. On failure, also retain PostgreSQL
logs and the failing runner output; database dumps are opt-in because they may
contain large or sensitive fixtures.
